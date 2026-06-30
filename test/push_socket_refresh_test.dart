import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:technical_team/core/services/notification_service.dart';
import 'package:technical_team/core/services/push_socket.dart';
import 'package:technical_team/core/services/token_refresh_service.dart';
import 'package:technical_team/core/storage/secure_storage_service.dart';

/// تخزين في الذاكرة لتوكن واحد يمكن تبديله أثناء الاختبار.
class _MemStorage extends SecureStorageService {
  _MemStorage(this._token);
  String _token;

  @override
  Future<String?> getToken() async => _token;
  set token(String v) => _token = v;
}

class _NoopNotifications extends NotificationService {
  _NoopNotifications() : super.test();
}

/// تجديد وهمي: يبدّل التوكن المخزّن من "expired" إلى "fresh" ويحصي مرّاته.
class _FakeRefresh extends TokenRefreshService {
  _FakeRefresh(this._storage) : super(storage: _storage);
  final _MemStorage _storage;
  int calls = 0;
  bool succeed = true;

  @override
  Future<bool> refresh() async {
    calls++;
    if (!succeed) return false;
    _storage.token = 'fresh';
    return true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late HttpServer server;
  late int port;
  var acceptedWithFresh = 0;
  var rejectedExpired = 0;

  /// خادم يقرأ ?token=: يقبل ويُبقي الاتصال لو 'fresh'، ويُغلق فورًا لو 'expired'
  /// (محاكاة رفض التوكن المنتهي بعد المصافحة).
  void startServer() {
    server.listen((req) async {
      final token = req.uri.queryParameters['token'];
      if (WebSocketTransformer.isUpgradeRequest(req)) {
        final ws = await WebSocketTransformer.upgrade(req);
        if (token == 'fresh') {
          acceptedWithFresh++;
          ws.listen((_) {}, onError: (_) {});
          // يبقى مفتوحًا.
        } else {
          rejectedExpired++;
          await ws.close(); // إغلاق مبكّر → يحفّز مسار التجديد في العميل.
        }
      } else {
        req.response.statusCode = HttpStatus.badRequest;
        await req.response.close();
      }
    });
  }

  setUp(() async {
    acceptedWithFresh = 0;
    rejectedExpired = 0;
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    port = server.port;
    startServer();
    dotenv.loadFromString(envString: 'WS_URL=ws://127.0.0.1:$port/ws');
  });

  tearDown(() async {
    await server.close(force: true);
  });

  test('إغلاق مبكّر بتوكن منتهٍ → تجديد واحد ثم إعادة اتصال بالتوكن الجديد',
      () async {
    final storage = _MemStorage('expired');
    final refresh = _FakeRefresh(storage);
    final socket = PushSocket(
      storage: storage,
      refreshService: refresh,
      notifications: _NoopNotifications(),
    );

    await socket.start();
    // اتصال أول بـ 'expired' → الخادم يغلق فورًا → العميل يجدّد مرّة → يعيد
    // الاتصال بـ 'fresh' → يُقبل ويبقى.
    await Future<void>.delayed(const Duration(seconds: 1));

    expect(refresh.calls, 1, reason: 'يجب أن يجدّد مرّة واحدة فقط لكل نوبة.');
    expect(rejectedExpired, greaterThanOrEqualTo(1),
        reason: 'الاتصال الأول بالتوكن المنتهي يجب أن يُرفض.');
    expect(acceptedWithFresh, 1,
        reason: 'بعد التجديد يجب أن ينجح الاتصال بالتوكن الجديد.');

    await socket.dispose();
  });

  test('فشل التجديد (نهاية الجلسة) → تعافٍ ذاتي: يبقى حيًّا بإعادة محاولة بطيئة',
      () async {
    final storage = _MemStorage('expired');
    final refresh = _FakeRefresh(storage)..succeed = false;
    final socket = PushSocket(
      storage: storage,
      refreshService: refresh,
      notifications: _NoopNotifications(),
    );

    await socket.start();
    await Future<void>.delayed(const Duration(seconds: 1));

    // جرّب التجديد مرّة واحدة، فشل → لا اتصال ناجح، لكنّ الـ socket لا يموت:
    // يبقى نشطًا وينتظر إعادة محاولة بطيئة (60ث) ليلتقط أي توكن جديد لاحقًا.
    expect(refresh.calls, 1, reason: 'تجديد واحد لكل نوبة.');
    expect(acceptedWithFresh, 0, reason: 'لا يجب أن ينجح أي اتصال بلا توكن.');
    expect(socket.isActive, isTrue, reason: 'يجب أن يبقى الـ socket نشطًا.');
    expect(socket.hasPendingReconnect, isTrue,
        reason: 'يجب أن تكون هناك إعادة محاولة مجدولة (حيّ لا ميّت).');

    await socket.dispose();
    expect(socket.hasPendingReconnect, isFalse,
        reason: 'dispose يلغي إعادة المحاولة.');
  });
}
