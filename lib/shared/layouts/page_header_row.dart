import 'package:flutter/material.dart';

import '../theme/app_dimens.dart';

/// صفّ رأس الصفحة: العنوان على حافة والإجراء على الحافة المقابلة.
///
/// كانت الرؤوس تستخدم `Wrap(alignment: start)` فيلتصق زرّ الإجراء بالعنوان
/// ويبقى فراغ واسع على الحافة الأخرى. `Row` مع `spaceBetween` يدفع الزر إلى
/// الحافة المقابلة، ويسقط إلى عمود تحت [breakpoint] حيث لا يتّسع السطر
/// للعنصرين معاً.
class PageHeaderRow extends StatelessWidget {
  final Widget title;

  /// زرّ الإجراء. `null` يعرض العنوان وحده (مثلاً حين لا يملك المستخدم
  /// صلاحية الإجراء) دون أن يختلّ التوزيع.
  final Widget? action;

  final double breakpoint;

  const PageHeaderRow({
    super.key,
    required this.title,
    this.action,
    this.breakpoint = 620,
  });

  @override
  Widget build(BuildContext context) {
    final actionWidget = action;

    return LayoutBuilder(
      builder: (context, constraints) {
        if (actionWidget == null) {
          return Align(
            alignment: AlignmentDirectional.centerStart,
            child: title,
          );
        }

        if (constraints.maxWidth < breakpoint) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              title,
              const SizedBox(height: AppSpacing.lg),
              actionWidget,
            ],
          );
        }

        return Row(
          textDirection: TextDirection.rtl,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(child: title),
            const SizedBox(width: AppSpacing.xl),
            actionWidget,
          ],
        );
      },
    );
  }
}
