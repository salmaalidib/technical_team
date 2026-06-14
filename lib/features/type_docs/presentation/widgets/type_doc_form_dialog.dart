import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/enums/form_status.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../bloc/type_docs_bloc.dart';
import '../bloc/type_docs_event.dart';
import '../bloc/type_docs_state.dart';

/// Name-only dialog to create a new document type, or rename an existing one
/// when [id] is non-null. Must be shown with a [TypeDocsBloc] in its context
/// (pass it via `BlocProvider.value`).
class TypeDocFormDialog extends StatefulWidget {
  final int? id;
  final String? initialName;

  const TypeDocFormDialog({super.key, this.id, this.initialName});

  bool get isEdit => id != null;

  @override
  State<TypeDocFormDialog> createState() => _TypeDocFormDialogState();
}

class _TypeDocFormDialogState extends State<TypeDocFormDialog> {
  late final TextEditingController _name =
      TextEditingController(text: widget.initialName ?? '');
  bool _touched = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  String? get _nameError {
    final value = _name.text.trim();
    if (value.isEmpty) return 'هذا الحقل مطلوب';
    if (value.length > 256) return '256 حرفاً كحد أقصى';
    return null;
  }

  void _submit(BuildContext context) {
    setState(() => _touched = true);
    if (_nameError != null) return;

    final name = _name.text.trim();
    final bloc = context.read<TypeDocsBloc>();
    if (widget.isEdit) {
      bloc.add(RenameTypeDocRequested(id: widget.id!, name: name));
    } else {
      bloc.add(CreateTypeDocRequested(name: name));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TypeDocsBloc, TypeDocsState>(
      listenWhen: (p, c) => p.formStatus != c.formStatus,
      listener: (context, state) {
        if (state.formStatus == FormStatus.success) {
          AppSnackBar.show(
            context,
            message: widget.isEdit
                ? 'تم تعديل نوع المستند بنجاح'
                : 'تم إضافة نوع المستند بنجاح',
          );
          Navigator.of(context).pop();
        } else if (state.formStatus == FormStatus.failure) {
          AppSnackBar.show(
            context,
            message: state.formError ?? 'تعذّر حفظ نوع المستند',
            isError: true,
          );
        }
      },
      builder: (context, state) {
        final submitting = state.formStatus == FormStatus.submitting;

        return Directionality(
          textDirection: TextDirection.rtl,
          child: Dialog(
            backgroundColor: AppColors.surface,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            child: SizedBox(
              width: 460,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _Header(
                    title: widget.isEdit ? 'تعديل نوع المستند' : 'إضافة نوع مستند',
                    onClose: () => Navigator.pop(context),
                  ),
                  const Divider(height: 1, color: AppColors.border),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(28, 24, 28, 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'اسم نوع المستند *',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _name,
                          autofocus: true,
                          textAlign: TextAlign.right,
                          textDirection: TextDirection.rtl,
                          onChanged: (_) => setState(() {}),
                          onSubmitted: (_) => _submit(context),
                          decoration: InputDecoration(
                            hintText: 'مثال: شهادة ميلاد',
                            errorText: _touched ? _nameError : null,
                            hintStyle: const TextStyle(
                                color: AppColors.textSecondary, fontSize: 15),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 14),
                            border: _border(AppColors.border),
                            enabledBorder: _border(AppColors.border),
                            focusedBorder: _border(AppColors.primary),
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Divider(height: 1, color: AppColors.border),
                        const SizedBox(height: 16),
                        _Actions(
                          submitting: submitting,
                          saveLabel: widget.isEdit ? 'حفظ' : 'إضافة',
                          onSave: () => _submit(context),
                          onCancel: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  final String title;
  final VoidCallback onClose;

  const _Header({required this.title, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          InkWell(
            onTap: onClose,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.inputBackground,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.close_rounded,
                  size: 22, color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

class _Actions extends StatelessWidget {
  final bool submitting;
  final String saveLabel;
  final VoidCallback onSave;
  final VoidCallback onCancel;

  const _Actions({
    required this.submitting,
    required this.saveLabel,
    required this.onSave,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: submitting ? null : onSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: submitting
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      saveLabel,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700),
                    ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: SizedBox(
            height: 48,
            child: TextButton(
              onPressed: submitting ? null : onCancel,
              style: TextButton.styleFrom(
                backgroundColor: AppColors.inputBackground,
                foregroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text(
                'إلغاء',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

OutlineInputBorder _border(Color color) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: color),
    );
