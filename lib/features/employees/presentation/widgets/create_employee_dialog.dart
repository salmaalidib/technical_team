import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/active_org/active_organization_cubit.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/enums/form_status.dart';
import '../../../../core/enums/request_status.dart';
import '../../../../core/services/key_generation_service.dart';
import '../../../../core/services/key_storage_service.dart';
import '../../../../core/services/whatsapp_service.dart';
import '../../../../shared/theme/app_colors.dart';
import '../bloc/employees_bloc.dart';
import '../bloc/employees_event.dart';
import '../bloc/employees_state.dart';

class CreateEmployeeDialog extends StatefulWidget {
  const CreateEmployeeDialog({super.key});

  @override
  State<CreateEmployeeDialog> createState() => _CreateEmployeeDialogState();
}

class _CreateEmployeeDialogState extends State<CreateEmployeeDialog> {
  final _firstName = TextEditingController();
  final _fatherName = TextEditingController();
  final _motherName = TextEditingController();
  final _lastName = TextEditingController();
  final _nationalId = TextEditingController();
  final _phone = TextEditingController();
  final _userName = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _pin = TextEditingController();
  final _publicKey = TextEditingController();

  String? _lastGeneratedPassword;
  String? _lastGeneratedPin;

  // The organization is the user's active one, chosen once after login.
  late final int? _organizationId =
      getIt<ActiveOrganizationCubit>().activeOrgId;
  int? _departmentId;
  int? _roleId;
  bool _touched = false;

  @override
  void initState() {
    super.initState();
    _generatePasswordAndPin();
    // Load the active organization's departments for the (cascading) department
    // dropdown. Deferred to post-frame so the EmployeesBloc provided to this
    // dialog route is available.
    final orgId = _organizationId;
    if (orgId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.read<EmployeesBloc>().add(LoadEmployeeDepartments(orgId));
        }
      });
    }
  }

  void _generatePasswordAndPin() {
    _password.text = getIt<KeyStorageService>().generatePassword();
    _pin.text = getIt<KeyStorageService>().generatePin();
  }

  @override
  void dispose() {
    _firstName.dispose();
    _fatherName.dispose();
    _motherName.dispose();
    _lastName.dispose();
    _nationalId.dispose();
    _phone.dispose();
    _userName.dispose();
    _email.dispose();
    _password.dispose();
    _pin.dispose();
    _publicKey.dispose();
    super.dispose();
  }

  String? _required(TextEditingController c) {
    if (!_touched) return null;
    return c.text.trim().isEmpty ? 'هذا الحقل مطلوب' : null;
  }

  String? _pinError() {
    if (!_touched) return null;
    final value = _pin.text.trim();

    if (value.isEmpty) return 'هذا الحقل مطلوب';
    if (!RegExp(r'^\d{6}$').hasMatch(value)) {
      return 'يجب أن يكون PIN من 6 أرقام';
    }

    return null;
  }

  void _showDialogMessage(String message) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('تنبيه'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('حسناً'),
          ),
        ],
      ),
    );
  }

  void _showCredentialsDialog({
    required BuildContext rootContext,
    required String message,
    required String userName,
    required String phone,
    required String password,
    required String pin,
  }) {
    showDialog(
      context: rootContext,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('تم إنشاء الموظف بنجاح'),
        content: SelectableText(
          '$message\n\n'
          'كلمة المرور المؤقتة:\n$password\n\n'
          'رمز PIN:\n$pin\n\n'
          'يجب تسليم كلمة المرور والـ PIN للموظف وحفظهما جيداً.',
          textDirection: TextDirection.rtl,
        ),
        actions: [
          TextButton.icon(
            onPressed: () => _sendCredentialsToWhatsApp(
              dialogContext: dialogContext,
              userName: userName,
              phone: phone,
              password: password,
              pin: pin,
            ),
            icon: const Icon(Icons.send_rounded, size: 18),
            label: const Text('إرسال عبر واتساب'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('حسناً'),
          ),
        ],
      ),
    );
  }

  Future<void> _sendCredentialsToWhatsApp({
    required BuildContext dialogContext,
    required String userName,
    required String phone,
    required String password,
    required String pin,
  }) async {
    final trimmedPhone = phone.trim();
    if (trimmedPhone.isEmpty) {
      _showDialogMessage('لا يوجد رقم هاتف للموظف لإرسال الرسالة عبر واتساب');
      return;
    }

    final messenger = ScaffoldMessenger.maybeOf(dialogContext);
    final whatsapp = getIt<WhatsAppService>();
    final body = WhatsAppService.buildCredentialsMessage(
      userName: userName,
      password: password,
      pin: pin,
    );

    final opened = await whatsapp.sendCredentials(
      phone: trimmedPhone,
      message: body,
    );

    if (!opened) {
      // canLaunchUrl/launchUrl failed (no WhatsApp and no browser handler).
      _showDialogMessage('تعذّر فتح واتساب على هذا الجهاز');
      return;
    }

    messenger?.showSnackBar(
      const SnackBar(
        content: Text('تم فتح واتساب — اضغط إرسال لإتمام إرسال الرسالة'),
      ),
    );
  }

  Future<void> _submit(BuildContext context) async {
    debugPrint('CREATE EMPLOYEE BUTTON CLICKED');

    setState(() => _touched = true);

    final state = context.read<EmployeesBloc>().state;
    final hasDepartments = state.departments.isNotEmpty;
    final hasRoles = state.roles.isNotEmpty;

    if (_firstName.text.trim().isEmpty ||
        _fatherName.text.trim().isEmpty ||
        _motherName.text.trim().isEmpty ||
        _lastName.text.trim().isEmpty ||
        _nationalId.text.trim().isEmpty ||
        _phone.text.trim().isEmpty ||
        _userName.text.trim().isEmpty ||
        _email.text.trim().isEmpty ||
        _password.text.trim().isEmpty ||
        _pin.text.trim().isEmpty ||
        !RegExp(r'^\d{6}$').hasMatch(_pin.text.trim()) ||
        _organizationId == null ||
        (hasDepartments && _departmentId == null) ||
        (hasRoles && _roleId == null)) {
      _showDialogMessage('املأ كل الحقول المطلوبة أولاً');
      return;
    }

    try {
      final generatedPassword = _password.text.trim();
      final generatedPin = _pin.text.trim();

      _lastGeneratedPassword = generatedPassword;
      _lastGeneratedPin = generatedPin;

      debugPrint('GENERATING KEYS...');
      final keys = await getIt<KeyGenerationService>().generateKeys();

      debugPrint('PICKING FLASH DIRECTORY...');
      final directoryPath =
          await getIt<KeyStorageService>().pickExternalDirectory();

      if (directoryPath == null) {
        _showDialogMessage('لم يتم اختيار مجلد لحفظ المفاتيح');
        return;
      }

      debugPrint('SAVING KEYS TO: $directoryPath');

      await getIt<KeyStorageService>().saveEmployeeKeys(
        directoryPath: directoryPath,
        userName: _userName.text.trim(),
        privateKey: keys.privateKey,
        publicKey: keys.publicKey,
        pin: generatedPin,
      );

      _publicKey.text = keys.publicKey;

      if (!context.mounted) return;

      debugPrint('SENDING CREATE EMPLOYEE REQUEST...');

      context.read<EmployeesBloc>().add(
            CreateEmployeeRequested(
              firstName: _firstName.text,
              lastName: _lastName.text,
              fatherName: _fatherName.text,
              motherName: _motherName.text,
              nationalId: _nationalId.text,
              userName: _userName.text,
              email: _email.text,
              phoneNumber: _phone.text,
              password: generatedPassword,
              pin: generatedPin,
              confirmPin: generatedPin,
              organizationId: _organizationId,
              departmentId: _departmentId,
              roleId: _roleId,
              publicKey: _publicKey.text,
            ),
          );
    } catch (e) {
      debugPrint('CREATE EMPLOYEE ERROR: $e');

      if (!context.mounted) return;

      _showDialogMessage(
        e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<EmployeesBloc, EmployeesState>(
      listenWhen: (p, c) =>
          p.formStatus != c.formStatus || p.actionError != c.actionError,
      listener: (context, state) {
        if (state.formStatus == FormStatus.success) {
          final successMessage =
              state.createdEmployee?.message ?? 'تم إنشاء حساب الموظف بنجاح';

          final password = _lastGeneratedPassword ?? '';
          final pin = _lastGeneratedPin ?? '';

          // Capture the controller values BEFORE the pop — popping unmounts this
          // State and disposes the controllers, so reading them afterwards is
          // unsafe.
          final userName = _userName.text.trim();
          final phone = _phone.text.trim();

          // Capture the navigator that hosts this page BEFORE popping the
          // create dialog. After the pop this State is unmounted, so its own
          // context is defunct — but this navigator outlives it and can host
          // the credentials dialog.
          final navigator = Navigator.of(context);

          navigator.pop();

          // Show the credentials dialog on the root navigator's context, which
          // is still mounted after the create dialog is gone.
          _showCredentialsDialog(
            rootContext: navigator.context,
            message: successMessage,
            userName: userName,
            phone: phone,
            password: password,
            pin: pin,
          );
        }

        if (state.formStatus == FormStatus.failure) {
          _showDialogMessage(state.formError ?? 'تعذّر إنشاء الموظف');
        }

        if (state.actionError != null) {
          _showDialogMessage(state.actionError!);
        }
      },
      builder: (context, state) {
        final submitting = state.formStatus == FormStatus.submitting;
        final hasDepartments = state.departments.isNotEmpty;
        final hasRoles = state.roles.isNotEmpty;

        return Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 24,
          ),
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 920,
              maxHeight: 760,
            ),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(28, 26, 28, 22),
                    child: Row(
                      children: [
                        Text(
                          'إنشاء موظف جديد',
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const Spacer(),
                        InkWell(
                          onTap: () => Navigator.pop(context),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: AppColors.inputBackground,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.close_rounded),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: AppColors.border),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const _SectionTitle(
                            icon: Icons.person_outline_rounded,
                            title: 'بيانات الموظف',
                            subtitle:
                                'قم بإدخال بيانات الموظف الأساسية وحساب الدخول',
                          ),
                          const SizedBox(height: 26),
                          _TwoFieldsRow(
                            first: _AppTextField(
                              controller: _firstName,
                              label: 'الاسم الأول *',
                              hint: 'مثال: أحمد',
                              errorText: _required(_firstName),
                            ),
                            second: _AppTextField(
                              controller: _fatherName,
                              label: 'اسم الأب *',
                              hint: 'مثال: محمود',
                              errorText: _required(_fatherName),
                            ),
                          ),
                          const SizedBox(height: 18),
                          _TwoFieldsRow(
                            first: _AppTextField(
                              controller: _motherName,
                              label: 'اسم الأم *',
                              hint: 'مثال: فاطمة',
                              errorText: _required(_motherName),
                            ),
                            second: _AppTextField(
                              controller: _lastName,
                              label: 'الاسم الأخير *',
                              hint: 'مثال: الأحمد',
                              errorText: _required(_lastName),
                            ),
                          ),
                          const SizedBox(height: 18),
                          _TwoFieldsRow(
                            first: _AppTextField(
                              controller: _nationalId,
                              label: 'الرقم الوطني *',
                              hint: 'مثال: 01010101010',
                              errorText: _required(_nationalId),
                            ),
                            second: _AppTextField(
                              controller: _phone,
                              label: 'رقم الهاتف *',
                              hint: '09xxxxxxxx',
                              errorText: _required(_phone),
                            ),
                          ),
                          const SizedBox(height: 18),
                          _TwoFieldsRow(
                            first: _AppTextField(
                              controller: _userName,
                              label: 'اسم المستخدم *',
                              hint: 'مثال: ahmad.mahmoud',
                              errorText: _required(_userName),
                            ),
                            second: _AppTextField(
                              controller: _email,
                              label: 'البريد الإلكتروني *',
                              hint: 'example@edu.sy',
                              errorText: _required(_email),
                            ),
                          ),
                          const SizedBox(height: 18),
                          _TwoFieldsRow(
                            first: _GeneratedTextField(
                              controller: _password,
                              label: 'كلمة المرور المؤقتة *',
                              hint: 'يتم توليدها تلقائياً',
                              errorText: _required(_password),
                              onGenerate: () {
                                setState(() {
                                  _password.text = getIt<KeyStorageService>()
                                      .generatePassword();
                                });
                              },
                            ),
                            second: _GeneratedTextField(
                              controller: _pin,
                              label: 'رمز PIN *',
                              hint: '6 أرقام',
                              errorText: _pinError(),
                              onGenerate: () {
                                setState(() {
                                  _pin.text =
                                      getIt<KeyStorageService>().generatePin();
                                });
                              },
                            ),
                          ),
                          const SizedBox(height: 18),
                          _AppTextField(
                            controller: _publicKey,
                            label: 'Public Key',
                            hint: 'يتم توليده تلقائياً عند الإنشاء',
                            readOnly: true,
                          ),
                          const SizedBox(height: 26),
                          const Divider(height: 1, color: AppColors.border),
                          const SizedBox(height: 24),
                          const _SectionTitle(
                            icon: Icons.account_tree_outlined,
                            title: 'التعيين الإداري',
                          ),
                          const SizedBox(height: 20),
                          _AppDropdown(
                            label: hasDepartments
                                ? 'القسم / الدائرة *'
                                : 'القسم / الدائرة',
                            hint:
                                state.departmentsStatus == RequestStatus.loading
                                    ? 'جار تحميل الأقسام...'
                                    : hasDepartments
                                        ? 'اختر القسم...'
                                        : 'لا توجد أقسام متاحة',
                            value: _departmentId,
                            items: {
                              for (final d in state.departments) d.id: d.name,
                            },
                            errorText: _touched &&
                                    hasDepartments &&
                                    _departmentId == null
                                ? 'هذا الحقل مطلوب'
                                : null,
                            onChanged: submitting || !hasDepartments
                                ? null
                                : (v) {
                                    setState(() {
                                      _departmentId = v;
                                      _roleId = null;
                                    });

                                    if (v != null) {
                                      context
                                          .read<EmployeesBloc>()
                                          .add(LoadEmployeeRoles(v));
                                    }
                                  },
                          ),
                          const SizedBox(height: 18),
                          _AppDropdown(
                            label: hasRoles ? 'الدور *' : 'الدور',
                            hint: state.rolesStatus == RequestStatus.loading
                                ? 'جار تحميل الأدوار...'
                                : hasRoles
                                    ? 'اختر الدور...'
                                    : 'لا توجد أدوار متاحة',
                            value: _roleId,
                            items: {
                              for (final r in state.roles) r.id: r.name,
                            },
                            errorText: _touched && hasRoles && _roleId == null
                                ? 'هذا الحقل مطلوب'
                                : null,
                            onChanged: submitting || !hasRoles
                                ? null
                                : (v) => setState(() => _roleId = v),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Divider(height: 1, color: AppColors.border),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(28, 18, 28, 22),
                    child: Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 54,
                            child: ElevatedButton(
                              onPressed:
                                  submitting ? null : () => _submit(context),
                              child: submitting
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text('إنشاء حساب الموظف'),
                            ),
                          ),
                        ),
                        const SizedBox(width: 18),
                        Expanded(
                          child: SizedBox(
                            height: 54,
                            child: ElevatedButton(
                              onPressed: submitting
                                  ? null
                                  : () => Navigator.pop(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.inputBackground,
                                foregroundColor: AppColors.primary,
                              ),
                              child: const Text('إلغاء'),
                            ),
                          ),
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

class _TwoFieldsRow extends StatelessWidget {
  final Widget first;
  final Widget second;

  const _TwoFieldsRow({
    required this.first,
    required this.second,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: first),
        const SizedBox(width: 22),
        Expanded(child: second),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;

  const _SectionTitle({
    required this.icon,
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.primary, size: 26),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _AppTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final bool obscureText;
  final String? errorText;
  final bool readOnly;

  const _AppTextField({
    required this.controller,
    required this.label,
    required this.hint,
    this.obscureText = false,
    this.errorText,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          textAlign: TextAlign.right,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscureText,
          readOnly: readOnly,
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.right,
          decoration: InputDecoration(
            hintText: hint,
            errorText: errorText,
            hintTextDirection: TextDirection.rtl,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }
}

class _GeneratedTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final VoidCallback onGenerate;
  final String? errorText;

  const _GeneratedTextField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.onGenerate,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          textAlign: TextAlign.right,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.left,
          decoration: InputDecoration(
            hintText: hint,
            errorText: errorText,
            suffixIcon: IconButton(
              tooltip: 'توليد جديد',
              onPressed: onGenerate,
              icon: const Icon(Icons.refresh_rounded),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }
}

class _AppDropdown extends StatelessWidget {
  final String label;
  final String hint;
  final int? value;
  final Map<int, String> items;
  final ValueChanged<int?>? onChanged;
  final String? errorText;

  const _AppDropdown({
    required this.label,
    required this.hint,
    required this.value,
    required this.items,
    required this.onChanged,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          textAlign: TextAlign.right,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<int>(
          value: items.containsKey(value) ? value : null,
          isExpanded: true,
          decoration: InputDecoration(
            errorText: errorText,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          hint: Text(
            hint,
            textAlign: TextAlign.right,
          ),
          items: items.entries
              .map(
                (e) => DropdownMenuItem<int>(
                  value: e.key,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      e.value,
                      textAlign: TextAlign.right,
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}
