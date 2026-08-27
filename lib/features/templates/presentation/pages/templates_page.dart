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
import '../../../../shared/theme/app_dimens.dart';

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

class _TemplatesView extends StatefulWidget {
  const _TemplatesView();

  @override
  State<_TemplatesView> createState() => _TemplatesViewState();
}

class _TemplatesViewState extends State<_TemplatesView> {
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollCtrl.removeListener(_onScroll);
    _scrollCtrl.dispose();
    super.dispose();
  }

  /// Fetch the next page as the bottom comes into view.
  void _onScroll() {
    if (!_scrollCtrl.hasClients) return;
    final pos = _scrollCtrl.position;
    // `maxScrollExtent == 0` means the content doesn't overflow, so the bottom
    // is always "reached" — never treat that as a scroll to the end.
    if (pos.maxScrollExtent <= 0) return;
    if (pos.pixels >= pos.maxScrollExtent - 200) {
      context.read<TemplatesBloc>().add(const TemplatesNextPageRequested());
    }
  }

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
      color: AppColors.surfaceAlt,
      padding: EdgeInsets.fromLTRB(horizontal, 28, horizontal, 30),
      child: SingleChildScrollView(
        controller: _scrollCtrl,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Header(onCreate: () => _openForm(context)),
            const SizedBox(height: 18),
            const _SearchBar(),
            const SizedBox(height: 22),
            _Body(onEdit: (t) => _openForm(context, template: t)),
          ],
        ),
      ),
    );
  }
}

/// Debounced search over the templates list. The debounce lives in the bloc's
/// event transformer, so every keystroke can be dispatched safely.
class _SearchBar extends StatefulWidget {
  const _SearchBar();

  @override
  State<_SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<_SearchBar> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: TextField(
        controller: _controller,
        textAlign: TextAlign.right,
        onChanged: (v) =>
            context.read<TemplatesBloc>().add(TemplatesSearchChanged(v)),
        decoration: InputDecoration(
          hintText: 'ابحث باسم القالب...',
          prefixIcon: const Icon(Icons.search_rounded,
              color: AppColors.textSecondary, size: 22),
          suffixIcon: _controller.text.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  color: AppColors.textSecondary,
                  onPressed: () {
                    _controller.clear();
                    context
                        .read<TemplatesBloc>()
                        .add(const TemplatesSearchChanged(''));
                    setState(() {});
                  },
                ),
          filled: true,
          fillColor: AppColors.surface,
          hintStyle: const TextStyle(
              color: AppColors.textSecondary, fontSize: 15),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: const BorderSide(color: AppColors.primary),
          ),
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
              borderRadius: BorderRadius.circular(AppRadius.md),
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
      buildWhen: (p, c) =>
          p.status != c.status ||
          p.templates != c.templates ||
          p.loadingMore != c.loadingMore,
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
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 80),
                child: Center(
                  child: Text(
                    state.search.isEmpty
                        ? 'لا توجد قوالب لعرضها — أنشئ قالبك الأول'
                        : 'لا توجد قوالب مطابقة لـ «${state.search}»',
                    style: const TextStyle(
                        color: AppColors.textTertiary, fontSize: 15),
                  ),
                ),
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Grid(templates: state.templates, onEdit: onEdit),
                if (state.loadingMore)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: SizedBox(
                        height: 26,
                        width: 26,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
              ],
            );
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
