import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../domain/entities/date_bound.dart';
import 'dialog_kit.dart';
import 'field_form_kit.dart';
import '../../../../shared/theme/app_dimens.dart';

/// Editor for one end of a date range.
///
/// The three modes the backend accepts are laid out openly — a fixed date, the
/// day the form opens, or an offset from that day — so a rule like "at least 18
/// years old" is discoverable rather than hidden behind a toggle. Whichever
/// mode is active, the date it resolves to today is previewed underneath so the
/// rule is never abstract.
class DateBoundField extends StatelessWidget {
  final String label;
  final DateBound value;
  final ValueChanged<DateBound> onChanged;

  /// Placeholder for the fixed-date box.
  final String hint;

  /// Shown under the field once the user has attempted to submit.
  final String? errorText;

  const DateBoundField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    required this.hint,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    final isAbsolute = value is AbsoluteDateBound;
    final isToday = value is TodayDateBound;
    final relative = value is RelativeDateBound
        ? value as RelativeDateBound
        : const RelativeDateBound(years: -1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DialogLabel(label),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
          decoration: BoxDecoration(
            color: AppColors.inputBackground,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // The three modes, always visible.
              Wrap(
                textDirection: TextDirection.rtl,
                spacing: 8,
                runSpacing: 8,
                children: [
                  _ModeChip(
                    label: 'تاريخ محدّد',
                    selected: isAbsolute,
                    onTap: () => onChanged(const AbsoluteDateBound('')),
                  ),
                  _ModeChip(
                    label: 'اليوم',
                    selected: isToday,
                    onTap: () => onChanged(const TodayDateBound()),
                  ),
                  _ModeChip(
                    label: 'إزاحة عن اليوم',
                    selected: value is RelativeDateBound,
                    onTap: () => onChanged(relative),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (isAbsolute)
                _AbsoluteInput(
                  date: (value as AbsoluteDateBound).date,
                  hint: hint,
                  onChanged: (d) => onChanged(AbsoluteDateBound(d)),
                )
              else if (value is RelativeDateBound) ...[
                _OffsetRow(
                  value: relative,
                  onChanged: onChanged,
                ),
                const SizedBox(height: 8),
                const Text(
                  'القيمة السالبة تعني قبل اليوم — مثال: ‎-18 سنة لأقل عمر مسموح',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
              // The fixed-date box carries its own inline error; the dynamic
              // modes can't be malformed, so only the preview follows them.
              if (!isAbsolute || _resolvable(value)) ...[
                const SizedBox(height: 12),
                _ResolvedPreview(value: value),
              ],
            ],
          ),
        ),
        if (errorText != null) DialogErrorText(errorText!),
      ],
    );
  }

  /// Whether a preview would be meaningful — an empty or half-typed fixed date
  /// resolves to today, which would be misleading to show.
  static bool _resolvable(DateBound bound) =>
      bound is! AbsoluteDateBound || bound.isValid;
}

class _ResolvedPreview extends StatelessWidget {
  final DateBound value;

  const _ResolvedPreview({required this.value});

  @override
  Widget build(BuildContext context) {
    final resolved = DateBound.format(value.resolve());
    final described = value.describe();

    return Row(
      textDirection: TextDirection.rtl,
      children: [
        const Icon(Icons.event_available_outlined,
            size: 15, color: AppColors.primary),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value is AbsoluteDateBound
                ? 'التاريخ: $resolved'
                : 'يُحتسب اليوم: $resolved  •  $described',
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }
}

class _AbsoluteInput extends StatefulWidget {
  final String date;
  final String hint;
  final ValueChanged<String> onChanged;

  const _AbsoluteInput({
    required this.date,
    required this.hint,
    required this.onChanged,
  });

  @override
  State<_AbsoluteInput> createState() => _AbsoluteInputState();
}

class _AbsoluteInputState extends State<_AbsoluteInput> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.date);

  @override
  void didUpdateWidget(_AbsoluteInput old) {
    super.didUpdateWidget(old);
    // Only push external changes in — never while the user is typing, which
    // would fight the cursor.
    if (widget.date != _controller.text) {
      _controller.text = widget.date;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DialogTextInput(
      controller: _controller,
      hint: widget.hint,
      onChanged: widget.onChanged,
    );
  }
}

/// The three signed boxes of a relative offset.
class _OffsetRow extends StatelessWidget {
  final RelativeDateBound value;
  final ValueChanged<DateBound> onChanged;

  const _OffsetRow({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      textDirection: TextDirection.rtl,
      children: [
        Expanded(
          child: _OffsetBox(
            label: 'سنوات',
            value: value.years,
            onChanged: (v) => onChanged(RelativeDateBound(
              years: v,
              months: value.months,
              days: value.days,
            )),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _OffsetBox(
            label: 'أشهر',
            value: value.months,
            onChanged: (v) => onChanged(RelativeDateBound(
              years: value.years,
              months: v,
              days: value.days,
            )),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _OffsetBox(
            label: 'أيام',
            value: value.days,
            onChanged: (v) => onChanged(RelativeDateBound(
              years: value.years,
              months: value.months,
              days: v,
            )),
          ),
        ),
      ],
    );
  }
}

class _ModeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ModeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.white,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: selected ? AppColors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

/// A signed integer box for one unit of a relative offset.
class _OffsetBox extends StatefulWidget {
  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  const _OffsetBox({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  State<_OffsetBox> createState() => _OffsetBoxState();
}

class _OffsetBoxState extends State<_OffsetBox> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.value.toString());

  @override
  void didUpdateWidget(_OffsetBox old) {
    super.didUpdateWidget(old);
    // A bare "-" is a valid intermediate state; don't overwrite it with 0.
    if (widget.value != (int.tryParse(_controller.text) ?? 0)) {
      _controller.text = widget.value.toString();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.label,
          textAlign: TextAlign.right,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 44,
          child: TextField(
            controller: _controller,
            textAlign: TextAlign.center,
            keyboardType: const TextInputType.numberWithOptions(signed: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^-?\d*')),
            ],
            onChanged: (t) => widget.onChanged(int.tryParse(t) ?? 0),
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                borderSide: const BorderSide(color: AppColors.primary),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
