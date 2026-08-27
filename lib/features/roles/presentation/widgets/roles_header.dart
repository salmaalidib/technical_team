import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/layouts/page_header_row.dart';
import '../bloc/roles_bloc.dart';
import 'create_role_dialog.dart';
import '../../../../shared/theme/app_dimens.dart';

class RolesHeader extends StatelessWidget {
  const RolesHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return PageHeaderRow(
      title: Column(
        // في RTL: start = اليمين. كانت end تدفع صفّ العنوان (الأضيق) بعيداً
        // عن اليمين بمقدار الفرق بينه وبين عرض النص الفرعي.
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            textDirection: TextDirection.rtl,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.shield_outlined,
                  color: AppColors.primary, size: 34),
              const SizedBox(width: 10),
              Text(
                'إدارة الأدوار',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'تحديد الأدوار والصلاحيات الوظيفية',
            textAlign: TextAlign.right,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ],
      ),
      action: SizedBox(
        width: 210,
        height: 54,
        child: ElevatedButton(
          onPressed: () {
            final bloc = context.read<RolesBloc>();
            showDialog(
              context: context,
              barrierColor: AppColors.scrim,
              builder: (_) => BlocProvider.value(
                value: bloc,
                child: const CreateRoleDialog(),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            textDirection: TextDirection.rtl,
            children: [
              const Icon(Icons.add_rounded, size: 24),
              const SizedBox(width: 10),
              Text(
                'إنشاء دور جديد',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
