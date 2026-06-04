import 'package:flutter/material.dart';

import '../../../../shared/theme/app_colors.dart';

class CreateEmployeeDialog extends StatelessWidget {
  const CreateEmployeeDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
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
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
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
                      _SectionTitle(
                        icon: Icons.person_outline_rounded,
                        title: 'بيانات الموظف',
                        subtitle:
                            'قم بإدخال بيانات الموظف الأساسية وحساب الدخول',
                      ),
                      const SizedBox(height: 26),
                      const _TwoFieldsRow(
                        first: _AppTextField(
                          label: 'الاسم الأول *',
                          hint: 'مثال: أحمد',
                        ),
                        second: _AppTextField(
                          label: 'اسم الأب *',
                          hint: 'مثال: محمود',
                        ),
                      ),
                      const SizedBox(height: 18),
                      const _TwoFieldsRow(
                        first: _AppTextField(
                          label: 'اسم الأم *',
                          hint: 'مثال: فاطمة',
                        ),
                        second: _AppTextField(
                          label: 'الاسم الأخير *',
                          hint: 'مثال: الأحمد',
                        ),
                      ),
                      const SizedBox(height: 18),
                      const _TwoFieldsRow(
                        first: _AppTextField(
                          label: 'الرقم الوطني *',
                          hint: 'مثال: 01010101010',
                        ),
                        second: _AppTextField(
                          label: 'رقم الهاتف *',
                          hint: '09xxxxxxxx',
                        ),
                      ),
                      const SizedBox(height: 18),
                      const _TwoFieldsRow(
                        first: _AppTextField(
                          label: 'اسم المستخدم *',
                          hint: 'مثال: ahmad.mahmoud',
                        ),
                        second: _AppTextField(
                          label: 'البريد الإلكتروني *',
                          hint: 'example@edu.sy',
                        ),
                      ),
                      const SizedBox(height: 18),
                      const _AppTextField(
                        label: 'كلمة المرور *',
                        hint: '••••••••',
                        obscureText: true,
                      ),
                      const SizedBox(height: 26),
                      const Divider(height: 1, color: AppColors.border),
                      const SizedBox(height: 24),
                      _SectionTitle(
                        icon: Icons.account_tree_outlined,
                        title: 'التعيين الإداري',
                      ),
                      const SizedBox(height: 20),
                      const _AppDropdown(
                        label: 'المؤسسة *',
                        hint: 'اختر المؤسسة...',
                      ),
                      const SizedBox(height: 18),
                      const _AppDropdown(
                        label: 'القسم / الدائرة *',
                        hint: 'اختر القسم...',
                      ),
                      const SizedBox(height: 18),
                      const _AppDropdown(
                        label: 'الدور *',
                        hint: 'اختر الدور...',
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
                          onPressed: () {},
                          child: const Text('إنشاء حساب الموظف'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: SizedBox(
                        height: 54,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
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
      crossAxisAlignment:
          CrossAxisAlignment.start, // يضمن محاذاة الأيقونة مع أعلى السطر الأول
      children: [
        Icon(
          icon,
          color: AppColors.primary,
          size: 26,
        ),
        const SizedBox(width: 12), // المسافة بين الأيقونة والنصوص
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment
                .start, // ستكون لليمين تلقائياً بسبب الـ RTL المحيط بالـ Dialog
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
  final String label;
  final String hint;
  final bool obscureText;

  const _AppTextField({
    required this.label,
    required this.hint,
    this.obscureText = false,
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
          obscureText: obscureText,
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.right,
          decoration: InputDecoration(
            hintText: hint,
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

class _AppDropdown extends StatelessWidget {
  final String label;
  final String hint;

  const _AppDropdown({
    required this.label,
    required this.hint,
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
        DropdownButtonFormField<String>(
          value: null,
          isExpanded: true,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          hint: Text(
            hint,
            textAlign: TextAlign.right,
          ),
          items: const [],
          onChanged: (_) {},
        ),
      ],
    );
  }
}
