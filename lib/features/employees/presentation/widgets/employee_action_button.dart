import 'package:flutter/material.dart';

class EmployeeActionButton extends StatelessWidget {
  final IconData icon;
  final Color backgroundColor;
  final Color iconColor;
  final VoidCallback? onTap;

  const EmployeeActionButton({
    super.key,
    required this.icon,
    required this.backgroundColor,
    required this.iconColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // نستخدم GestureDetector (وليس InkWell) لأن MouseRegion الداخلي لـ InkWell
    // يتعارض مع تتبّع الماوس داخل خلايا SfDataGrid ويُطلق assertion في
    // mouse_tracker أثناء الـ hover. SystemMouseCursors.click يُبقي مؤشّر اليد.
    return MouseRegion(
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
    );
  }
}