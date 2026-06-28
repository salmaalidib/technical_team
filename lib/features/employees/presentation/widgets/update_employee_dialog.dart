import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/enums/form_status.dart';
import '../../../../core/enums/request_status.dart';
import '../../../../core/services/key_generation_service.dart';
import '../../../../core/services/key_storage_service.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../domain/entities/employee.dart';
import '../bloc/employees_bloc.dart';
import '../bloc/employees_event.dart';
import '../bloc/employees_state.dart';

/// نموذج تعديل موظف بكل الحقول. يبني حمولة جزئية (الحقول المتغيّرة فقط)
/// ويحترم قواعد الـ backend الترابطية:
///   * تغيير كلمة المرور → يرسل password + confirm_password.
///   * تغيير PIN → يرسل pin + confirm_pin.
///   * تغيير الدور → يرسل organization_id + department_id + role_id معاً.
///   * المفتاح العام اختياري؛ إن أُرسل private_key يتطلب public_key + pin.
class UpdateEmployeeDialog extends StatefulWidget {
  final Employee employee;

  const UpdateEmployeeDialog({super.key, required this.employee});

  @override
  State<UpdateEmployeeDialog> createState() => _UpdateEmployeeDialogState();
}

class _UpdateEmployeeDialogState extends State<UpdateEmployeeDialog> {
  late final TextEditingController _firstName;
  late final TextEditingController _fatherName;
  late final TextEditingController _motherName;
  late final TextEditingController _lastName;
  late final TextEditingController _nationalId;
  late final TextEditingController _phone;
  late final TextEditingController _userName;
  late final TextEditingController _email;

  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  final _pin = TextEditingController();
  final _confirmPin = TextEditingController();

  // المفتاح العام المُولَّد حديثاً (إن طلب المستخدم توليد مفتاح جديد). يبقى
  // null ما لم يُولَّد، فلا يُرسل أي تغيير للمفاتيح.
  String? _generatedPublicKey;
  bool _generatingKey = false;

  // قسم الأمان مخفيٌّ افتراضياً مثل قسم إعادة التعيين. عند تفعيله تُولَّد كلمة
  // مرور و PIN جديدان تلقائياً (كما في الإنشاء).
  bool _changeSecurity = false;

  late bool _isActive;

  // التعيين الإداري — يُملأ فقط إن أراد المستخدم تغييره.
  int? _departmentId;
  int? _roleId;
  bool _reassign = false;

  bool _touched = false;

  Employee get _e => widget.employee;

  @override
  void initState() {
    super.initState();
    _firstName = TextEditingController(text: _e.firstName);
    _fatherName = TextEditingController(text: _e.fatherName);
    _motherName = TextEditingController(text: _e.motherName);
    _lastName = TextEditingController(text: _e.lastName);
    _nationalId = TextEditingController(text: _e.nationalId);
    _phone = TextEditingController(text: _e.phoneNumber);
    _userName = TextEditingController(text: _e.userName);
    _email = TextEditingController(text: _e.email);
    _isActive = _e.isActive;
    _departmentId = _e.department?.id;
    _roleId = _e.role?.id;
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
    _confirmPassword.dispose();
    _pin.dispose();
    _confirmPin.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('تنبيه'),
        content: Text(message, textDirection: TextDirection.rtl),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('حسناً'),
          ),
        ],
      ),
    );
  }

  /// يبني الحمولة الجزئية: فقط الحقول التي تغيّرت فعلاً عن قيمة الموظف الأصلية.
  Map<String, dynamic>? _buildPayload() {
    final data = <String, dynamic>{};

    void putIfChanged(String key, String current, String original) {
      final trimmed = current.trim();
      if (trimmed.isNotEmpty && trimmed != original.trim()) {
        data[key] = trimmed;
      }
    }

    putIfChanged('first_name', _firstName.text, _e.firstName);
    putIfChanged('last_name', _lastName.text, _e.lastName);
    putIfChanged('father_name', _fatherName.text, _e.fatherName);
    putIfChanged('mother_name', _motherName.text, _e.motherName);
    putIfChanged('national_id', _nationalId.text, _e.nationalId);
    putIfChanged('userName', _userName.text, _e.userName);
    putIfChanged('email', _email.text, _e.email);
    putIfChanged('phone_number', _phone.text, _e.phoneNumber);

    if (_isActive != _e.isActive) {
      data['is_active'] = _isActive;
    }

    // كلمة المرور
    final password = _password.text.trim();
    if (password.isNotEmpty) {
      if (password != _confirmPassword.text.trim()) {
        _showMessage('كلمة المرور وتأكيدها غير متطابقتين');
        return null;
      }
      data['password'] = password;
      data['confirm_password'] = password;
    }

    // PIN
    final pin = _pin.text.trim();
    if (pin.isNotEmpty) {
      if (!RegExp(r'^\d{6}$').hasMatch(pin)) {
        _showMessage('رمز PIN يجب أن يتكون من 6 أرقام');
        return null;
      }
      if (pin != _confirmPin.text.trim()) {
        _showMessage('رمز PIN وتأكيده غير متطابقين');
        return null;
      }
      data['pin'] = pin;
      data['confirm_pin'] = pin;

      // أي تغيير للـ PIN يستوجب مفتاحاً جديداً: المفتاح الخاص القديم مشفّر
      // بالـ PIN القديم، فلا يُفكّ بالـ PIN الجديد. نمنع الحفظ ما لم يُولَّد
      // مفتاح جديد (يُحفظ مشفّراً بالـ PIN الجديد على الفلاشة).
      if (_generatedPublicKey == null) {
        _showMessage('غيّرت رمز PIN، لذا يجب توليد مفتاح جديد أولاً '
            '(المفتاح الخاص يُحفظ مشفّراً بالـ PIN الجديد).');
        return null;
      }
    }

    // المفتاح العام — يُرسل فقط إن وُلّد مفتاح جديد عبر زر التوليد.
    final newKey = _generatedPublicKey;
    if (newKey != null && newKey.isNotEmpty) {
      data['public_key'] = newKey;
    }

    // إعادة التعيين — الثلاثي معاً
    if (_reassign) {
      if (_departmentId == null || _roleId == null) {
        _showMessage('لإعادة التعيين اختر القسم والدور');
        return null;
      }
      data['organization_id'] = _e.organization?.id;
      data['department_id'] = _departmentId;
      data['role_id'] = _roleId;

      if (data['organization_id'] == null) {
        _showMessage('لا يمكن إعادة التعيين: مؤسسة الموظف غير معروفة');
        return null;
      }
    }

    return data;
  }

  /// يفعّل/يلغي قسم الأمان. عند التفعيل يُولّد كلمة مرور و PIN جديدين تلقائياً
  /// (مثل الإنشاء) ليكونا جاهزين لتشفير المفتاح الخاص عند توليده. عند الإلغاء
  /// تُمسح كل قيم الأمان فلا يُرسل أي تغيير.
  void _toggleSecurity(bool enabled) {
    setState(() {
      _changeSecurity = enabled;
      if (enabled) {
        final storage = getIt<KeyStorageService>();
        final pin = storage.generatePin();
        final password = storage.generatePassword();
        _pin.text = pin;
        _confirmPin.text = pin;
        _password.text = password;
        _confirmPassword.text = password;
      } else {
        _pin.clear();
        _confirmPin.clear();
        _password.clear();
        _confirmPassword.clear();
        _generatedPublicKey = null;
      }
    });
  }

  /// يُبطل المفتاح المُولَّد عند أي تعديل لاحق للـ PIN، لأن المفتاح حُفظ مشفّراً
  /// بالـ PIN السابق ولم يعد مطابقاً. هكذا يُجبَر المستخدم على إعادة التوليد.
  void _onPinChanged(String _) {
    if (_generatedPublicKey != null) {
      setState(() => _generatedPublicKey = null);
    }
  }

  /// يولّد زوج مفاتيح جديداً, يحفظ المفتاح الخاص (مشفّراً بالـ PIN) على مجلد
  /// خارجي، ويحتفظ بالمفتاح العام لإرساله مع الحفظ. يتطلب إدخال PIN جديد
  /// (6 أرقام) لتشفير المفتاح الخاص، تماماً كما في شاشة الإنشاء.
  Future<void> _generateNewKey() async {
    final pin = _pin.text.trim();
    if (!RegExp(r'^\d{6}$').hasMatch(pin)) {
      _showMessage(
        'لتوليد مفتاح جديد أدخل رمز PIN جديداً (6 أرقام) في قسم الأمان أولاً، '
        'فهو يُستخدم لتشفير المفتاح الخاص.',
      );
      return;
    }
    if (pin != _confirmPin.text.trim()) {
      _showMessage('رمز PIN وتأكيده غير متطابقين');
      return;
    }

    setState(() => _generatingKey = true);
    try {
      final keys = await getIt<KeyGenerationService>().generateKeys();

      final directoryPath =
          await getIt<KeyStorageService>().pickExternalDirectory();
      if (directoryPath == null) {
        _showMessage('لم يتم اختيار مجلد لحفظ المفتاح الخاص');
        return;
      }

      await getIt<KeyStorageService>().saveEmployeeKeys(
        directoryPath: directoryPath,
        userName: _e.userName,
        privateKey: keys.privateKey,
        publicKey: keys.publicKey,
        pin: pin,
      );

      if (!mounted) return;
      setState(() => _generatedPublicKey = keys.publicKey);
      _showMessage('تم توليد مفتاح جديد وحفظ المفتاح الخاص. سيُحدَّث المفتاح '
          'العام عند الحفظ.');
    } catch (e) {
      if (!mounted) return;
      _showMessage(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _generatingKey = false);
    }
  }

  void _submit(BuildContext context) {
    setState(() => _touched = true);

    final payload = _buildPayload();
    if (payload == null) return;

    if (payload.isEmpty) {
      _showMessage('لم تقم بأي تعديل');
      return;
    }

    context.read<EmployeesBloc>().add(
          UpdateEmployeeRequested(id: _e.id, data: payload),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<EmployeesBloc, EmployeesState>(
      listenWhen: (p, c) => p.updateStatus != c.updateStatus,
      listener: (context, state) {
        if (state.updateStatus == FormStatus.success) {
          Navigator.pop(context);
        } else if (state.updateStatus == FormStatus.failure) {
          _showMessage(state.updateError ?? 'تعذّر تعديل بيانات الموظف');
        }
      },
      builder: (context, state) {
        final submitting = state.updateStatus == FormStatus.submitting &&
            state.updatingId == _e.id;

        return Dialog(
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          backgroundColor: AppColors.surface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 920, maxHeight: 780),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Column(
                children: [
                  _Header(name: _e.fullName),
                  const Divider(height: 1, color: AppColors.border),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const _SectionTitle(
                            icon: Icons.person_outline_rounded,
                            title: 'البيانات الشخصية',
                          ),
                          const SizedBox(height: 22),
                          _Row(
                            first: _Field(
                                controller: _firstName, label: 'الاسم الأول'),
                            second: _Field(
                                controller: _fatherName, label: 'اسم الأب'),
                          ),
                          const SizedBox(height: 16),
                          _Row(
                            first: _Field(
                                controller: _motherName, label: 'اسم الأم'),
                            second: _Field(
                                controller: _lastName, label: 'الاسم الأخير'),
                          ),
                          const SizedBox(height: 16),
                          _Row(
                            first: _Field(
                                controller: _nationalId,
                                label: 'الرقم الوطني'),
                            second: _Field(
                                controller: _phone, label: 'رقم الهاتف'),
                          ),
                          const SizedBox(height: 16),
                          _Row(
                            first: _Field(
                                controller: _userName, label: 'اسم المستخدم'),
                            second: _Field(
                                controller: _email, label: 'البريد الإلكتروني'),
                          ),
                          const SizedBox(height: 22),
                          _ActiveSwitch(
                            value: _isActive,
                            onChanged: submitting
                                ? null
                                : (v) => setState(() => _isActive = v),
                          ),
                          const SizedBox(height: 22),
                          const Divider(height: 1, color: AppColors.border),
                          const SizedBox(height: 22),

                          // ===== إعادة التعيين =====
                          _ReassignToggle(
                            value: _reassign,
                            onChanged: submitting
                                ? null
                                : (v) {
                                    setState(() => _reassign = v);
                                    if (!v) return;
                                    final orgId = _e.organization?.id;
                                    final bloc = context.read<EmployeesBloc>();
                                    if (orgId != null) {
                                      bloc.add(LoadEmployeeDepartments(orgId));
                                    }
                                    // حمّل أدوار القسم الحالي أيضاً حتى يظهر
                                    // الدور المُعيَّن مسبقاً في قائمة الأدوار،
                                    // لا القسم فقط.
                                    final deptId = _e.department?.id;
                                    if (deptId != null) {
                                      bloc.add(LoadEmployeeRoles(deptId));
                                    }
                                  },
                          ),
                          if (_reassign) ...[
                            const SizedBox(height: 18),
                            _Dropdown(
                              label: 'القسم / الدائرة',
                              hint: state.departmentsStatus ==
                                      RequestStatus.loading
                                  ? 'جار تحميل الأقسام...'
                                  : 'اختر القسم...',
                              value: _departmentId,
                              items: {
                                for (final d in state.departments) d.id: d.name,
                              },
                              onChanged: submitting
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
                            const SizedBox(height: 16),
                            _Dropdown(
                              label: 'الدور',
                              hint: state.rolesStatus == RequestStatus.loading
                                  ? 'جار تحميل الأدوار...'
                                  : 'اختر الدور...',
                              value: _roleId,
                              items: {
                                for (final r in state.roles) r.id: r.name,
                              },
                              onChanged: submitting
                                  ? null
                                  : (v) => setState(() => _roleId = v),
                            ),
                          ],

                          const SizedBox(height: 22),
                          const Divider(height: 1, color: AppColors.border),
                          const SizedBox(height: 22),

                          // ===== الأمان (مخفي افتراضياً) =====
                          _SecurityToggle(
                            value: _changeSecurity,
                            onChanged:
                                submitting ? null : (v) => _toggleSecurity(v),
                          ),
                          if (_changeSecurity) ...[
                            const SizedBox(height: 14),
                            const _SecurityNotice(),
                            const SizedBox(height: 18),
                            _Row(
                              first: _Field(
                                  controller: _password,
                                  label: 'كلمة المرور الجديدة',
                                  hint: 'مُولّدة تلقائياً'),
                              second: _Field(
                                  controller: _confirmPassword,
                                  label: 'تأكيد كلمة المرور'),
                            ),
                            const SizedBox(height: 16),
                            _Row(
                              first: _Field(
                                  controller: _pin,
                                  label: 'رمز PIN الجديد',
                                  hint: 'مُولّد تلقائياً',
                                  onChanged: _onPinChanged),
                              second: _Field(
                                  controller: _confirmPin,
                                  label: 'تأكيد PIN',
                                  onChanged: _onPinChanged),
                            ),
                            const SizedBox(height: 16),
                            _PublicKeySection(
                              generated: _generatedPublicKey != null,
                              generating: _generatingKey,
                              onGenerate:
                                  submitting ? null : () => _generateNewKey(),
                            ),
                          ],
                          if (_touched) const SizedBox(height: 4),
                        ],
                      ),
                    ),
                  ),
                  const Divider(height: 1, color: AppColors.border),
                  _Footer(
                    submitting: submitting,
                    onSubmit: () => _submit(context),
                    onCancel: () => Navigator.pop(context),
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

// ======================= عناصر داخلية =======================

class _Header extends StatelessWidget {
  final String name;
  const _Header({required this.name});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 26, 28, 22),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'تعديل الموظف — $name',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                  ),
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
    );
  }
}

class _Footer extends StatelessWidget {
  final bool submitting;
  final VoidCallback onSubmit;
  final VoidCallback onCancel;

  const _Footer({
    required this.submitting,
    required this.onSubmit,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 18, 28, 22),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 54,
              child: ElevatedButton(
                onPressed: submitting ? null : onSubmit,
                child: submitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('حفظ التعديلات'),
              ),
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: SizedBox(
              height: 54,
              child: ElevatedButton(
                onPressed: submitting ? null : onCancel,
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
    );
  }
}

class _Row extends StatelessWidget {
  final Widget first;
  final Widget second;
  const _Row({required this.first, required this.second});

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
  const _SectionTitle({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ),
      ],
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final ValueChanged<String>? onChanged;

  const _Field({
    required this.controller,
    required this.label,
    this.hint,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          onChanged: onChanged,
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.right,
          decoration: InputDecoration(
            hintText: hint,
            hintTextDirection: TextDirection.rtl,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
    );
  }
}

class _Dropdown extends StatelessWidget {
  final String label;
  final String hint;
  final int? value;
  final Map<int, String> items;
  final ValueChanged<int?>? onChanged;

  const _Dropdown({
    required this.label,
    required this.hint,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
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
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          hint: Text(hint, textAlign: TextAlign.right),
          items: items.entries
              .map(
                (e) => DropdownMenuItem<int>(
                  value: e.key,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(e.value, textAlign: TextAlign.right),
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

/// مفتاح إظهار قسم الأمان (مخفي افتراضياً مثل إعادة التعيين).
class _SecurityToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;

  const _SecurityToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.lock_outline_rounded,
            color: AppColors.primary, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'تغيير الأمان (كلمة المرور / PIN / المفتاح)',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ),
        Switch(value: value, onChanged: onChanged),
      ],
    );
  }
}

/// رسالة توضّح ما سيحدث عند تفعيل قسم الأمان.
class _SecurityNotice extends StatelessWidget {
  const _SecurityNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.lightPrimary,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded,
              color: AppColors.primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'عند تفعيل هذا القسم تم توليد كلمة مرور ورمز PIN جديدين تلقائياً. '
              'بما أن الـ PIN تغيّر، يجب توليد مفتاح جديد قبل الحفظ — سيُحفظ '
              'المفتاح الخاص مشفّراً بالـ PIN الجديد على مجلد خارجي (فلاشة).',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textPrimary,
                    height: 1.6,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

/// قسم المفتاح العام: عبارة توضّح أنه سيتولّد public key جديد, وزر للتوليد.
/// التوليد يحفظ المفتاح الخاص خارجياً ويُرسل العام عند الحفظ.
class _PublicKeySection extends StatelessWidget {
  final bool generated;
  final bool generating;
  final VoidCallback? onGenerate;

  const _PublicKeySection({
    required this.generated,
    required this.generating,
    required this.onGenerate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.inputBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.vpn_key_outlined,
                  color: AppColors.primary, size: 22),
              const SizedBox(width: 10),
              Text(
                'المفتاح العام (Public Key)',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'عند توليد مفتاح جديد سيتم إنشاء مفتاح عام جديد للموظف، وحفظ المفتاح '
            'الخاص (مشفّراً برمز PIN الجديد) على مجلد خارجي. اتركه دون توليد '
            'لإبقاء المفتاح الحالي.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.6,
                ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 14,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                height: 46,
                child: ElevatedButton.icon(
                  onPressed: generating ? null : onGenerate,
                  icon: generating
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.refresh_rounded, size: 20),
                  label: Text(generated
                      ? 'إعادة توليد مفتاح جديد'
                      : 'توليد مفتاح جديد'),
                ),
              ),
              if (generated)
                const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_outline,
                        color: AppColors.primary, size: 20),
                    SizedBox(width: 6),
                    Text(
                      'تم توليد مفتاح جديد',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActiveSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;

  const _ActiveSwitch({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          'حالة التفعيل',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(width: 14),
        Switch(value: value, onChanged: onChanged),
        const SizedBox(width: 6),
        Text(
          value ? 'نشط' : 'غير نشط',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: value ? AppColors.primary : AppColors.error,
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
    );
  }
}

class _ReassignToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;

  const _ReassignToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.account_tree_outlined,
            color: AppColors.primary, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'إعادة تعيين القسم / الدور',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ),
        Switch(value: value, onChanged: onChanged),
      ],
    );
  }
}
