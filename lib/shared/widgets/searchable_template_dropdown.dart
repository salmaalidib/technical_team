import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/enums/request_status.dart';
import '../../features/templates/domain/entities/doc_template.dart';
import '../../features/templates/presentation/bloc/templates_bloc.dart';
import '../../features/templates/presentation/bloc/templates_event.dart';
import '../../features/templates/presentation/bloc/templates_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';

/// Never shrink the panel below this — a shorter box can't scroll far enough to
/// trigger the next page, which silently breaks pagination.
const double _kMinPanelHeight = 240;
const double _kMaxPanelHeight = 420;

/// A searchable, server-paginated multi-select over the document templates —
/// the same interaction as `SearchableFieldDropdown`, so the wizard's template
/// picker behaves exactly like its date/field pickers.
///
/// Selection state is owned by the caller ([selectedIds] + [onToggle]) because
/// the templates linked to a stage live in the process-builder draft, not in
/// [TemplatesBloc]. [selectedTemplates] is passed separately so a linked
/// template still renders as a chip even when it isn't on the loaded page.
class SearchableTemplateDropdown extends StatefulWidget {
  final Set<int> selectedIds;

  /// Already-linked templates, used for the trigger count and the chips.
  final List<DocTemplate> selectedTemplates;

  final void Function(DocTemplate template, bool selected) onToggle;

  const SearchableTemplateDropdown({
    super.key,
    required this.selectedIds,
    required this.selectedTemplates,
    required this.onToggle,
  });

  @override
  State<SearchableTemplateDropdown> createState() =>
      _SearchableTemplateDropdownState();
}

class _SearchableTemplateDropdownState
    extends State<SearchableTemplateDropdown> {
  final _controller = OverlayPortalController();
  final _link = LayerLink();
  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  /// Placement decided when the panel opens, then held until it closes.
  ///
  /// Recomputing it on every rebuild made the panel jump: picking a template
  /// adds a chip under the trigger, which grows the form, pushes the trigger
  /// down and shrinks the space below it — so the next rebuild flipped the
  /// open panel above the trigger mid-interaction.
  bool _flip = false;
  double _maxHeight = _kMaxPanelHeight;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollCtrl.removeListener(_onScroll);
    _scrollCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollCtrl.hasClients) return;
    final pos = _scrollCtrl.position;
    // `maxScrollExtent == 0` means the list doesn't overflow the panel, so
    // there is nothing to reach — never treat that as "hit the bottom".
    if (pos.maxScrollExtent <= 0) return;
    if (pos.pixels >= pos.maxScrollExtent - 120) {
      context.read<TemplatesBloc>().add(const TemplatesNextPageRequested());
    }
  }

  /// A page that doesn't fill the panel leaves nothing to scroll, so the user
  /// can never reach the bottom to pull page 2. Grow until it overflows.
  void _topUpIfNotScrollable() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_controller.isShowing) return;
      if (!_scrollCtrl.hasClients) return;
      if (_scrollCtrl.position.maxScrollExtent > 0) return;

      final s = context.read<TemplatesBloc>().state;
      if (s.hasMore && !s.loadingMore && s.status != RequestStatus.loading) {
        context.read<TemplatesBloc>().add(const TemplatesNextPageRequested());
      }
    });
  }

  /// Measures the free space around the trigger and freezes the placement for
  /// this open session.
  void _measurePlacement() {
    final box = context.findRenderObject() as RenderBox?;
    final media = MediaQuery.of(context);
    final screenH = media.size.height;

    var below = screenH;
    var above = 0.0;
    if (box != null && box.hasSize) {
      final top = box.localToGlobal(Offset.zero).dy;
      final bottom = top + box.size.height;
      below = screenH - media.padding.bottom - bottom;
      above = top - media.padding.top;
    }

    _flip = below < _kMinPanelHeight && above > below;
    _maxHeight = ((_flip ? above : below) - 16)
        .clamp(_kMinPanelHeight, _kMaxPanelHeight)
        .toDouble();
  }

  void _open() {
    // Reset the box so the panel opens on the full (unfiltered) list.
    _searchCtrl.clear();
    _measurePlacement();
    final bloc = context.read<TemplatesBloc>();
    if (bloc.state.status != RequestStatus.success ||
        bloc.state.search.isNotEmpty) {
      bloc.add(const LoadTemplates(limit: kTemplatesPageSize));
    }
    _controller.show();
  }

  void _close() => _controller.hide();

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _link,
      child: OverlayPortal(
        controller: _controller,
        overlayChildBuilder: _buildPanel,
        child: _Trigger(
          count: widget.selectedIds.length,
          onTap: () => _controller.isShowing ? _close() : _open(),
        ),
      ),
    );
  }

  Widget _buildPanel(BuildContext context) {
    // Placement is whatever [_measurePlacement] decided at open time — never
    // recomputed here, or the panel would move while the user is using it.
    final flip = _flip;
    final maxHeight = _maxHeight;

    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: _close,
          ),
        ),
        CompositedTransformFollower(
          link: _link,
          targetAnchor: flip ? Alignment.topRight : Alignment.bottomRight,
          followerAnchor: flip ? Alignment.bottomRight : Alignment.topRight,
          offset: Offset(0, flip ? -8 : 8),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Align(
              alignment: flip ? Alignment.bottomRight : Alignment.topRight,
              child: _Panel(
                maxHeight: maxHeight,
                selectedIds: widget.selectedIds,
                searchCtrl: _searchCtrl,
                scrollCtrl: _scrollCtrl,
                onBuilt: _topUpIfNotScrollable,
                onToggle: widget.onToggle,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ════════════════════════════ trigger ════════════════════════════

class _Trigger extends StatelessWidget {
  final int count;
  final VoidCallback onTap;

  const _Trigger({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final hasSelection = count > 0;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(
            color: hasSelection ? AppColors.primary : AppColors.border,
            width: hasSelection ? 1.4 : 1.1,
          ),
        ),
        child: Row(
          textDirection: TextDirection.rtl,
          children: [
            Icon(
              Icons.search_rounded,
              size: 18,
              color: hasSelection ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                hasSelection ? '$count قالب محدد' : 'اختر القوالب...',
                textAlign: TextAlign.right,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: hasSelection
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                  fontSize: 15,
                  fontWeight: hasSelection ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
            const Icon(Icons.keyboard_arrow_down_rounded,
                color: AppColors.textPrimary),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════ panel ════════════════════════════

class _Panel extends StatelessWidget {
  final double maxHeight;
  final Set<int> selectedIds;
  final TextEditingController searchCtrl;
  final ScrollController scrollCtrl;
  final VoidCallback onBuilt;
  final void Function(DocTemplate template, bool selected) onToggle;

  const _Panel({
    required this.maxHeight,
    required this.selectedIds,
    required this.searchCtrl,
    required this.scrollCtrl,
    required this.onBuilt,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context).size;
    final panelWidth = media.width < 420 ? media.width - 32 : 360.0;

    return Material(
      color: AppColors.transparent,
      child: Container(
        width: panelWidth,
        constraints: BoxConstraints(maxHeight: maxHeight),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.border),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadowMedium,
              blurRadius: 24,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _PanelSearchBar(
              controller: searchCtrl,
              onChanged: (q) => context
                  .read<TemplatesBloc>()
                  .add(TemplatesSearchChanged(q)),
              onClear: () {
                searchCtrl.clear();
                context
                    .read<TemplatesBloc>()
                    .add(const TemplatesSearchChanged(''));
              },
            ),
            const Divider(height: 1, color: AppColors.border),
            Flexible(
              child: _Results(
                selectedIds: selectedIds,
                scrollCtrl: scrollCtrl,
                onBuilt: onBuilt,
                onToggle: onToggle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PanelSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _PanelSearchBar({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: TextField(
        controller: controller,
        autofocus: true,
        textAlign: TextAlign.right,
        textDirection: TextDirection.rtl,
        onChanged: onChanged,
        style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
        decoration: InputDecoration(
          isDense: true,
          hintText: 'ابحث في القوالب...',
          hintStyle:
              const TextStyle(color: AppColors.textSecondary, fontSize: 13),
          prefixIcon: const Icon(Icons.search_rounded,
              size: 20, color: AppColors.textSecondary),
          suffixIcon: ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (_, value, __) => value.text.isEmpty
                ? const SizedBox.shrink()
                : IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18),
                    color: AppColors.textSecondary,
                    onPressed: onClear,
                  ),
          ),
          filled: true,
          fillColor: AppColors.background,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            borderSide: const BorderSide(color: AppColors.primary),
          ),
        ),
      ),
    );
  }
}

class _Results extends StatelessWidget {
  final Set<int> selectedIds;
  final ScrollController scrollCtrl;
  final VoidCallback onBuilt;
  final void Function(DocTemplate template, bool selected) onToggle;

  const _Results({
    required this.selectedIds,
    required this.scrollCtrl,
    required this.onBuilt,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TemplatesBloc, TemplatesState>(
      buildWhen: (p, c) =>
          p.status != c.status ||
          p.templates != c.templates ||
          p.loadingMore != c.loadingMore ||
          p.error != c.error,
      builder: (context, state) {
        if (state.status == RequestStatus.loading && state.templates.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 36),
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
          );
        }

        if (state.status == RequestStatus.failure && state.templates.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              state.error ?? 'تعذّر تحميل القوالب',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.error, fontSize: 13),
            ),
          );
        }

        if (state.templates.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              state.search.isEmpty
                  ? 'لا توجد قوالب — أنشئ قوالب من صفحة القوالب'
                  : 'لا توجد قوالب مطابقة',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 13),
            ),
          );
        }

        onBuilt();

        return ListView.builder(
          controller: scrollCtrl,
          padding: const EdgeInsets.symmetric(vertical: 4),
          shrinkWrap: true,
          itemCount: state.templates.length + (state.loadingMore ? 1 : 0),
          itemBuilder: (context, i) {
            if (i >= state.templates.length) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Center(
                  child: SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              );
            }

            final t = state.templates[i];
            final selected = selectedIds.contains(t.id);

            return InkWell(
              onTap: () => onToggle(t, !selected),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                child: Row(
                  textDirection: TextDirection.rtl,
                  children: [
                    Checkbox(
                      value: selected,
                      activeColor: AppColors.primary,
                      visualDensity: VisualDensity.compact,
                      onChanged: (v) => onToggle(t, v ?? false),
                    ),
                    Expanded(
                      child: Text(
                        t.name,
                        textAlign: TextAlign.right,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          color: selected
                              ? AppColors.primary
                              : AppColors.textPrimary,
                          fontWeight:
                              selected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
