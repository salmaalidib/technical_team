import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// طبقة العرض لإشعارات سطح المكتب.
///
/// تعرض إشعار توست (Toast) أصلي على Windows عبر WinRT باستخدام حزمة
/// [flutter_local_notifications] (الطريقة الصحيحة المدعومة رسميًّا — لا نستخدم
/// حِزم Windows غير رسمية). الخدمة Singleton وتُهيّأ مرّة واحدة فقط
/// (idempotent)، ويستدعيها [PushSocket] عند وصول حدث من الخادم.
///
/// قيود معروفة على Windows دون تحزيم MSIX: الدالتان [cancel] و
/// `getActiveNotifications` لا تعملان (قيد نظام)، لكنّ العرض الأساسي يعمل بدونه.
class NotificationService {
  NotificationService._();

  /// مُنشئ مخصّص للاختبارات فقط — يتيح إنشاء نسخة معزولة بدل الـ Singleton
  /// دون لمس قنوات المنصّة الأصلية.
  @visibleForTesting
  NotificationService.test();

  /// النسخة الوحيدة (Singleton).
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// معرّف ثابت يُمرَّر مع إعدادات Windows. **ثابت عبر كل التشغيلات** — هو هوية
  /// التطبيق لدى نظام إشعارات Windows، فلا يُولَّد وقت التشغيل أبدًا.
  /// (مُولَّد مرّة واحدة عبر `uuidgen`/`[guid]::NewGuid()`.)
  static const String _windowsGuid = '7244e7ab-d04e-4f5d-8e93-d52fc7de6fc0';

  /// الاسم الظاهر للتطبيق في نظام الإشعارات.
  static const String _appName = 'Technical Team';

  /// معرّف التطبيق بصيغة Company.Product (AppUserModelID).
  static const String _appUserModelId = 'AbuKm.TechnicalTeam';

  /// يُستدعى عند الضغط على الإشعار (في المقدمة). يُمرَّر له الـ payload الخام
  /// كي يربطه المستدعي بمنطق التنقّل.
  void Function(String? payload)? onSelect;

  /// تُهيّئ القناة الأصلية مرّة واحدة فقط. الاستدعاء المتكرر آمن (no-op).
  Future<void> init({void Function(String? payload)? onSelect}) async {
    if (onSelect != null) this.onSelect = onSelect;
    if (_initialized) return;

    // الإشعارات الأصلية تُهيَّأ على Windows فقط في هذا التطبيق (سطح المكتب).
    // على أي منصة أخرى نتجاهل التهيئة بهدوء بدل أن نُسقط التطبيق، فتبقى البنية
    // قابلة لإضافة Android/iOS لاحقًا دون إعادة كتابة.
    if (!kIsWeb && !Platform.isWindows) {
      _initialized = true;
      return;
    }

    const windowsSettings = WindowsInitializationSettings(
      appName: _appName,
      appUserModelId: _appUserModelId,
      guid: _windowsGuid,
    );

    const settings = InitializationSettings(windows: windowsSettings);

    await _plugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: _handleResponse,
    );

    _initialized = true;
  }

  /// يعرض إشعار توست. آمن للاستدعاء قبل اكتمال [init] — يهيّئ كسولًا عند اللزوم.
  Future<void> show({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_initialized) await init();
    if (!kIsWeb && !Platform.isWindows) return;

    // مُعرّف الإشعار: على Windows دون MSIX لا يُستخدم للإلغاء (قيد نظام)، لكنّه
    // مطلوب في التوقيع. نستخدم قيمة ثابتة بسيطة لأن كل توست مستقل عن سابقه.
    const int notificationId = 0;

    await _plugin.show(
      id: notificationId,
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(
        windows: WindowsNotificationDetails(),
      ),
      payload: payload,
    );
  }

  /// إلغاء الإشعارات. **لا يعمل على Windows دون MSIX** (قيد نظام) — مُبقًى
  /// للتوافق مع المنصات الأخرى مستقبلًا.
  Future<void> cancelAll() => _plugin.cancelAll();

  void _handleResponse(NotificationResponse response) {
    final payload = response.payload;

    // TODO(routing): اربط الـ payload بمنطق التنقّل في التطبيق.
    // مثال: فكّ ترميز الـ payload كـ JSON واستخرج منه مسار go_router المطلوب
    // ثم استدعِ AppRouter.router.go(route)، أو مرّره عبر onSelect لطبقة أعلى.
    onSelect?.call(payload);
  }
}
