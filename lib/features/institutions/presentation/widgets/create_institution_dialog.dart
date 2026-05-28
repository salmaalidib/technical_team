import 'package:flutter/material.dart';

import '../../../../shared/theme/app_colors.dart';

class CreateInstitutionDialog extends StatelessWidget {
  const CreateInstitutionDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Dialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        child: SizedBox(
          width: 620,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _DialogHeader(),
              const Divider(height: 1, color: AppColors.border),
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 28, 28, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: const [
                    _DialogSubtitle(),
                    SizedBox(height: 30),
                    _FieldLabel('اسم المؤسسة *'),
                    SizedBox(height: 8),
                    _TextInput(hint: 'أدخل اسم المؤسسة...'),
                    SizedBox(height: 22),
                    _FieldLabel('المؤسسة الأم (اختياري)'),
                    SizedBox(height: 8),
                    _DropdownInput(
                      hint: 'اختر الموقع...',
                      items: [
                        'ريف دمشق',
                      ],
                    ),
                    SizedBox(height: 22),
                    _FieldLabel('الموقع *'),
                    SizedBox(height: 8),
                    _DropdownInput(
                      hint: 'اختر الموقع...',
                      items: [
                        'ريف دمشق',
                      ],
                    ),
                    SizedBox(height: 28),
                    Divider(height: 1, color: AppColors.border),
                    SizedBox(height: 18),
                    _DialogActions(),
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

class _DialogHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 22),
      child: Row(
        children: [
          const Text(
            'إنشاء مؤسسة جديدة',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const Spacer(),
          InkWell(
            onTap: () => Navigator.pop(context),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.inputBackground,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.close_rounded,
                size: 24,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DialogSubtitle extends StatelessWidget {
  const _DialogSubtitle();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.apartment_outlined,
          color: AppColors.primary,
          size: 25,
        ),
        SizedBox(width: 10),
        Text(
          'قم بإدخال بيانات المؤسسة الجديدة',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 15,
          ),
        ),
      ],
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
  final String hint;

  const _TextInput({required this.hint});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: TextField(
        textAlign: TextAlign.right,
        textDirection: TextDirection.rtl,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 15,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14),
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
      ),
    );
  }
}

class _DropdownInput extends StatefulWidget {
  final List<String> items;
  final String hint;

  const _DropdownInput({
    required this.items,
    required this.hint,
  });

  @override
  State<_DropdownInput> createState() => _DropdownInputState();
}

class _DropdownInputState extends State<_DropdownInput> {
  String? selectedValue;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: DropdownButtonFormField<String>(
        value: selectedValue,
        isExpanded: true,
        icon: const Icon(
          Icons.keyboard_arrow_down_rounded,
          color: AppColors.textPrimary,
        ),
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(
              color: AppColors.border,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(
              color: AppColors.border,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(
              color: AppColors.primary,
            ),
          ),
        ),
        hint: Text(
          widget.hint,
          textAlign: TextAlign.right,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 15,
          ),
        ),
        items: widget.items.map((item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                item,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontSize: 15,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            selectedValue = value;
          });
        },
      ),
    );
  }
}

class _DialogActions extends StatelessWidget {
  const _DialogActions();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'حفظ المؤسسة',
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
            height: 48,
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                backgroundColor: AppColors.inputBackground,
                foregroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'إلغاء',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
