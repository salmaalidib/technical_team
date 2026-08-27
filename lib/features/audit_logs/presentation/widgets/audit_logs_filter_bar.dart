import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_dimens.dart';
import '../../domain/entities/audit_log_entry.dart';
import '../../domain/entities/audit_log_filter.dart';
import '../bloc/audit_logs_bloc.dart';
import '../bloc/audit_logs_event.dart';
import '../bloc/audit_logs_state.dart';
import 'audit_log_format.dart';

/// لوحة الفلاتر: معرّف المستخدم، الحدث، الحالة، نوع المورد، والفترة.
///
/// الفلاتر تُجمَّع محلياً ولا تُرسَل إلا عند «تطبيق» — كل تغيير حقل كان سيطلق
/// طلباً للخادم، وهي خمسة حقول.
class AuditLogsFilterBar extends StatefulWidget {
  const AuditLogsFilterBar({super.key});

  @override
  State<AuditLogsFilterBar> createState() => _AuditLogsFilterBarState();
}

class _AuditLogsFilterBarState extends State<AuditLogsFilterBar> {
  late final TextEditingController _userIdController;
  late final TextEditingController _resourceTypeController;

  String? _action;
  AuditLogStatus? _status;
  DateTime? _fromDate;
  DateTime? _toDate;

  @override
  void initState() {
    super.initState();
    final filter = context.read<AuditLogsBloc>().state.filter;
    _userIdController =
        TextEditingController(text: filter.userId?.toString() ?? '');
    _resourceTypeController =
        TextEditingController(text: filter.resourceType ?? '');
    _action = filter.action;
    _status = filter.status;
    _fromDate = filter.fromDate;
    _toDate = filter.toDate;
  }

  @override
  void dispose() {
    _userIdController.dispose();
    _resourceTypeController.dispose();
    super.dispose();
  }

  void _apply() {
    final userId = int.tryParse(_userIdController.text.trim());
    final resourceType = _resourceTypeController.text.trim();

    context.read<AuditLogsBloc>().add(
          ApplyAuditLogFilter(
            AuditLogFilter(
              userId: userId,
              action: _action,
              status: _status,
              resourceType: resourceType.isEmpty ? null : resourceType,
              fromDate: _fromDate,
              toDate: _toDate,
            ),
          ),
        );
  }

  void _clear() {
    setState(() {
      _userIdController.clear();
      _resourceTypeController.clear();
      _action = null;
      _status = null;
      _fromDate = null;
      _toDate = null;
    });
    context.read<AuditLogsBloc>().add(const ClearAuditLogFilter());
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final initial = (isFrom ? _fromDate : _toDate) ?? DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      // آخر يوم قابل للاختيار هو اليوم: لا توجد سجلات في المستقبل.
      lastDate: DateTime.now(),
      builder: (context, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: child!,
      ),
    );

    if (picked == null || !mounted) return;
    setState(() {
      if (isFrom) {
        _fromDate = picked;
        // نطاق مقلوب يعيد صفحة فارغة دائماً؛ اسحب الطرف الآخر معه.
        if (_toDate != null && _toDate!.isBefore(picked)) _toDate = picked;
      } else {
        _toDate = picked;
        if (_fromDate != null && _fromDate!.isAfter(picked)) _fromDate = picked;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuditLogsBloc, AuditLogsState>(
      buildWhen: (p, c) => p.knownActions != c.knownActions,
      builder: (context, state) {
        return Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.allMd,
            border: Border.all(color: AppColors.border),
            boxShadow: const [
              BoxShadow(
                color: AppColors.shadowSoft,
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                textDirection: TextDirection.rtl,
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.md,
                children: [
                  _FilterSlot(
                    width: 210,
                    child: _ActionDropdown(
                      value: _action,
                      actions: state.knownActions,
                      onChanged: (value) => setState(() => _action = value),
                    ),
                  ),
                  _FilterSlot(
                    width: 170,
                    child: _StatusDropdown(
                      value: _status,
                      onChanged: (value) => setState(() => _status = value),
                    ),
                  ),
                  _FilterSlot(
                    width: 170,
                    child: _TextFilterField(
                      controller: _userIdController,
                      label: 'معرّف المستخدم',
                      icon: Icons.person_outline_rounded,
                      isNumeric: true,
                    ),
                  ),
                  _FilterSlot(
                    width: 190,
                    child: _TextFilterField(
                      controller: _resourceTypeController,
                      label: 'نوع المورد',
                      hint: 'task، user، transaction…',
                      icon: Icons.category_outlined,
                    ),
                  ),
                  _FilterSlot(
                    width: 180,
                    child: _DateFilterField(
                      label: 'من تاريخ',
                      value: _fromDate,
                      onTap: () => _pickDate(isFrom: true),
                      onClear: _fromDate == null
                          ? null
                          : () => setState(() => _fromDate = null),
                    ),
                  ),
                  _FilterSlot(
                    width: 180,
                    child: _DateFilterField(
                      label: 'إلى تاريخ',
                      value: _toDate,
                      onTap: () => _pickDate(isFrom: false),
                      onClear: _toDate == null
                          ? null
                          : () => setState(() => _toDate = null),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                textDirection: TextDirection.rtl,
                children: [
                  FilledButton.icon(
                    onPressed: _apply,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 22, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: AppRadius.allSm,
                      ),
                    ),
                    icon: const Icon(Icons.filter_alt_rounded, size: 18),
                    label: const Text('تطبيق الفلاتر'),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  OutlinedButton.icon(
                    onPressed: _clear,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      side: const BorderSide(color: AppColors.border),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: AppRadius.allSm,
                      ),
                    ),
                    icon: const Icon(Icons.clear_rounded, size: 18),
                    label: const Text('مسح'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

/// يمنح كل حقل عرضاً ثابتاً داخل الـ Wrap كي تصطفّ الحقول في شبكة منتظمة.
class _FilterSlot extends StatelessWidget {
  final double width;
  final Widget child;

  const _FilterSlot({required this.width, required this.child});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: width, minWidth: 150),
      child: child,
    );
  }
}

class _FilterLabel extends StatelessWidget {
  final String text;

  const _FilterLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, right: 2),
      child: Text(
        text,
        textAlign: TextAlign.right,
        textDirection: TextDirection.rtl,
        style: const TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

InputDecoration _fieldDecoration({
  String? hint,
  Widget? icon,
  Widget? suffix,
}) {
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(
      fontSize: 13,
      color: AppColors.textSecondary,
    ),
    prefixIcon: icon,
    suffixIcon: suffix,
    isDense: true,
    filled: true,
    fillColor: AppColors.surface,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: AppRadius.allSm,
      borderSide: const BorderSide(color: AppColors.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: AppRadius.allSm,
      borderSide: const BorderSide(color: AppColors.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: AppRadius.allSm,
      borderSide: const BorderSide(color: AppColors.primary),
    ),
  );
}

class _TextFilterField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData icon;
  final bool isNumeric;

  const _TextFilterField({
    required this.controller,
    required this.label,
    required this.icon,
    this.hint,
    this.isNumeric = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _FilterLabel(label),
        TextField(
          controller: controller,
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.right,
          keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
          inputFormatters:
              isNumeric ? [FilteringTextInputFormatter.digitsOnly] : null,
          style: const TextStyle(fontSize: 13.5),
          decoration: _fieldDecoration(
            hint: hint,
            icon: Icon(icon, size: 18, color: AppColors.textSecondary),
          ),
        ),
      ],
    );
  }
}

class _ActionDropdown extends StatelessWidget {
  final String? value;
  final List<String> actions;
  final ValueChanged<String?> onChanged;

  const _ActionDropdown({
    required this.value,
    required this.actions,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    // الكود المحفوظ في الفلتر قد لا يكون ضمن known_actions بعد (أول تحميل)،
    // فنضيفه للقائمة كي لا يرمي DropdownButton على قيمة بلا عنصر مطابق.
    final options = <String>{
      if (value != null && value!.isNotEmpty) value!,
      ...actions,
    }.toList()
      ..sort();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _FilterLabel('الحدث'),
        DropdownButtonFormField<String?>(
          initialValue: value,
          isExpanded: true,
          decoration: _fieldDecoration(
            icon: const Icon(Icons.bolt_outlined,
                size: 18, color: AppColors.textSecondary),
          ),
          style: const TextStyle(fontSize: 13.5, color: AppColors.textPrimary),
          dropdownColor: AppColors.surface,
          borderRadius: AppRadius.allSm,
          hint: const Text('كل الأحداث', style: TextStyle(fontSize: 13)),
          items: [
            const DropdownMenuItem<String?>(
              value: null,
              child: Text('كل الأحداث', textDirection: TextDirection.rtl),
            ),
            for (final action in options)
              DropdownMenuItem<String?>(
                value: action,
                child: Text(
                  auditActionLabel(action),
                  textDirection: TextDirection.rtl,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _StatusDropdown extends StatelessWidget {
  final AuditLogStatus? value;
  final ValueChanged<AuditLogStatus?> onChanged;

  const _StatusDropdown({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _FilterLabel('الحالة'),
        DropdownButtonFormField<AuditLogStatus?>(
          initialValue: value,
          isExpanded: true,
          decoration: _fieldDecoration(
            icon: const Icon(Icons.flag_outlined,
                size: 18, color: AppColors.textSecondary),
          ),
          style: const TextStyle(fontSize: 13.5, color: AppColors.textPrimary),
          dropdownColor: AppColors.surface,
          borderRadius: AppRadius.allSm,
          hint: const Text('كل الحالات', style: TextStyle(fontSize: 13)),
          items: [
            const DropdownMenuItem<AuditLogStatus?>(
              value: null,
              child: Text('كل الحالات', textDirection: TextDirection.rtl),
            ),
            // unknown حالة عرض محلية فقط ولا يقبلها الخادم كفلتر.
            for (final status in const [
              AuditLogStatus.success,
              AuditLogStatus.failure,
              AuditLogStatus.blocked,
            ])
              DropdownMenuItem<AuditLogStatus?>(
                value: status,
                child: Text(status.label, textDirection: TextDirection.rtl),
              ),
          ],
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _DateFilterField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  const _DateFilterField({
    required this.label,
    required this.value,
    required this.onTap,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _FilterLabel(label),
        InkWell(
          onTap: onTap,
          borderRadius: AppRadius.allSm,
          child: InputDecorator(
            decoration: _fieldDecoration(
              icon: const Icon(Icons.calendar_today_outlined,
                  size: 17, color: AppColors.textSecondary),
              suffix: onClear == null
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close_rounded, size: 16),
                      color: AppColors.textSecondary,
                      splashRadius: 16,
                      onPressed: onClear,
                    ),
            ),
            child: Text(
              value == null ? 'غير محدّد' : auditApiDay(value!),
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
              style: TextStyle(
                fontSize: 13.5,
                color: value == null
                    ? AppColors.textSecondary
                    : AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
