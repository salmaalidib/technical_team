import 'package:flutter/material.dart';

import '../../../../core/enums/request_status.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../domain/entities/permission.dart';

/// Searchable checkbox list of every permission in the system.
///
/// Shows [Permission.name] (the Arabic label) with [Permission.code] as a
/// secondary line; search matches either. Two chips filter locally on
/// [Permission.type]: «تقني» (admin) and «موظف» (employee).
class PermissionPicker extends StatefulWidget {
  final RequestStatus status;
  final List<Permission> permissions;
  final Set<int> selectedIds;
  final ValueChanged<Set<int>> onChanged;

  /// Height of the scrollable list area.
  final double listHeight;

  const PermissionPicker({
    super.key,
    required this.status,
    required this.permissions,
    required this.selectedIds,
    required this.onChanged,
    this.listHeight = 240,
  });

  @override
  State<PermissionPicker> createState() => _PermissionPickerState();
}

/// The local audience filter chips: `admin` is labeled «تقني» in the UI.
/// Matching uses [Permission.audiences], so shared (`employee,citizen,admin`)
/// rows show under both chips.
enum _TypeFilter { admin, employee }

class _PermissionPickerState extends State<PermissionPicker> {
  final _searchController = TextEditingController();

  /// Shared by the list and its [Scrollbar]; the ambient
  /// [PrimaryScrollController] is not attached to this nested list.
  final _listController = ScrollController();

  String _query = '';
  _TypeFilter _typeFilter = _TypeFilter.employee;

  @override
  void dispose() {
    _searchController.dispose();
    _listController.dispose();
    super.dispose();
  }

  bool _matchesType(Permission p) {
    return switch (_typeFilter) {
      _TypeFilter.admin => p.audiences.contains('admin'),
      _TypeFilter.employee => p.audiences.contains('employee'),
    };
  }

  List<Permission> get _filtered {
    final q = _query.trim().toLowerCase();

    return widget.permissions
        .where(_matchesType)
        .where((p) =>
            q.isEmpty ||
            p.name.toLowerCase().contains(q) ||
            p.code.toLowerCase().contains(q))
        .toList();
  }

  void _toggle(int id, bool selected) {
    final next = {...widget.selectedIds};
    if (selected) {
      next.add(id);
    } else {
      next.remove(id);
    }
    widget.onChanged(next);
  }

  /// Applies to the filtered subset only, so "select all" during a search
  /// doesn't silently select hidden permissions.
  void _toggleAllVisible(bool selectAll) {
    final visibleIds = _filtered.map((p) => p.id);
    final next = {...widget.selectedIds};
    if (selectAll) {
      next.addAll(visibleIds);
    } else {
      next.removeAll(visibleIds);
    }
    widget.onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.status == RequestStatus.loading) {
      return _shell(
        child: const Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (widget.status == RequestStatus.failure) {
      return _shell(
        child: const Center(
          child: Text(
            'تعذّر تحميل الصلاحيات',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
        ),
      );
    }

    if (widget.status == RequestStatus.success && widget.permissions.isEmpty) {
      return _shell(
        child: const Center(
          child: Text(
            'لا توجد صلاحيات',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
        ),
      );
    }

    final filtered = _filtered;
    final visibleIds = filtered.map((p) => p.id).toSet();
    final allVisibleSelected = visibleIds.isNotEmpty &&
        visibleIds.every(widget.selectedIds.contains);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _typeChips(),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _searchField()),
            const SizedBox(width: 12),
            TextButton(
              onPressed: visibleIds.isEmpty
                  ? null
                  : () => _toggleAllVisible(!allVisibleSelected),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              child: Text(
                allVisibleSelected ? 'إلغاء تحديد الكل' : 'تحديد الكل',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _shell(
          child: filtered.isEmpty
              ? const Center(
                  child: Text(
                    'لا توجد نتائج مطابقة',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                )
              : Scrollbar(
                  controller: _listController,
                  child: ListView.builder(
                    controller: _listController,
                    padding: EdgeInsets.zero,
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final permission = filtered[index];
                      final selected =
                          widget.selectedIds.contains(permission.id);

                      return CheckboxListTile(
                        value: selected,
                        onChanged: (v) => _toggle(permission.id, v ?? false),
                        dense: true,
                        controlAffinity: ListTileControlAffinity.leading,
                        activeColor: AppColors.primary,
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 8),
                        title: Text(
                          permission.name,
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontSize: 14.5,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        subtitle: Text(
                          permission.code,
                          textAlign: TextAlign.right,
                          textDirection: TextDirection.ltr,
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ),
        const SizedBox(height: 8),
        Text(
          'المحدَّد: ${widget.selectedIds.length} من ${widget.permissions.length}',
          textAlign: TextAlign.right,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  static const _typeFilterLabels = {
    _TypeFilter.admin: 'تقني',
    _TypeFilter.employee: 'موظف',
  };

  Widget _typeChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: _TypeFilter.values.map((filter) {
        final selected = _typeFilter == filter;
        return ChoiceChip(
          label: Text(_typeFilterLabels[filter]!),
          selected: selected,
          onSelected: (_) => setState(() => _typeFilter = filter),
          selectedColor: AppColors.primary.withValues(alpha: 0.15),
          labelStyle: TextStyle(
            fontSize: 12.5,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? AppColors.primary : AppColors.textSecondary,
          ),
          side: BorderSide(
            color: selected ? AppColors.primary : AppColors.border,
          ),
          visualDensity: VisualDensity.compact,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        );
      }).toList(),
    );
  }

  Widget _shell({required Widget child}) {
    return Container(
      height: widget.listHeight,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }

  Widget _searchField() {
    return TextField(
      controller: _searchController,
      textAlign: TextAlign.right,
      onChanged: (v) => setState(() => _query = v),
      decoration: InputDecoration(
        hintText: 'ابحث عن صلاحية...',
        isDense: true,
        prefixIcon: const Icon(Icons.search_rounded, size: 20),
        hintStyle:
            const TextStyle(color: AppColors.textSecondary, fontSize: 14),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
      ),
    );
  }
}
