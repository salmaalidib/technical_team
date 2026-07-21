import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/enums/request_status.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/app_skeleton.dart';
import '../../domain/entities/doc_template.dart';
import '../bloc/templates_bloc.dart';
import '../bloc/templates_event.dart';
import '../bloc/templates_state.dart';
import '../widgets/template_card.dart';
import 'template_form_page.dart';

/// Document-templates dashboard: lists the active templates and opens the
/// create/edit form. Provides the [TemplatesBloc] consumed by both this page
/// and the form page it pushes.
class TemplatesPage extends StatelessWidget {
  const TemplatesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<TemplatesBloc>()..add(const LoadTemplates()),
      child: const _TemplatesView(),
    );
  }
}

class _TemplatesView extends StatelessWidget {
  const _TemplatesView();

  Future<void> _openForm(BuildContext context, {DocTemplate? template}) async {
    final bloc = context.read<TemplatesBloc>();
    bloc.add(const ResetTemplateForm());
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TemplateFormPage(
          templatesBloc: bloc,
          template: template,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final horizontal = MediaQuery.sizeOf(context).width < 700 ? 16.0 : 40.0;
    return Container(
      color: const Color(0xffF0EFE7),
      padding: EdgeInsets.fromLTRB(horizontal, 28, horizontal, 30),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Header(onCreate: () => _openForm(context)),
            const SizedBox(height: 28),
            _Body(onEdit: (t) => _openForm(context, template: t)),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final VoidCallback onCreate;

  const _Header({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'قوالب المستندات',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'إنشاء وتعديل قوالب الوثائق ونماذجها',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        ElevatedButton.icon(
          onPressed: onCreate,
          icon: const Icon(Icons.add_rounded, size: 20),
          label: const Text('قالب جديد'),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(0, 50),
            padding: const EdgeInsets.symmetric(horizontal: 22),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ],
    );
  }
}

class _Body extends StatelessWidget {
  final ValueChanged<DocTemplate> onEdit;

  const _Body({required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TemplatesBloc, TemplatesState>(
      buildWhen: (p, c) => p.status != c.status || p.templates != c.templates,
      builder: (context, state) {
        switch (state.status) {
          case RequestStatus.initial:
          case RequestStatus.loading:
            return const AppSkeleton.cards();
          case RequestStatus.failure:
            return _ErrorState(
              message: state.error ?? 'حدث خطأ غير متوقع',
              onRetry: () =>
                  context.read<TemplatesBloc>().add(const LoadTemplates()),
            );
          case RequestStatus.success:
            if (state.templates.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 80),
                child: Center(
                  child: Text(
                    'لا توجد قوالب لعرضها — أنشئ قالبك الأول',
                    style: TextStyle(color: Colors.black54, fontSize: 15),
                  ),
                ),
              );
            }
            return _Grid(templates: state.templates, onEdit: onEdit);
        }
      },
    );
  }
}

class _Grid extends StatelessWidget {
  final List<DocTemplate> templates;
  final ValueChanged<DocTemplate> onEdit;

  const _Grid({required this.templates, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 22.0;
        final width = constraints.maxWidth;
        final columns = width >= 1000 ? 3 : (width >= 640 ? 2 : 1);
        final cardWidth = (width - (columns - 1) * gap) / columns;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: templates
              .map((t) => SizedBox(
                    width: cardWidth,
                    child: TemplateCard(
                      template: t,
                      onEdit: () => onEdit(t),
                    ),
                  ))
              .toList(),
        );
      },
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppColors.error, size: 44),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('إعادة المحاولة'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}
