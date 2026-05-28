import 'package:flutter/material.dart';

class InstitutionActionButton extends StatelessWidget {
  final IconData icon;
  final Color backgroundColor;
  final Color iconColor;

  const InstitutionActionButton({
    super.key,
    required this.icon,
    required this.backgroundColor,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
    );
  }
}
