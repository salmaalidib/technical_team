import 'package:flutter/material.dart';

/// زر إجراء دائري/مربّع داخل خلايا جدول الأقسام.
///
/// مطابق لأسلوب `EmployeeActionButton`: يستخدم [GestureDetector] (وليس
/// [InkWell]) لأن [MouseRegion] الداخلي لـ InkWell يتعارض مع تتبّع الماوس داخل
/// خلايا [SfDataGrid] ويُطلق assertion أثناء الـ hover. يُضاف [tooltip] هنا
/// لتوضيح كل إجراء.
class DepartmentActionButton extends StatelessWidget {
  final IconData icon;
  final Color backgroundColor;
  final Color iconColor;
  final String tooltip;
  final VoidCallback? onTap;

  const DepartmentActionButton({
    super.key,
    required this.icon,
    required this.backgroundColor,
    required this.iconColor,
    required this.tooltip,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}
