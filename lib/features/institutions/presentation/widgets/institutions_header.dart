import 'package:flutter/material.dart';
import 'package:technical_team/features/institutions/presentation/widgets/create_institution_dialog.dart';

import '../../../../shared/theme/app_colors.dart';

class InstitutionsHeader extends StatelessWidget {
  const InstitutionsHeader({super.key});

  @override
  Widget build(BuildContext context) {
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
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                textDirection: TextDirection.rtl,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.apartment_outlined,
                    color: AppColors.primary,
                    size: 32,
                  ),
                  SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      'إدارة المؤسسات',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 31,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Text(
                'عرض وإدارة جميع المؤسسات التعليمية',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                style: TextStyle(
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
              showDialog(
                context: context,
                barrierColor: Colors.black.withOpacity(0.55),
                builder: (_) => const CreateInstitutionDialog(),
              );
            },
            icon: const Icon(Icons.add_rounded, size: 24),
            label: const Text(
              'إنشاء مؤسسة جديدة',
              overflow: TextOverflow.ellipsis,
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
