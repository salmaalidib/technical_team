import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:web_socket_channel/status.dart' as ws_status;
import 'package:web_socket_channel/web_socket_channel.dart';

import '../storage/secure_storage_service.dart';
import 'notification_service.dart';
import 'token_refresh_service.dart';

/// شكل الإشعار الوارد من الخادم.
///
/// الرسالة المتوقَّعة على القناة: `{ "title": "...", "body": "...", "payload": { ... } }`.
class PushMessage {
  const PushMessage({required this.title, required this.body, this.payload});

  final String title;
  final String body;
  final Map<String, dynamic>? payload;

  /// يفكّ ترميز رسالة JSON. يُعيد `null` لأي رسالة غير صالحة أو لا تحمل عنوانًا
  /// (نتجاهلها بهدوء دون إسقاط الاتصال).
  static PushMessage? tryParse(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;

      // إطارات تحكّم (مثل pong) ليست إشعارات — نتجاهلها.
      final type = decoded['type'];
      if (type == 'pong' || type == 'ping') return null;

      final title = decoded['title'];
      final body = decoded['body'];
      if (title is! String || body is! String) return null;

      final payload = decoded['payload'];
      return PushMessage(
        title: title,
        body: body,
        payload: payload is Map<String, dynamic> ? payload : null,
      );
    } catch (_) {
      // JSON غير صالح — تجاهُل آمن.
      return null;
    }
  }
}

/// طبقة النقل: اتصال WebSocket دائم بخادم الإشعارات (بديل FCM على سطح المكتب).
///
/// المسؤوليات:
///  * فتح اتصال `wss` دائم مع تمرير access token كـ `?token=...`.
///  * **إعادة اتصال تلقائية** بتراجع أسّي (يبدأ 1ث ويتضاعف حتى سقف 30ث،
///    ويُصفَّر عند نجاح الاتصال).
///  * **ping دوري** كل 30ث لإبقاء الاتصال حيًّا.
///  * تحويل كل رسالة JSON صالحة إلى توست عبر [NotificationService].
///
/// لا يعمل الاتصال إلا طالما التطبيق يعمل — لذلك يُقرَن بأيقونة شريط النظام
/// (انظر `tray_service.dart`) كي تبقى الإشعارات واصلة حتى عند "إغلاق" النافذة.
class PushSocket {
  PushSocket({
    required SecureStorageService storage,
    required TokenRefreshService refreshService,
    NotificationService? notifications,
  })  : _storage = storage,
        _refreshService = refreshService,
        _notifications = notifications ?? NotificationService.instance;

  final SecureStorageService _storage;
  final TokenRefreshService _refreshService;
  final NotificationService _notifications;

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;
  Timer? _pingTimer;
  Timer? _reconnectTimer;

  /// تراجع إعادة الاتصال: يبدأ من ثانية ويتضاعف حتى السقف.
  static const Duration _initialBackoff = Duration(seconds: 1);
  static const Duration _maxBackoff = Duration(seconds: 30);
  static const Duration _pingInterval = Duration(seconds: 30);

  /// مهلة "انتظار الجلسة" بعد فشل التجديد (نهاية الجلسة): يبقى الـ socket حيًّا
  /// ويعيد المحاولة ببطء، فحين يسجّل المستخدم الدخول من جديد ويُخزَّن توكن صالح
  /// تلتقطه المحاولة التالية تلقائيًّا — تعافٍ ذاتي دون أي ربط بطبقة المصادقة.
  static const Duration _sessionRetryInterval = Duration(seconds: 60);

  /// إغلاقٌ خلال هذه المهلة بعد نجاح المصافحة يُعدّ "مبكّرًا" — مؤشّر مرجَّح على
  /// رفضٍ بسبب توكن منتهٍ (الخادم يقبل المصافحة ثم يغلق فورًا)، فنحاول تجديدًا.
  static const Duration _earlyCloseThreshold = Duration(seconds: 5);

  Duration _backoff = _initialBackoff;

  /// `true` بعد [start] وحتى [dispose] — يمنع إعادة الاتصال بعد الإيقاف المتعمَّد.
  bool _active = false;

  /// عدّاد جيل الاتصال. يزداد عند كل محاولة اتصال وعند كل تنظيف، فيمكن لأي
  /// محاولة `_connect()` معلّقة على await أن تكتشف بعد الاستئناف أنّها تجاوَزها
  /// إيقافٌ ([dispose]) أو إعادةُ اتصال أحدث، فتنسحب وتُغلق قناتها بدل أن تترك
  /// اتصالًا/مؤقّتًا/اشتراكًا شبحيًّا حيًّا.
  int _generation = 0;

  /// `true` بعد محاولة تجديد واحدة ضمن "نوبة فشل" واحدة. نوبة الفشل = سلسلة
  /// محاولات فاشلة دون اتصال ناجح بينها. يُصفَّر عند أول اتصال ناجح. الغرض:
  /// نجدّد التوكن **مرّة واحدة فقط** لكل نوبة، ثم نعود للتراجع الأسّي بدل قصف
  /// نقطة الـ refresh في كل محاولة.
  bool _triedRefreshThisEpisode = false;

  /// لحظة آخر اتصال ناجح؛ لقياس ما إذا كان الإغلاق "مبكّرًا".
  DateTime? _connectedAt;

  /// للاختبارات: هل الـ socket ما زال نشطًا (لم يُستدعَ dispose)؟
  @visibleForTesting
  bool get isActive => _active;

  /// للاختبارات: هل توجد إعادة محاولة مجدولة (الـ socket حيّ ينتظر، لا ميّت)؟
  @visibleForTesting
  bool get hasPendingReconnect => _reconnectTimer?.isActive ?? false;

  /// يبدأ الاتصال (idempotent). الاستدعاء المتكرر لا يفتح اتصالًا ثانيًا.
  Future<void> start() async {
    if (_active) return;
    _active = true;
    await _connect();
  }

  Future<void> _connect() async {
    if (!_active) return;

    // بصمة هذه المحاولة؛ نقارنها بعد كل await لاكتشاف تجاوُزها.
    final generation = ++_generation;
    bool isStale() => !_active || generation != _generation;

    final wsBase = dotenv.env['WS_URL'];
    if (wsBase == null || wsBase.isEmpty) {
      debugPrint('[PushSocket] WS_URL غير مُعرَّف في ملف البيئة — تخطّي الاتصال.');
      return;
    }

    // نمرّر access token كـ query parameter (الترويسات غير مدعومة في الاتصال
    // المشترك عبر WebSocketChannel.connect). نبني الـ Uri عبر replace كي
    // يُرمَّز التوكن بشكل صحيح.
    final token = await _storage.getToken();
    // قد يكون dispose() أو إعادة اتصال أحدث جرت أثناء انتظار التوكن.
    if (isStale()) return;

    Uri uri;
    try {
      final base = Uri.parse(wsBase);
      uri = (token != null && token.isNotEmpty)
          ? base.replace(queryParameters: {
              ...base.queryParameters,
              'token': token,
            })
          : base;
    } catch (e) {
      debugPrint('[PushSocket] WS_URL غير صالح: $e');
      return;
    }

    try {
      final channel = WebSocketChannel.connect(uri);

      // connect() لا يرمي عند الفشل — ننتظر ready لاكتشاف فشل المصافحة.
      await channel.ready;

      // أُوقِف الاتصال أو تجاوزته محاولة أحدث أثناء انتظار المصافحة → أغلق هذه
      // القناة فورًا (وإلّا بقيت مفتوحة دون أن يُغلقها أحد) ثم انسحب.
      if (isStale()) {
        try {
          await channel.sink.close(ws_status.normalClosure);
        } catch (_) {
          // أُغلقت بالفعل.
        }
        return;
      }

      _channel = channel;

      // نجح الاتصال → انتهت نوبة الفشل: صفّر التراجع وعلم التجديد، وسجّل اللحظة.
      _backoff = _initialBackoff;
      _triedRefreshThisEpisode = false;
      _connectedAt = DateTime.now();
      _startPing();

      _subscription = channel.stream.listen(
        _onData,
        onError: (Object error) {
          // خطأ في منتصف البث ليس مصادقةً عادةً → تراجُع عادي.
          debugPrint('[PushSocket] خطأ في القناة: $error');
          _handleConnectionFailure(earlyClose: false);
        },
        onDone: () {
          // إغلاقٌ مبكّرٌ بعد المصافحة يُرجَّح أنه توكن منتهٍ → جرّب التجديد.
          final connectedAt = _connectedAt;
          final early = connectedAt != null &&
              DateTime.now().difference(connectedAt) < _earlyCloseThreshold;
          debugPrint(
            '[PushSocket] أُغلِق الاتصال '
            '(code: ${channel.closeCode}, reason: ${channel.closeReason}, '
            'early: $early).',
          );
          _handleConnectionFailure(earlyClose: early);
        },
        cancelOnError: true,
      );

      debugPrint('[PushSocket] متصل بخادم الإشعارات.');
    } catch (e) {
      // فشل المصافحة (channel.ready رمى) — السبب الأرجح توكن منتهٍ/مرفوض.
      debugPrint('[PushSocket] تعذّر الاتصال: $e');
      _handleConnectionFailure(earlyClose: true);
    }
  }

  void _onData(dynamic data) {
    if (data is! String) return; // نتجاهل الإطارات الثنائية.
    final message = PushMessage.tryParse(data);
    if (message == null) return; // رسالة غير صالحة أو إطار تحكّم — تجاهُل آمن.

    _notifications.show(
      title: message.title,
      body: message.body,
      payload: message.payload == null ? null : jsonEncode(message.payload),
    );
  }

  void _startPing() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(_pingInterval, (_) {
      final channel = _channel;
      if (channel == null) return;
      try {
        // إطار ping على مستوى التطبيق؛ الخادم يردّ pong (نتجاهله في tryParse).
        channel.sink.add(jsonEncode({'type': 'ping'}));
      } catch (e) {
        debugPrint('[PushSocket] فشل إرسال ping: $e');
      }
    });
  }

  /// يقرّر ما يحدث عند فشل/انقطاع الاتصال: محاولة تجديد واحدة (إن كان الفشل
  /// مبكّرًا ولم نجرّب بعد في هذه النوبة)، وإلّا تراجُع عادي.
  ///
  /// - فشل غير مبكّر، أو جرّبنا التجديد في هذه النوبة، أو أُوقف الـ socket
  ///   → `_scheduleReconnect()` (التراجع الأسّي كالمعتاد).
  /// - فشل مبكّر ولم نجرّب بعد → نجدّد التوكن مرّة واحدة:
  ///     • نجح التجديد → إعادة اتصال فورية بالتوكن الجديد.
  ///     • فشل التجديد (انتهى الـ refresh token = نهاية الجلسة فعلًا) → نتوقّف
  ///       (لا تنقّل هنا؛ AuthInterceptor يتولّى مسح الجلسة والتوجيه لـ /login
  ///       عند أول طلب HTTP لاحق).
  Future<void> _handleConnectionFailure({required bool earlyClose}) async {
    if (!earlyClose || _triedRefreshThisEpisode || !_active) {
      _scheduleReconnect();
      return;
    }

    _triedRefreshThisEpisode = true;

    // نظّف القناة الميتة أولًا (يزيد _generation) ثم التقط الجيل بعده لاكتشاف
    // أي إيقاف/محاولة أحدث تجري أثناء انتظار التجديد.
    _cleanupConnection();
    final generation = _generation;

    final ok = await _refreshService.refresh();

    // أُوقِف الـ socket أو تجاوزته محاولة أحدث أثناء التجديد → لا تفعل شيئًا.
    if (!_active || generation != _generation) return;

    if (ok) {
      // توكن جديد يستحق محاولة فورية: صفّر التراجع ثم أعد الاتصال (سيقرأ
      // _connect التوكن المحدَّث من التخزين).
      _backoff = _initialBackoff;
      await _connect();
    } else {
      // فشل التجديد = نهاية الجلسة (انتهى الـ refresh token أو لا توكن). بدل
      // التوقّف الأبدي، ندخل وضع "انتظار الجلسة": إعادة محاولة بطيئة (60ث) تبقي
      // الـ socket حيًّا. حين يسجّل المستخدم الدخول من جديد ويُخزَّن توكن صالح،
      // تلتقطه المحاولة التالية وتنجح — تعافٍ ذاتي دون ربط بطبقة المصادقة.
      // نُصفّر علم النوبة كي تُسمح محاولة تجديد جديدة بعد عودة المستخدم.
      _triedRefreshThisEpisode = false;
      debugPrint(
        '[PushSocket] فشل تجديد التوكن — انتظار جلسة جديدة '
        '(إعادة محاولة كل ${_sessionRetryInterval.inSeconds}ث).',
      );
      _scheduleReconnect(overrideDelay: _sessionRetryInterval);
    }
  }

  /// يجدول إعادة اتصال. بلا [overrideDelay] يستخدم التراجع الأسّي الحالي
  /// ويضاعفه للمحاولة التالية. مع [overrideDelay] (حالة "انتظار الجلسة" بعد فشل
  /// التجديد) يعيد المحاولة بمهلة ثابتة دون مضاعفة، فيبقى ينبض ببطء حتى يعود
  /// توكنٌ صالح.
  void _scheduleReconnect({Duration? overrideDelay}) {
    _cleanupConnection();
    if (!_active) return;

    // تجنّب جدولة محاولتين متزامنتين.
    if (_reconnectTimer?.isActive ?? false) return;

    final delay = overrideDelay ?? _backoff;
    debugPrint(
      '[PushSocket] إعادة المحاولة بعد ${delay.inSeconds}ث.',
    );
    _reconnectTimer = Timer(delay, () {
      // التراجع الأسّي يُضاعَف فقط في المسار العادي؛ مهلة الجلسة الثابتة لا.
      if (overrideDelay == null) {
        final next = _backoff * 2;
        _backoff = next > _maxBackoff ? _maxBackoff : next;
      }
      _connect();
    });
  }

  /// يُغلق الاشتراك والـ timers والقناة الحالية دون تعطيل إعادة الاتصال.
  void _cleanupConnection() {
    // إبطال أي محاولة `_connect()` معلّقة على await: زيادة الجيل تجعلها تنسحب
    // بعد الاستئناف بدل أن تُركّب اتصالًا/مؤقّتًا/اشتراكًا فوق ما نظّفناه للتو.
    _generation++;
    _pingTimer?.cancel();
    _pingTimer = null;
    _subscription?.cancel();
    _subscription = null;
    final channel = _channel;
    _channel = null;
    try {
      channel?.sink.close(ws_status.normalClosure);
    } catch (_) {
      // أُغلقت القناة بالفعل.
    }
  }

  /// إيقاف نهائي للاتصال (عند الخروج الفعلي من التطبيق).
  Future<void> dispose() async {
    _active = false;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _cleanupConnection();
  }
}
