import 'dart:io' show Platform, exit;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

/// طبقة البقاء حيًّا (System Tray + اعتراض الإغلاق).
///
/// تضمن أن اتصال [PushSocket] يبقى حيًّا حتى عندما "يغلق" المستخدم النافذة:
///  * تعترض زر الإغلاق (X) عبر `window_manager` فتُخفي النافذة بدل الخروج.
///  * تضيف أيقونة في شريط النظام عبر `tray_manager` بقائمة:
///    (إظهار النافذة / خروج نهائي).
///
/// التهيئة الأصلية (`setPreventClose`, `setIcon`, `setContextMenu`) تتم في
/// [init] الذي يُستدعى مرّة في `main` بعد تهيئة `windowManager`. أمّا تسجيل
/// المستمعين فيُدار عبر [TrayBootstrap] لأن الـ listeners يجب أن تُسجَّل من
/// داخل دورة حياة عنصر واجهة (initState/dispose).
class TrayService {
  TrayService._();

  static final TrayService instance = TrayService._();

  /// مسار أيقونة الـ tray. على Windows يجب أن يكون ملف `.ico` حقيقي مُعلَن
  /// ضمن أصول التطبيق في pubspec.yaml.
  static const String _windowsIcon = 'assets/icons/tray_icon.ico';
  static const String _otherIcon = 'assets/icons/tray_icon.png';

  static const String _menuKeyShow = 'show_window';
  static const String _menuKeyExit = 'exit_app';

  bool _initialized = false;

  /// يُهيّئ الـ tray واعتراض الإغلاق. سطح المكتب فقط؛ idempotent.
  Future<void> init() async {
    if (_initialized) return;
    if (kIsWeb || !(Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      return;
    }

    // اعتراض زر الإغلاق: بدونه يُغلَق التطبيق قبل أن يعمل onWindowClose.
    await windowManager.setPreventClose(true);

    await trayManager.setIcon(
      Platform.isWindows ? _windowsIcon : _otherIcon,
    );

    await trayManager.setContextMenu(
      Menu(
        items: [
          MenuItem(key: _menuKeyShow, label: 'إظهار النافذة'),
          MenuItem.separator(),
          MenuItem(key: _menuKeyExit, label: 'خروج'),
        ],
      ),
    );

    _initialized = true;
  }

  /// يُظهر النافذة ويعطيها التركيز (من أيقونة الـ tray أو عند نقرها).
  Future<void> showWindow() async {
    await windowManager.show();
    await windowManager.focus();
  }

  /// خروج فعلي من التطبيق. [onBeforeExit] فرصة لإغلاق الموارد (مثل الـ socket).
  Future<void> exitApp({Future<void> Function()? onBeforeExit}) async {
    try {
      await onBeforeExit?.call();
    } finally {
      // destroy() يتجاوز حارس prevent-close ثم نُنهي العملية.
      await windowManager.destroy();
      exit(0);
    }
  }

  /// يُخفي النافذة إلى الـ tray (يُستدعى من معالج onWindowClose).
  Future<void> hideToTray() => windowManager.hide();

  /// أوامر قائمة الـ tray حسب المفتاح.
  bool isShowKey(String? key) => key == _menuKeyShow;
  bool isExitKey(String? key) => key == _menuKeyExit;
}

/// عنصر واجهة يربط دورة حياة مستمعي النافذة والـ tray بعمر التطبيق.
///
/// يُركَّب مرّة واحدة قرب جذر الشجرة (في `builder` الخاص بـ MaterialApp) كي
/// يبقى حيًّا طوال الجلسة ولا يُعاد بناؤه عند التنقّل بين الصفحات.
class TrayBootstrap extends StatefulWidget {
  const TrayBootstrap({
    super.key,
    required this.child,
    this.onBeforeExit,
  });

  final Widget child;

  /// يُستدعى قبل الخروج النهائي (مثلًا لإغلاق اتصال الـ PushSocket).
  final Future<void> Function()? onBeforeExit;

  @override
  State<TrayBootstrap> createState() => _TrayBootstrapState();
}

class _TrayBootstrapState extends State<TrayBootstrap>
    with WindowListener, TrayListener {
  bool get _desktop =>
      !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);

  @override
  void initState() {
    super.initState();
    if (_desktop) {
      windowManager.addListener(this);
      trayManager.addListener(this);
    }
  }

  @override
  void dispose() {
    if (_desktop) {
      windowManager.removeListener(this);
      trayManager.removeListener(this);
    }
    super.dispose();
  }

  // ===== اعتراض الإغلاق: إخفاء بدل الخروج =====
  @override
  void onWindowClose() async {
    final prevented = await windowManager.isPreventClose();
    if (prevented) {
      await TrayService.instance.hideToTray();
    }
  }

  // ===== تفاعلات أيقونة الـ tray =====
  @override
  void onTrayIconMouseDown() {
    // نقرة يسار على الأيقونة → إظهار النافذة.
    TrayService.instance.showWindow();
  }

  @override
  void onTrayIconRightMouseDown() {
    // نقرة يمين → إظهار قائمة السياق (السلوك المعتاد على Windows).
    trayManager.popUpContextMenu();
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    final service = TrayService.instance;
    if (service.isShowKey(menuItem.key)) {
      service.showWindow();
    } else if (service.isExitKey(menuItem.key)) {
      service.exitApp(onBeforeExit: widget.onBeforeExit);
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
