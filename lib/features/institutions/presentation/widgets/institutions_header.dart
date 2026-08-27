import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../shared/theme/app_colors.dart';
import '../bloc/institutions_bloc.dart';
import '../bloc/institutions_state.dart';
import 'create_institution_dialog.dart';
import '../../../../shared/theme/app_dimens.dart';
import '../../../../shared/theme/app_text_styles.dart';

class InstitutionsHeader extends StatelessWidget {
  const InstitutionsHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<InstitutionsBloc, InstitutionsState>(
      buildWhen: (p, c) => p.breadcrumb != c.breadcrumb,
      builder: (context, state) {
        final atRoot = state.breadcrumb.isEmpty;
        final title = atRoot
            ? 'إدارة المؤسسات'
            : 'المؤسسات التابعة لـ: ${state.breadcrumb.last.name}';
        final subtitle = atRoot
            ? 'عرض وإدارة جميع المؤسسات التعليمية'
            : 'المؤسسات التابعة للمؤسسة المحددة';
        final buttonLabel = atRoot ? 'إنشاء مؤسسة جديدة' : 'إضافة مؤسسة تابعة';

        return Wrap(
          textDirection: TextDirection.rtl,
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 20,
          runSpacing: 16,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 520,
                minWidth: 260,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    textDirection: TextDirection.rtl,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.apartment_outlined,
                        color: AppColors.primary,
                        size: 32,
                      ),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 31,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 240,
              height: 58,
              child: ElevatedButton.icon(
                onPressed: () {
                  // Hand the page's bloc to the dialog so its form can submit
                  // through the same InstitutionsBloc instance.
                  final bloc = context.read<InstitutionsBloc>();
                  final crumb = atRoot ? null : bloc.state.breadcrumb.last;
                  showDialog(
                    context: context,
                    barrierColor: AppColors.scrim,
                    builder: (_) => BlocProvider.value(
                      value: bloc,
                      child: CreateInstitutionDialog(
                        fixedParentId: crumb?.id,
                        fixedParentName: crumb?.name,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.add_rounded, size: 24),
                label: Text(
                  buttonLabel,
                  overflow: TextOverflow.ellipsis,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  // styleFrom يستبدل نمط الثيم بالكامل، فيجب تثبيت الخط هنا
                  // وإلا سقط النص إلى خط النظام.
                  textStyle: AppTextStyles.labelLarge,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
