import 'package:flutter/material.dart';

import '../../../../shared/theme/app_colors.dart';

/// Shared, styled building blocks for the create-process wizard, matching the
/// look of the existing create dialogs (roles / employees).

class WizardLabel extends StatelessWidget {
  final String text;
  const WizardLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.right,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 15,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class WizardSectionTitle extends StatelessWidget {
  final String text;
  const WizardSectionTitle(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.right,
      style: const TextStyle(
        color: AppColors.primary,
        fontSize: 18,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class WizardTextInput extends StatelessWidget {
  final TextEditingController? controller;
  final String hint;
  final String? errorText;
  final TextDirection? textDirection;
  final ValueChanged<String>? onChanged;

  const WizardTextInput({
    super.key,
    this.controller,
    required this.hint,
    this.errorText,
    this.textDirection,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      textAlign: TextAlign.right,
      textDirection: textDirection ?? TextDirection.rtl,
      decoration: _wizardInputDecoration(hint: hint, errorText: errorText),
    );
  }
}

class WizardDropdown<T> extends StatelessWidget {
  final String hint;
  final T? value;
  final Map<T, String> items;
  final ValueChanged<T?> onChanged;
  final String? errorText;
  final bool enabled;

  const WizardDropdown({
    super.key,
    required this.hint,
    required this.value,
    required this.items,
    required this.onChanged,
    this.errorText,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      value: items.containsKey(value) ? value : null,
      isExpanded: true,
      icon: const Icon(Icons.keyboard_arrow_down_rounded,
          color: AppColors.textPrimary),
      decoration: _wizardInputDecoration(hint: null, errorText: errorText),
      hint: Text(
        hint,
        textAlign: TextAlign.right,
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 15),
      ),
      items: items.entries
          .map(
            (e) => DropdownMenuItem<T>(
              value: e.key,
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  e.value,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
          )
          .toList(),
      onChanged: enabled ? onChanged : null,
    );
  }
}

/// Tappable date field — opens the platform date picker. Only month/day matter
/// to the backend, but the full date is shown for clarity.
class WizardDateField extends StatelessWidget {
  final DateTime? value;
  final String hint;
  final String? errorText;
  final ValueChanged<DateTime> onPicked;

  const WizardDateField({
    super.key,
    required this.value,
    required this.hint,
    required this.onPicked,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    final text = value == null
        ? hint
        : '${value!.day}/${value!.month}/${value!.year}';

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () async {
        final now = DateTime.now();
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? now,
          firstDate: DateTime(now.year - 1),
          lastDate: DateTime(now.year + 5),
        );
        if (picked != null) onPicked(picked);
      },
      child: InputDecorator(
        decoration: _wizardInputDecoration(hint: null, errorText: errorText),
        child: Row(
          textDirection: TextDirection.rtl,
          children: [
            Expanded(
              child: Text(
                text,
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 15,
                  color: value == null
                      ? AppColors.textSecondary
                      : AppColors.textPrimary,
                ),
              ),
            ),
            const Icon(Icons.calendar_today_rounded,
                size: 18, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

InputDecoration _wizardInputDecoration({String? hint, String? errorText}) {
  return InputDecoration(
    hintText: hint,
    errorText: errorText,
    filled: true,
    fillColor: Colors.white,
    hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 15),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppColors.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppColors.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppColors.primary),
    ),
  );
}

/// The 4-step progress header (RTL: step 1 on the right).
class WizardStepper extends StatelessWidget {
  final int currentStep;
  final List<String> titles;

  const WizardStepper({
    super.key,
    required this.currentStep,
    required this.titles,
  });

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    for (var i = 0; i < titles.length; i++) {
      final step = i + 1;
      children.add(_StepNode(
        step: step,
        title: titles[i],
        state: step < currentStep
            ? _NodeState.done
            : (step == currentStep ? _NodeState.current : _NodeState.upcoming),
      ));
      if (i < titles.length - 1) {
        children.add(Expanded(
          child: Container(
            height: 2,
            margin: const EdgeInsets.only(bottom: 28),
            color: step < currentStep ? AppColors.primary : AppColors.border,
          ),
        ));
      }
    }

    return Row(
      textDirection: TextDirection.rtl,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }
}

enum _NodeState { done, current, upcoming }

class _StepNode extends StatelessWidget {
  final int step;
  final String title;
  final _NodeState state;

  const _StepNode({
    required this.step,
    required this.title,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final isUpcoming = state == _NodeState.upcoming;
    final circleColor =
        isUpcoming ? AppColors.inputBackground : AppColors.primary;
    final textColor = isUpcoming ? AppColors.textSecondary : AppColors.primary;

    return SizedBox(
      width: 96,
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: circleColor,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: state == _NodeState.done
                ? const Icon(Icons.check_rounded, color: Colors.white, size: 24)
                : Text(
                    '$step',
                    style: TextStyle(
                      color: isUpcoming ? AppColors.textSecondary : Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: TextStyle(
              color: textColor,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
