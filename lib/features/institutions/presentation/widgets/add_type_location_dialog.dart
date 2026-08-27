import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/enums/form_status.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_dimens.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../bloc/institutions_bloc.dart';
import '../bloc/institutions_event.dart';
import '../bloc/institutions_state.dart';

/// Adds a location type (محافظة، منطقة، ناحية...) via `POST /api/type-location`.
///
/// Opened from the "+" beside the type dropdown in [AddLocationDialog], which
/// selects the created type on return. Uses its own form status so it never
/// collides with the add-location submit running underneath it.
class AddTypeLocationDialog extends StatefulWidget {
  const AddTypeLocationDialog({super.key});

  @override
  State<AddTypeLocationDialog> createState() => _AddTypeLocationDialogState();
}

class _AddTypeLocationDialogState extends State<AddTypeLocationDialog> {
  final _nameController = TextEditingController();
  bool _nameTouched = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit(BuildContext context) {
    final name = _nameController.text.trim();
    setState(() => _nameTouched = true);
    if (name.isEmpty) return;

    context
        .read<InstitutionsBloc>()
        .add(CreateTypeLocationRequested(name: name));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<InstitutionsBloc, InstitutionsState>(
      listenWhen: (p, c) =>
          p.typeLocationFormStatus != c.typeLocationFormStatus,
      listener: (context, state) {
        if (state.typeLocationFormStatus == FormStatus.success) {
          AppSnackBar.show(context, message: 'تم إضافة نوع الموقع بنجاح');
          Navigator.of(context).pop();
        } else if (state.typeLocationFormStatus == FormStatus.failure) {
          AppSnackBar.show(
            context,
            message: state.typeLocationFormError ?? 'تعذّر إضافة نوع الموقع',
            isError: true,
          );
        }
      },
      builder: (context, state) {
        final submitting =
            state.typeLocationFormStatus == FormStatus.submitting;

        return Directionality(
          textDirection: TextDirection.rtl,
          child: Dialog(
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: SizedBox(
              width: 460,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _Header(onClose: () => Navigator.pop(context)),
                  const Divider(height: 1, color: AppColors.border),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(28, 24, 28, 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const _FieldLabel('اسم النوع *'),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _nameController,
                          textAlign: TextAlign.right,
                          textDirection: TextDirection.rtl,
                          autofocus: true,
                          onSubmitted: (_) =>
                              submitting ? null : _submit(context),
                          decoration: InputDecoration(
                            hintText: 'مثال: منطقة، ناحية...',
                            errorText: _nameTouched &&
                                    _nameController.text.trim().isEmpty
                                ? 'هذا الحقل مطلوب'
                                : null,
                            hintStyle: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 15,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 14,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                              borderSide:
                                  const BorderSide(color: AppColors.border),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                              borderSide:
                                  const BorderSide(color: AppColors.border),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                              borderSide:
                                  const BorderSide(color: AppColors.primary),
                            ),
                          ),
                        ),
                        const SizedBox(height: 26),
                        const Divider(height: 1, color: AppColors.border),
                        const SizedBox(height: 18),
                        _Actions(
                          submitting: submitting,
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
  final VoidCallback onClose;

  const _Header({required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
      child: Row(
        children: [
          const Icon(Icons.category_outlined,
              color: AppColors.primary, size: 24),
          const SizedBox(width: 10),
          const Text(
            'إضافة نوع موقع',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const Spacer(),
          InkWell(
            onTap: onClose,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.inputBackground,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: const Icon(
                Icons.close_rounded,
                size: 22,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;

  const _FieldLabel(this.text);

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

class _Actions extends StatelessWidget {
  final bool submitting;
  final VoidCallback onSave;
  final VoidCallback onCancel;

  const _Actions({
    required this.submitting,
    required this.onSave,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 46,
            child: ElevatedButton(
              onPressed: submitting ? null : onSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
              ),
              child: submitting
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.white,
                      ),
                    )
                  : const Text(
                      'حفظ النوع',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: SizedBox(
            height: 46,
            child: TextButton(
              onPressed: submitting ? null : onCancel,
              style: TextButton.styleFrom(
                backgroundColor: AppColors.inputBackground,
                foregroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
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
