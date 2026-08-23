import 'package:flutter/material.dart';

import '../../theme/app_text_styles.dart';

/// يفرض خط التطبيق (Cairo) على شجرة [SfDataGrid] بالكامل.
///
/// جداول Syncfusion لا ترث `fontFamily` من ثيم التطبيق: فهي تبني نصوصها
/// اعتماداً على `DefaultTextStyle` الخاص بها، فيظهر الخط الافتراضي للنظام
/// بدل Cairo. تغليف الجدول بهذه الأداة يعيد ربطه بخط التطبيق دون الحاجة
/// إلى كتابة `fontFamily` في كل خلية.
class GridFontScope extends StatelessWidget {
  const GridFontScope({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final base = DefaultTextStyle.of(context).style;
    return DefaultTextStyle(
      style: base.copyWith(fontFamily: AppTextStyles.fontFamily),
      child: child,
    );
  }
}
