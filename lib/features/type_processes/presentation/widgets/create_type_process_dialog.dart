import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/enums/form_status.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../bloc/type_processes_bloc.dart';
import '../bloc/type_processes_event.dart';
import '../bloc/type_processes_state.dart';

class CreateTypeProcessDialog extends StatefulWidget {
  const CreateTypeProcessDialog({super.key});

  @override
  State<CreateTypeProcessDialog> createState() =>
      _CreateTypeProcessDialogState();
}

class _CreateTypeProcessDialogState extends State<CreateTypeProcessDialog> {
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  bool _touched = false;

  static final _codePattern = RegExp(r'^[A-Z0-9_]{2,20}$');

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  String? get _nameError {
    final name = _nameController.text.trim();
    if (name.isEmpty) return 'هذا الحقل مطلوب';
    if (name.length < 2) return 'حرفان على الأقل';
    if (name.length > 100) return '100 حرف كحد أقصى';
    return null;
  }

  String? get _codeError {
    final code = _codeController.text.trim().toUpperCase();
    if (code.isEmpty) return 'هذا الحقل مطلوب';
    if (!_codePattern.hasMatch(code)) {
      return 'حروف إنجليزية كبيرة أو أرقام أو _ فقط (2-20)';
    }
    return null;
  }

  void _submit(BuildContext context) {
    setState(() => _touched = true);
    if (_nameError != null || _codeError != null) return;

    context.read<TypeProcessesBloc>().add(
          CreateTypeProcessRequested(
            name: _nameController.text.trim(),
            code: _codeController.text.trim().toUpperCase(),
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final dialogWidth = screenWidth - 32 < 520.0 ? screenWidth - 32 : 520.0;

    return BlocConsumer<TypeProcessesBloc, TypeProcessesState>(
      listenWhen: (p, c) => p.formStatus != c.formStatus,
      listener: (context, state) {
        if (state.formStatus == FormStatus.success) {
          AppSnackBar.show(context, message: 'تم إنشاء نوع العملية بنجاح');
          Navigator.of(context).pop();
        } else if (state.formStatus == FormStatus.failure) {
          AppSnackBar.show(
            context,
            message: state.formError ?? 'تعذّر إنشاء نوع العملية',
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
            insetPadding: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            child: SizedBox(
              width: dialogWidth,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _Header(onClose: () => Navigator.pop(context)),
                  const Divider(height: 1, color: AppColors.border),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(28, 26, 28, 18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const _Label('اسم نوع العملية *'),
                          const SizedBox(height: 8),
                          _TextInput(
                            controller: _nameController,
                            hint: 'مثال: معاملة مدنية',
                            errorText: _touched ? _nameError : null,
                          ),
                          const SizedBox(height: 20),
                          const _Label('الرمز (code) *'),
                          const SizedBox(height: 8),
                          _TextInput(
                            controller: _codeController,
                            hint: 'مثال: CIVIL_TX',
                            errorText: _touched ? _codeError : null,
                            textDirection: TextDirection.ltr,
                            textAlign: TextAlign.left,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                  RegExp('[A-Za-z0-9_]')),
                              LengthLimitingTextInputFormatter(20),
                              _UpperCaseFormatter(),
                            ],
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
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 22),
      child: Row(
        children: [
          const Text(
            'إنشاء نوع عملية',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const Spacer(),
          InkWell(
            onTap: onClose,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.inputBackground,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.close_rounded,
                  size: 24, color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;

  const _Label(this.text);

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

class _TextInput extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final String? errorText;
  final TextDirection textDirection;
  final TextAlign textAlign;
  final List<TextInputFormatter>? inputFormatters;

  const _TextInput({
    required this.controller,
    required this.hint,
    this.errorText,
    this.textDirection = TextDirection.rtl,
    this.textAlign = TextAlign.right,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      textAlign: textAlign,
      textDirection: textDirection,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        hintText: hint,
        errorText: errorText,
        hintStyle:
            const TextStyle(color: AppColors.textSecondary, fontSize: 15),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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

/// Forces the `code` field to uppercase as the user types so it matches the
/// backend pattern `^[A-Z0-9_]{2,20}$`.
class _UpperCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
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
            height: 48,
            child: ElevatedButton(
              onPressed: submitting ? null : onSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: submitting
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'حفظ',
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
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
                  borderRadius: BorderRadius.circular(8),
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
