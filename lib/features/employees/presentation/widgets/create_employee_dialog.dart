import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/active_org/active_organization_cubit.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/enums/form_status.dart';
import '../../../../core/enums/request_status.dart';
import '../../../../core/services/key_generation_service.dart';
import '../../../../core/services/key_storage_service.dart';
import '../../../../core/services/whatsapp_service.dart';
import '../../../../core/security/usb_device_info.dart';
import '../../../key_management/domain/usecases/get_connected_usb_devices.dart';
import '../../../key_management/domain/usecases/create_usb_bound_key.dart';
import '../../../key_management/presentation/widgets/usb_device_picker_dialog.dart';
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
  PendingUsbBoundKey? _pendingKey;

  // The organization is the user's active one, chosen once after login.
  late final int? _organizationId =
      getIt<ActiveOrganizationCubit>().activeOrgId;
  int? _departmentId;
  int? _roleId;
  bool _touched = false;

  @override
  void initState() {
    super.initState();
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

  @override
  void dispose() {
    unawaited(getIt<KeyStorageService>().discardStagedKey(_pendingKey));
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

  Future<bool> _confirmReplaceExistingKey() async {
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('يوجد مفتاح سابق'),
            content: const Text(
              'يوجد مفتاح سابق لهذا الموظف على الفلاشة. هل تريد استبداله؟',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('إلغاء'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('استبدال المفتاح'),
              ),
            ],
          ),
        ) ??
        false;
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

  String? _nationalIdError() {
    if (!_touched) return null;
    final value = _nationalId.text.trim();
    if (value.isEmpty) return 'هذا الحقل مطلوب';
    if (!RegExp(r'^\d{11}$').hasMatch(value)) {
      return 'يجب أن يتكون الرقم الوطني من 11 رقماً';
    }
    return null;
  }

  String? _phoneError() {
    if (!_touched) return null;
    final value = _phone.text.trim();
    if (value.isEmpty) return 'هذا الحقل مطلوب';
    if (!RegExp(r'^\d{10}$').hasMatch(value)) {
      return 'يجب أن يتكون رقم الهاتف من 10 أرقام';
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
          'كلمة المرور:\n$password\n\n'
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
        !RegExp(r'^\d{11}$').hasMatch(_nationalId.text.trim()) ||
        _phone.text.trim().isEmpty ||
        !RegExp(r'^\d{10}$').hasMatch(_phone.text.trim()) ||
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

      final selectedDevice = await UsbDevicePickerDialog.show(
        context,
        getIt<GetConnectedUsbDevices>(),
      );
      if (selectedDevice == null) {
        _showDialogMessage('لم يتم اختيار مجلد لحفظ المفاتيح');
        return;
      }

      final storage = getIt<KeyStorageService>();
      if (await storage.hasExistingKey(
            selectedDevice: selectedDevice,
            username: _userName.text.trim(),
          ) &&
          !await _confirmReplaceExistingKey()) {
        return;
      }

      debugPrint('GENERATING KEYS...');
      final keys = await getIt<KeyGenerationService>().generateKeys();

      _pendingKey = await getIt<CreateUsbBoundKey>()(
        selectedDevice: selectedDevice,
        username: _userName.text.trim(),
        privateKeyBytes: keys.privateKeyBytes,
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
      await getIt<KeyStorageService>().discardStagedKey(_pendingKey);
      _pendingKey = null;
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
      listener: (context, state) async {
        if (state.formStatus == FormStatus.success) {
          final dialogNavigator = Navigator.of(context);
          final rootNavigator = Navigator.of(context, rootNavigator: true);
          final pendingKey = _pendingKey;
          if (pendingKey == null) {
            _showDialogMessage('تعذّر العثور على المفتاح المرحلي لإتمام الحفظ');
            return;
          }
          try {
            await getIt<KeyStorageService>().commitStagedKey(
              pendingKey: pendingKey,
              pin: _lastGeneratedPin ?? '',
            );
            _pendingKey = null;
          } catch (error) {
            _showDialogMessage(error.toString());
            return;
          }
          if (!context.mounted) return;
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
          if (!dialogNavigator.mounted || !rootNavigator.mounted) return;
          dialogNavigator.pop();

          // Show the credentials dialog on the root navigator's context, which
          // is still mounted after the create dialog is gone.
          _showCredentialsDialog(
            rootContext: rootNavigator.context,
            message: successMessage,
            userName: userName,
            phone: phone,
            password: password,
            pin: pin,
          );
        }

        if (state.formStatus == FormStatus.failure) {
          await getIt<KeyStorageService>().discardStagedKey(_pendingKey);
          _pendingKey = null;
          if (!context.mounted) return;
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
            borderRadius: BorderRadius.circular(20),
          ),
          clipBehavior: Clip.antiAlias,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 920,
              maxHeight: 820,
            ),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(28, 14, 28, 14),
                    color: Colors.white,
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.person_add_alt_1_rounded,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'إنشاء موظف جديد',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'أدخل بيانات الموظف واربط حسابه بمفتاح USB آمن',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
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
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: AppColors.border.withValues(alpha: 0.65),
                  ),
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
                              hint: 'أدخل رقمك الوطني',
                              errorText: _nationalIdError(),
                              keyboardType: TextInputType.number,
                              maxLength: 11,
                              digitsOnly: true,
                              customCounterMax: 11,
                              onChanged: (_) {
                                if (_touched) setState(() {});
                              },
                            ),
                            second: _AppTextField(
                              controller: _phone,
                              label: 'رقم الهاتف *',
                              hint: 'أدخل رقم هاتفك',
                              errorText: _phoneError(),
                              keyboardType: TextInputType.phone,
                              maxLength: 10,
                              digitsOnly: true,
                              customCounterMax: 10,
                              onChanged: (_) {
                                if (_touched) setState(() {});
                              },
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
                            first: _AppTextField(
                              controller: _password,
                              label: 'كلمة المرور *',
                              hint: 'أدخل كلمة مرور آمنة',
                              errorText: _required(_password),
                              obscureText: true,
                              onChanged: (_) {
                                if (_touched) setState(() {});
                              },
                            ),
                            second: _AppTextField(
                              controller: _pin,
                              label: 'رمز PIN *',
                              hint: 'أدخل 6 أرقام',
                              errorText: _pinError(),
                              obscureText: true,
                              keyboardType: TextInputType.number,
                              maxLength: 6,
                              digitsOnly: true,
                              customCounterMax: 6,
                              onChanged: (_) {
                                if (_touched) setState(() {});
                              },
                            ),
                          ),
                          const SizedBox(height: 22),
                          _SecurityUsbCard(
                            getConnectedUsbDevices:
                                getIt<GetConnectedUsbDevices>(),
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
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: AppColors.border.withValues(alpha: 0.65),
                  ),
                  Container(
                    padding: const EdgeInsets.fromLTRB(28, 14, 28, 16),
                    color: Colors.white,
                    child: Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 50,
                            child: FilledButton.icon(
                              onPressed:
                                  submitting ? null : () => _submit(context),
                              icon: submitting
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.person_add_rounded),
                              label: Text(
                                submitting
                                    ? 'جارٍ إنشاء الحساب...'
                                    : 'إنشاء حساب الموظف',
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 18),
                        Expanded(
                          child: SizedBox(
                            height: 50,
                            child: OutlinedButton.icon(
                              onPressed: submitting
                                  ? null
                                  : () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.primary,
                                side: const BorderSide(color: AppColors.border),
                              ),
                              icon: const Icon(Icons.close_rounded),
                              label: const Text('إلغاء'),
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
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 620) {
          return Column(
            children: [
              first,
              const SizedBox(height: 18),
              second,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: first),
            const SizedBox(width: 22),
            Expanded(child: second),
          ],
        );
      },
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
  final TextInputType? keyboardType;
  final int? maxLength;
  final bool digitsOnly;
  final ValueChanged<String>? onChanged;
  final int? customCounterMax;

  const _AppTextField({
    required this.controller,
    required this.label,
    required this.hint,
    this.obscureText = false,
    this.errorText,
    this.keyboardType,
    this.maxLength,
    this.digitsOnly = false,
    this.onChanged,
    this.customCounterMax,
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
          keyboardType: keyboardType,
          maxLength: maxLength,
          inputFormatters: [
            if (digitsOnly) FilteringTextInputFormatter.digitsOnly,
            if (maxLength != null) LengthLimitingTextInputFormatter(maxLength),
          ],
          onChanged: onChanged,
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.right,
          decoration: InputDecoration(
            hintText: hint,
            errorText: errorText,
            hintTextDirection: TextDirection.rtl,
            counterText: '',
            constraints: const BoxConstraints(minHeight: 52),
            filled: true,
            fillColor: AppColors.surface,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 15,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 1.6,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.error),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.error,
                width: 1.6,
              ),
            ),
          ),
        ),
        if (customCounterMax != null) ...[
          const SizedBox(height: 3),
          Align(
            alignment: Alignment.centerRight,
            child: ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller,
              builder: (context, value, _) => Directionality(
                textDirection: TextDirection.rtl,
                child: Text(
                  '${value.text.length}/$customCounterMax',
                  textAlign: TextAlign.right,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.1,
                      ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _SecurityUsbCard extends StatefulWidget {
  final GetConnectedUsbDevices getConnectedUsbDevices;

  const _SecurityUsbCard({required this.getConnectedUsbDevices});

  @override
  State<_SecurityUsbCard> createState() => _SecurityUsbCardState();
}

class _SecurityUsbCardState extends State<_SecurityUsbCard> {
  late Future<List<UsbDeviceInfo>> _devices;

  @override
  void initState() {
    super.initState();
    _devices = widget.getConnectedUsbDevices();
  }

  void _refresh() {
    setState(() => _devices = widget.getConnectedUsbDevices());
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<UsbDeviceInfo>>(
      future: _devices,
      builder: (context, snapshot) {
        final loading = snapshot.connectionState == ConnectionState.waiting;
        final supportedDevices =
            snapshot.data?.where((device) => device.isSupported).toList() ??
                const <UsbDeviceInfo>[];
        final detected = supportedDevices.isNotEmpty;
        final hasError = snapshot.hasError;

        final Color accent;
        final IconData icon;
        final String status;
        final String message;
        if (loading) {
          accent = const Color(0xffB7791F);
          icon = Icons.sync_rounded;
          status = 'جارٍ فحص وحدات USB...';
          message = 'يرجى الانتظار أثناء قراءة وحدات الأمان المتصلة بالجهاز';
        } else if (detected) {
          accent = AppColors.primary;
          icon = Icons.usb_rounded;
          status = 'تم اكتشاف مفتاح USB آمن';
          message = supportedDevices.length == 1
              ? 'وحدة USB صالحة متصلة. سيتم اختيارها والتحقق منها عند إنشاء الحساب.'
              : 'تم العثور على ${supportedDevices.length} وحدات صالحة. ستختار الوحدة عند إنشاء الحساب.';
        } else if (hasError) {
          accent = AppColors.error;
          icon = Icons.usb_off_rounded;
          status = 'تعذّر فحص مفتاح USB';
          message = 'أعد توصيل وحدة USB ثم اضغط على إعادة الفحص';
        } else {
          accent = const Color(0xffB7791F);
          icon = Icons.usb_off_rounded;
          status = 'لم يتم اكتشاف مفتاح USB';
          message =
              'يرجى توصيل فلاشة الأمان (USB Token) بالجهاز لقراءة المفتاح';
        }

        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: accent.withValues(alpha: 0.28)),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: loading
                    ? Padding(
                        padding: const EdgeInsets.all(14),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: accent,
                        ),
                      )
                    : Icon(icon, color: accent, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 10,
                      runSpacing: 5,
                      children: [
                        Text(
                          'مفتاح الأمان USB',
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w800,
                                  ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            status,
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: accent,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      message,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.5,
                          ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: loading ? null : _refresh,
                tooltip: 'إعادة فحص وحدات USB',
                icon: const Icon(Icons.refresh_rounded),
                color: AppColors.primary,
              ),
            ],
          ),
        );
      },
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
          initialValue: items.containsKey(value) ? value : null,
          isExpanded: true,
          decoration: InputDecoration(
            errorText: errorText,
            filled: true,
            fillColor: AppColors.surface,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 1.6,
              ),
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
