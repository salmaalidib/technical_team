import 'package:flutter/material.dart';

import '../../../../core/enums/request_status.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../domain/entities/permission.dart';

/// Searchable checkbox list of every permission in the system.
///
/// Shows [Permission.displayName] (the Arabic label); the technical code is
/// only used for filtering, since users search by either.
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

class _PermissionPickerState extends State<PermissionPicker> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Permission> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return widget.permissions;

    return widget.permissions
        .where((p) =>
            p.displayName.toLowerCase().contains(q) ||
            p.name.toLowerCase().contains(q))
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
                  child: ListView.builder(
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
                          permission.displayName,
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontSize: 14.5,
                            color: AppColors.textPrimary,
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
