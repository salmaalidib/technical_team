import 'package:flutter/material.dart';

/// Colored pill summarising a process's approval state. Works for both list
/// shapes: the admin tab passes `approvalStatus`, the review tab may also pass
/// the precomputed `isApproved` flag.
class ApprovalBadge extends StatelessWidget {
  final String? approvalStatus;
  final bool? isApproved;

  const ApprovalBadge({super.key, this.approvalStatus, this.isApproved});

  @override
  Widget build(BuildContext context) {
    final status = approvalStatus?.toUpperCase();
    final approved = isApproved ?? (status == 'APPROVED');

    late final String label;
    late final Color color;
    if (approved || status == 'APPROVED') {
      label = 'معتمدة';
      color = const Color(0xff2E7D32);
    } else if (status == 'REJECTED') {
      label = 'مرفوضة';
      color = const Color(0xffC62828);
    } else {
      label = 'بانتظار الاعتماد';
      color = const Color(0xffB26A00);
    }

    return _Pill(label: label, color: color, icon: Icons.verified_outlined);
  }
}

/// Colored pill summarising whether the process is active.
class ActiveBadge extends StatelessWidget {
  final bool isActive;

  const ActiveBadge({super.key, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return _Pill(
      label: isActive ? 'مُفعّلة' : 'غير مُفعّلة',
      color: isActive ? const Color(0xff2E7D32) : const Color(0xff757575),
      icon: isActive ? Icons.toggle_on : Icons.toggle_off,
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;

  const _Pill({required this.label, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
