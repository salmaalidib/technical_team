import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/enums/request_status.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/app_id_dropdown.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../domain/entities/type_doc.dart';
import '../bloc/type_docs_bloc.dart';
import '../bloc/type_docs_event.dart';
import '../bloc/type_docs_state.dart';
import 'type_doc_form_dialog.dart';

/// Inline document-type picker for the file-picker form: a dropdown of the
/// active document types plus add / edit / delete (deactivate) actions.
///
/// Requires a [TypeDocsBloc] in its context. Reports the selected id via
/// [onChanged]; the parent owns the selection so it can include `type_doc_id`
/// in its request. A just-created type is auto-selected, and a selection that
/// gets deactivated is cleared.
class TypeDocSelector extends StatelessWidget {
  final int? value;
  final ValueChanged<int?> onChanged;
  final String? errorText;

  const TypeDocSelector({
    super.key,
    required this.value,
    required this.onChanged,
    this.errorText,
  });

  void _openForm(BuildContext context, {int? id, String? initialName}) {
    final bloc = context.read<TypeDocsBloc>();
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.55),
      builder: (_) => BlocProvider.value(
        value: bloc,
        child: TypeDocFormDialog(id: id, initialName: initialName),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, TypeDoc doc) async {
    final bloc = context.read<TypeDocsBloc>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('حذف نوع المستند'),
          content: Text('سيتم إخفاء "${doc.name}" من القائمة. هل أنت متأكد؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: TextButton.styleFrom(foregroundColor: AppColors.error),
              child: const Text('حذف'),
            ),
          ],
        ),
      ),
    );
    if (confirmed == true) {
      bloc.add(DeactivateTypeDocRequested(id: doc.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        // Auto-select a just-created type.
        BlocListener<TypeDocsBloc, TypeDocsState>(
          listenWhen: (p, c) =>
              p.lastCreatedId != c.lastCreatedId && c.lastCreatedId != null,
          listener: (_, state) => onChanged(state.lastCreatedId),
        ),
        // If the current selection was deactivated, clear it.
        BlocListener<TypeDocsBloc, TypeDocsState>(
          listenWhen: (p, c) => p.typeDocs != c.typeDocs,
          listener: (_, state) {
            final activeIds = state.typeDocs
                .where((t) => t.isActive)
                .map((t) => t.id)
                .toSet();
            if (value != null && !activeIds.contains(value)) {
              onChanged(null);
            }
          },
        ),
        // Surface inline action errors (deactivate).
        BlocListener<TypeDocsBloc, TypeDocsState>(
          listenWhen: (p, c) =>
              p.actionError != c.actionError && c.actionError != null,
          listener: (context, state) =>
              AppSnackBar.show(context, message: state.actionError!, isError: true),
        ),
      ],
      child: BlocBuilder<TypeDocsBloc, TypeDocsState>(
        builder: (context, state) {
          final active = state.typeDocs.where((t) => t.isActive).toList();
          final loading = state.status == RequestStatus.loading;
          final matches = active.where((t) => t.id == value);
          final selected = matches.isEmpty ? null : matches.first;
          final deactivating =
              value != null && state.busyIds.contains(value);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                textDirection: TextDirection.rtl,
                children: [
                  Expanded(
                    child: AppIdDropdown(
                      hint: loading ? 'جارٍ التحميل...' : 'اختر نوع المستند...',
                      value: value,
                      items: {for (final t in active) t.id: t.name},
                      onChanged: onChanged,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _IconButton(
                    icon: Icons.add_rounded,
                    tooltip: 'إضافة نوع',
                    onTap: () => _openForm(context),
                  ),
                  const SizedBox(width: 6),
                  _IconButton(
                    icon: Icons.edit_outlined,
                    tooltip: 'تعديل',
                    onTap: selected == null
                        ? null
                        : () => _openForm(context,
                            id: selected.id, initialName: selected.name),
                  ),
                  const SizedBox(width: 6),
                  deactivating
                      ? const SizedBox(
                          width: 46,
                          height: 46,
                          child: Center(
                            child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        )
                      : _IconButton(
                          icon: Icons.delete_outline_rounded,
                          tooltip: 'حذف',
                          color: AppColors.error,
                          onTap: selected == null
                              ? null
                              : () => _confirmDelete(context, selected),
                        ),
                ],
              ),
              if (errorText != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    errorText!,
                    textAlign: TextAlign.right,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// A square, bordered icon button that dims when [onTap] is null.
class _IconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  final Color? color;

  const _IconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final fg =
        enabled ? (color ?? AppColors.primary) : AppColors.textSecondary;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: AppColors.inputBackground,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 22, color: fg),
        ),
      ),
    );
  }
}
