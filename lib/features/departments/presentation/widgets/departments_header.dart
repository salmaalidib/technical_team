import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../shared/theme/app_colors.dart';
import '../bloc/departments_bloc.dart';
import '../bloc/departments_state.dart';
import 'create_department_dialog.dart';

class DepartmentsHeader extends StatelessWidget {
  const DepartmentsHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DepartmentsBloc, DepartmentsState>(
      buildWhen: (p, c) => p.breadcrumb != c.breadcrumb,
      builder: (context, state) {
        final atRoot = state.breadcrumb.isEmpty;
        final title = atRoot
            ? 'الهيكل التنظيمي للأقسام'
            : 'شعب: ${state.breadcrumb.last.name}';
        final subtitle = atRoot
            ? 'عرض هرمي تفاعلي للدوائر والأقسام والشعب والموظفين'
            : 'الشعب التابعة للقسم المحدد';
        final buttonLabel = atRoot ? 'إنشاء قسم جديد' : 'إضافة شعبة';

        return Wrap(
          textDirection: TextDirection.rtl,
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 20,
          runSpacing: 16,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  textDirection: TextDirection.rtl,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.folder_outlined,
                        color: AppColors.primary, size: 34),
                    const SizedBox(width: 10),
                    Text(
                      title,
                      style:
                          Theme.of(context).textTheme.headlineLarge?.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w800,
                              ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  textAlign: TextAlign.right,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
            SizedBox(
              width: 240,
              height: 58,
              child: ElevatedButton(
                onPressed: () {
                  final bloc = context.read<DepartmentsBloc>();
                  final crumb =
                      atRoot ? null : bloc.state.breadcrumb.last;
                  showDialog(
                    context: context,
                    barrierColor: Colors.black.withOpacity(0.55),
                    builder: (_) => BlocProvider.value(
                      value: bloc,
                      child: CreateDepartmentDialog(
                        fixedParentId: crumb?.id,
                        fixedParentName: crumb?.name,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  textDirection: TextDirection.rtl,
                  children: [
                    const Icon(Icons.add_rounded, size: 24),
                    const SizedBox(width: 10),
                    Text(
                      buttonLabel,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
