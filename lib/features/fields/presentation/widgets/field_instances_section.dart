import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../domain/entities/field_type.dart';
import '../bloc/fields_bloc.dart';
import '../bloc/fields_state.dart';
import 'field_type_card.dart';

class FieldInstancesSection extends StatelessWidget {
  final VoidCallback onAdd;

  const FieldInstancesSection({super.key, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FieldsBloc, FieldsState>(
      buildWhen: (p, c) =>
          p.selectedType != c.selectedType ||
          p.textFields != c.textFields ||
          p.radioGroups != c.radioGroups ||
          p.textDropdowns != c.textDropdowns ||
          p.checkLists != c.checkLists ||
          p.datePickers != c.datePickers ||
          p.filePickers != c.filePickers,
      builder: (context, state) {
        final type = state.selectedType;
        final meta = kFieldTypeMeta[type]!;

        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Directionality(
                textDirection: TextDirection.rtl,
                child: Row(
                  children: [
                    Text(
                      meta.label,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        meta.description,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      height: 44,
                      child: ElevatedButton(
                        onPressed: onAdd,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          // Override the theme's full-width default
                          // (minimumSize: Size(double.infinity, 58)) so this
                          // button shrink-wraps instead of demanding infinite
                          // width as a non-flex child of a Row.
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          padding:
                              const EdgeInsets.symmetric(horizontal: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          textDirection: TextDirection.rtl,
                          children: [
                            const Icon(Icons.add_rounded, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'إضافة ${meta.label}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Divider(height: 1, color: AppColors.border),
              const SizedBox(height: 20),
              _InstancesList(type: type, state: state),
            ],
          ),
        );
      },
    );
  }
}

class _InstancesList extends StatelessWidget {
  final FieldType type;
  final FieldsState state;

  const _InstancesList({required this.type, required this.state});

  @override
  Widget build(BuildContext context) {
    final rows = _buildRows();

    if (rows.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Text(
            'لا توجد عناصر بعد — أضف أول عنصر من الزر أعلاه',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _TableHeader(),
        const SizedBox(height: 4),
        ...rows,
      ],
    );
  }

  List<Widget> _buildRows() {
    switch (type) {
      case FieldType.textField:
        return state.textFields
            .map((e) => _InstanceRow(
                  idWidget: e.idWidget,
                  label: e.label,
                  isRequired: e.isRequired,
                  detail: e.inputType,
                ))
            .toList();
      case FieldType.radioGroup:
        return state.radioGroups
            .map((e) => _InstanceRow(
                  idWidget: e.idWidget,
                  label: e.label,
                  isRequired: e.isRequired,
                  detail: '${e.options.length} خيارات',
                ))
            .toList();
      case FieldType.textDropdown:
        return state.textDropdowns
            .map((e) => _InstanceRow(
                  idWidget: e.idWidget,
                  label: e.label,
                  isRequired: e.isRequired,
                  detail: '${e.options.length} خيارات',
                ))
            .toList();
      case FieldType.checkList:
        return state.checkLists
            .map((e) => _InstanceRow(
                  idWidget: e.idWidget,
                  label: e.label,
                  isRequired: e.isRequired,
                  detail: '${e.minSelected}–${e.maxSelected} اختيارات',
                ))
            .toList();
      case FieldType.datePicker:
        return state.datePickers
            .map((e) => _InstanceRow(
                  idWidget: e.idWidget,
                  label: e.label,
                  isRequired: e.isRequired,
                  detail: '${e.minDate} → ${e.maxDate}',
                ))
            .toList();
      case FieldType.filePicker:
        return state.filePickers
            .map((e) => _InstanceRow(
                  idWidget: e.idWidget,
                  label: e.label,
                  isRequired: e.isRequired,
                  detail: '${e.maxSizeMb} MB',
                ))
            .toList();
    }
  }
}

class _TableHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.inputBackground,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          children: [
            Expanded(
              flex: 3,
              child: Text(
                'التسمية',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                'المعرّف',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                'التفاصيل',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            SizedBox(
              width: 80,
              child: Text(
                'إلزامي',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InstanceRow extends StatelessWidget {
  final String idWidget;
  final String label;
  final bool isRequired;
  final String detail;

  const _InstanceRow({
    required this.idWidget,
    required this.label,
    required this.isRequired,
    required this.detail,
  });

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: AppColors.border),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Text(
                label,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                idWidget,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontFamily: 'monospace',
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                detail,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ),
            SizedBox(
              width: 80,
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isRequired
                        ? AppColors.lightPrimary
                        : AppColors.inputBackground,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isRequired ? 'إلزامي' : 'اختياري',
                    style: TextStyle(
                      color: isRequired
                          ? AppColors.primary
                          : AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
