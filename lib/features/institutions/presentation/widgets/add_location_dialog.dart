import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/enums/form_status.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/app_id_dropdown.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../bloc/institutions_bloc.dart';
import '../bloc/institutions_event.dart';
import '../bloc/institutions_state.dart';

/// Small dialog to add a new location, opened from the location picker inside
/// the create-institution dialog. Reuses the same [InstitutionsBloc].
///
/// There is no dedicated "list location types" endpoint, so the type options
/// are derived from the types already present on the loaded locations.
class AddLocationDialog extends StatefulWidget {
  const AddLocationDialog({super.key});

  @override
  State<AddLocationDialog> createState() => _AddLocationDialogState();
}

class _AddLocationDialogState extends State<AddLocationDialog> {
  final _nameController = TextEditingController();
  int? _typeId;
  bool _nameTouched = false;
  bool _typeTouched = false;

  @override
  void initState() {
    super.initState();
    // Default to the only/first known location type when there is exactly one.
    final types = _typeItems(context.read<InstitutionsBloc>().state);
    if (types.length == 1) _typeId = types.keys.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  /// `{ typeId: typeName }` derived from the loaded locations.
  Map<int, String> _typeItems(InstitutionsState state) {
    final map = <int, String>{};
    for (final l in state.locations) {
      if (l.typeId != null) {
        map[l.typeId!] = l.typeName ?? 'نوع #${l.typeId}';
      }
    }
    return map;
  }

  void _submit(BuildContext context) {
    final name = _nameController.text.trim();
    setState(() {
      _nameTouched = true;
      _typeTouched = true;
    });
    if (name.isEmpty || _typeId == null) return;

    context.read<InstitutionsBloc>().add(
          CreateLocationRequested(
            name: name,
            typeLocationId: _typeId!,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<InstitutionsBloc, InstitutionsState>(
      listenWhen: (p, c) => p.locationFormStatus != c.locationFormStatus,
      listener: (context, state) {
        if (state.locationFormStatus == FormStatus.success) {
          AppSnackBar.show(context, message: 'تم إضافة الموقع بنجاح');
          Navigator.of(context).pop();
        } else if (state.locationFormStatus == FormStatus.failure) {
          AppSnackBar.show(
            context,
            message: state.locationFormError ?? 'تعذّر إضافة الموقع',
            isError: true,
          );
        }
      },
      builder: (context, state) {
        final submitting =
            state.locationFormStatus == FormStatus.submitting;
        final typeItems = _typeItems(state);

        return Directionality(
          textDirection: TextDirection.rtl,
          child: Dialog(
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            child: SizedBox(
              width: 520,
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
                        const _FieldLabel('اسم الموقع *'),
                        const SizedBox(height: 8),
                        _TextInput(
                          controller: _nameController,
                          hint: 'أدخل اسم الموقع...',
                          errorText: _nameTouched &&
                                  _nameController.text.trim().isEmpty
                              ? 'هذا الحقل مطلوب'
                              : null,
                        ),
                        const SizedBox(height: 22),
                        const _FieldLabel('نوع الموقع *'),
                        const SizedBox(height: 8),
                        AppIdDropdown(
                          hint: 'اختر نوع الموقع...',
                          value: _typeId,
                          items: typeItems,
                          onChanged: (v) => setState(() {
                            _typeId = v;
                            _typeTouched = true;
                          }),
                          errorText: _typeTouched && _typeId == null
                              ? 'هذا الحقل مطلوب'
                              : null,
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
          const Icon(Icons.add_location_alt_outlined,
              color: AppColors.primary, size: 24),
          const SizedBox(width: 10),
          const Text(
            'إضافة موقع جديد',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const Spacer(),
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

class _TextInput extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final String? errorText;

  const _TextInput({
    required this.controller,
    required this.hint,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      textAlign: TextAlign.right,
      textDirection: TextDirection.rtl,
      decoration: InputDecoration(
        hintText: hint,
        errorText: errorText,
        hintStyle: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 15,
        ),
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
                      'حفظ الموقع',
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
