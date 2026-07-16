import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../domain/entities/process_stage.dart';
import '../bloc/process_builder_bloc.dart';
import '../bloc/process_builder_state.dart';

/// Step 3 — read-only preview of the stages generated from the uploaded BPMN.
class Step3PreviewStages extends StatelessWidget {
  const Step3PreviewStages({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProcessBuilderBloc, ProcessBuilderState>(
      buildWhen: (p, c) => p.createdProcess != c.createdProcess,
      builder: (context, state) {
        final stages = state.createdProcess?.stages ?? const <ProcessStage>[];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              textDirection: TextDirection.rtl,
              children: [
                const Icon(Icons.account_tree_outlined,
                    color: AppColors.primary, size: 22),
                const SizedBox(width: 8),
                Text(
                  'معاينة خطوات المعاملة (${stages.length})',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'تسلسل المراحل كما تم توليده من ملف سير العمل',
              textAlign: TextAlign.right,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 24),
            if (stages.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Text(
                    'لم يتم توليد أي مرحلة من الملف',
                    style: TextStyle(color: Colors.black54, fontSize: 15),
                  ),
                ),
              )
            else
              // RTL scroll view: the scroll "start" edge is the right, so a set
              // of cards narrower than the viewport hugs the right edge (no gap
              // on the right) and overflow scrolls leftward.
              Directionality(
                textDirection: TextDirection.rtl,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.only(bottom: 6),
                  child: IntrinsicHeight(
                    child: Row(
                      textDirection: TextDirection.rtl,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (var i = 0; i < stages.length; i++) ...[
                          _StageCard(stage: stages[i], order: i + 1),
                          if (i < stages.length - 1) const _Connector(),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _Connector extends StatelessWidget {
  const _Connector();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 6),
      child: Center(
        child: Icon(Icons.chevron_right_rounded,
            color: AppColors.textSecondary, size: 26),
      ),
    );
  }
}

class _StageCard extends StatelessWidget {
  final ProcessStage stage;
  final int order;
  const _StageCard({required this.stage, required this.order});

  @override
  Widget build(BuildContext context) {
    final isUser = stage.isUserTask;
    final typeLabel = isUser ? 'مهمة مستخدم' : 'مهمة نظام';
    final accent = isUser ? AppColors.primary : AppColors.secondary;
    final icon = isUser ? Icons.shield_outlined : Icons.bolt_outlined;

    return Container(
      width: 230,
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
      decoration: BoxDecoration(
        color: stage.isAuth ? AppColors.lightPrimary : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: stage.isAuth ? AppColors.primary : AppColors.border,
          width: stage.isAuth ? 1.6 : 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // order chip + type icon
          Row(
            textDirection: TextDirection.rtl,
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: const BoxDecoration(
                  color: AppColors.inputBackground,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '$order',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: accent, size: 22),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // name
          SizedBox(
            height: 44,
            child: Center(
              child: Text(
                stage.name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  height: 1.3,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // type badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              typeLabel,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 8),
          // auth sublabel (reserved height to keep cards aligned)
          SizedBox(
            height: 16,
            child: stage.isAuth
                ? const Text(
                    'استمارة التقديم (AUTH)',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
