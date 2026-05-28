import 'package:flutter/material.dart';

import '../../../../shared/theme/app_colors.dart';
import 'institution_action_button.dart';

class InstitutionsTable extends StatelessWidget {
  const InstitutionsTable({super.key});
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final tableWidth =
            constraints.maxWidth < 1000 ? 1000.0 : constraints.maxWidth;

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: tableWidth,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  _TableSearch(),
                  _TableHeader(),
                  _InstitutionRow(
                    number: '1',
                    name: 'مديرية التربية الرئيسية',
                    parent: '-',
                    location: 'دمشق',
                  ),
                  _InstitutionRow(
                    number: '2',
                    name: 'مديرية التربية - ريف دمشق',
                    parent: 'مديرية التربية الرئيسية',
                    location: 'ريف دمشق',
                  ),
                  _InstitutionRow(
                    number: '6',
                    name: 'مركز التدريب التربوي',
                    parent: 'مديرية التربية الرئيسية',
                    location: 'دمشق',
                  ),
                  SizedBox(height: 8),
                  _TableFooter(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TableSearch extends StatelessWidget {
  const _TableSearch();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: SizedBox(
        height: 52,
        child: TextField(
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.right,
          decoration: InputDecoration(
            hintText: 'البحث عن مؤسسة...',
            hintStyle: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 15,
            ),
            suffixIcon: const Icon(
              Icons.search,
              color: AppColors.textSecondary,
            ),
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
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  const _TableHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      color: const Color(0xffF0EFE7),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: const Row(
        textDirection: TextDirection.rtl,
        children: [
          SizedBox(width: 70, child: Text('#', style: _headerStyle)),
          Expanded(flex: 3, child: Text('اسم المؤسسة', style: _headerStyle)),
          Expanded(flex: 3, child: Text('المؤسسة الأم', style: _headerStyle)),
          Expanded(flex: 2, child: Text('الموقع', style: _headerStyle)),
          SizedBox(width: 150, child: Text('الإجراءات', style: _headerStyle)),
        ],
      ),
    );
  }
}

class _InstitutionRow extends StatelessWidget {
  final String number;
  final String name;
  final String parent;
  final String location;

  const _InstitutionRow({
    required this.number,
    required this.name,
    required this.parent,
    required this.location,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 76,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.border),
        ),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          SizedBox(width: 70, child: Text(number, style: _cellStyle)),
          Expanded(flex: 3, child: Text(name, style: _cellStyle)),
          Expanded(
            flex: 3,
            child: Text(
              parent,
              style: _cellStyle.copyWith(color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              location,
              style: _cellStyle.copyWith(color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(
            width: 150,
            child: Row(
              children: [
                InstitutionActionButton(
                  icon: Icons.visibility_outlined,
                  backgroundColor: AppColors.lightPrimary,
                  iconColor: AppColors.primary,
                ),
                SizedBox(width: 8),
                InstitutionActionButton(
                  icon: Icons.edit_outlined,
                  backgroundColor: Color(0xffF3EFE7),
                  iconColor: AppColors.secondary,
                ),
                SizedBox(width: 8),
                InstitutionActionButton(
                  icon: Icons.delete_outline,
                  backgroundColor: Color(0xffFDEAEA),
                  iconColor: Color(0xff9B2437),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TableFooter extends StatelessWidget {
  const _TableFooter();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 74,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Row(
        children: [
          const Text(
            'عرض 1 - 3 من 3',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
          const Spacer(),
          Row(
            children: [
              IconButton(
                onPressed: () {},
                splashRadius: 18,
                icon: const Icon(
                  Icons.chevron_left,
                  size: 24,
                  color: AppColors.textSecondary,
                ),
              ),
              Container(
                width: 72,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xffF0EFE7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  '1 / 1',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              IconButton(
                onPressed: () {},
                splashRadius: 18,
                icon: const Icon(
                  Icons.chevron_right,
                  size: 24,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

const TextStyle _headerStyle = TextStyle(
  color: AppColors.textPrimary,
  fontSize: 15,
  fontWeight: FontWeight.w800,
);

const TextStyle _cellStyle = TextStyle(
  color: AppColors.textPrimary,
  fontSize: 15,
  fontWeight: FontWeight.w600,
);
