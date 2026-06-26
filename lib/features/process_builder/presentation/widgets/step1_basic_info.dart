import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../shared/theme/app_colors.dart';
import '../bloc/process_builder_bloc.dart';
import '../bloc/process_builder_event.dart';
import '../bloc/process_builder_state.dart';
import 'wizard_kit.dart';

/// Step 1 — basic info: name, transaction/complaint, type, organization,
/// priority, start/end dates.
class Step1BasicInfo extends StatelessWidget {
  final bool showErrors;
  const Step1BasicInfo({super.key, this.showErrors = false});

  static const _priorities = {3: 'عالية', 2: 'متوسطة', 1: 'منخفضة'};

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProcessBuilderBloc, ProcessBuilderState>(
      builder: (context, state) {
        final bloc = context.read<ProcessBuilderBloc>();
        final narrow = MediaQuery.sizeOf(context).width < 640;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // كونها معاملة أو شكوى
            const WizardLabel('تصنيف *'),
            const SizedBox(height: 8),
            _ComplaintSelector(
              isComplaint: state.isComplaint,
              onChanged: (v) => bloc.add(ComplaintChanged(v)),
            ),
            const SizedBox(height: 20),

            const WizardLabel('اسم المعاملة *'),
            const SizedBox(height: 8),
            WizardTextInput(
              hint: 'مثال: معاملة مدنية',
              onChanged: (v) => bloc.add(NameChanged(v)),
              errorText: showErrors && state.name.trim().isEmpty
                  ? 'هذا الحقل مطلوب'
                  : null,
            ),
            const SizedBox(height: 20),

            // النوع يُحدَّد مسبقاً من صفحة النوع، فلم يعد يُختار هنا.
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const WizardLabel('الأولوية *'),
                const SizedBox(height: 8),
                WizardDropdown<int>(
                  hint: 'اختر الأولوية...',
                  value: state.priority,
                  items: _priorities,
                  onChanged: (v) =>
                      bloc.add(PriorityChanged(v ?? state.priority)),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Organization isn't picked here: it's the user's active one,
            // chosen once after login and seeded into the wizard at init.

            _twoCols(
              narrow,
              first: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const WizardLabel('تاريخ البداية *'),
                  const SizedBox(height: 8),
                  WizardDateField(
                    value: state.startDate,
                    hint: 'اختر التاريخ...',
                    onPicked: (d) => bloc.add(StartDateChanged(d)),
                    errorText: showErrors && state.startDate == null
                        ? 'هذا الحقل مطلوب'
                        : null,
                  ),
                ],
              ),
              second: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const WizardLabel('تاريخ النهاية (اختياري)'),
                  const SizedBox(height: 8),
                  WizardDateField(
                    value: state.endDate,
                    hint: 'اختر التاريخ...',
                    onPicked: (d) => bloc.add(EndDateChanged(d)),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _twoCols(bool narrow,
      {required Widget first, required Widget second}) {
    if (narrow) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [first, const SizedBox(height: 20), second],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: first),
        const SizedBox(width: 16),
        Expanded(child: second),
      ],
    );
  }
}

class _ComplaintSelector extends StatelessWidget {
  final bool isComplaint;
  final ValueChanged<bool> onChanged;

  const _ComplaintSelector({required this.isComplaint, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      textDirection: TextDirection.rtl,
      children: [
        Expanded(
          child: _Segment(
            label: 'معاملة',
            selected: !isComplaint,
            onTap: () => onChanged(false),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _Segment(
            label: 'شكوى',
            selected: isComplaint,
            onTap: () => onChanged(true),
          ),
        ),
      ],
    );
  }
}

class _Segment extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _Segment({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        height: 50,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
