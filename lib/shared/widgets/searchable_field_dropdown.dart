import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/enums/request_status.dart';
import '../../features/fields/domain/entities/field_type.dart';
import '../../features/fields/presentation/bloc/fields_bloc.dart';
import '../../features/fields/presentation/bloc/fields_event.dart';
import '../../features/fields/presentation/bloc/fields_state.dart';
import '../../features/fields/presentation/widgets/create_field_dialog.dart';
import '../../features/process_builder/domain/entities/widget_config.dart';
import '../theme/app_colors.dart';

/// Selection behaviour of [SearchableFieldDropdown].
enum FieldDropdownMode { single, multi }

/// A polished, RTL dropdown over the shared field library for one [FieldType],
/// backed by server-side search + pagination via [FieldsBloc].
///
/// * Opens an anchored panel with a search box, a lazily-paginated list
///   (infinite scroll), and elegant loading / empty / error states.
/// * [FieldDropdownMode.multi] → checkboxes; [selectedIds] drives ticks and the
///   trigger shows a count. [FieldDropdownMode.single] → tap to pick; the
///   trigger shows the picked label and offers a clear action.
/// * A trailing "+" opens [CreateFieldDialog] for the same type; on success the
///   bloc reloads the first page so the new field shows up.
class SearchableFieldDropdown extends StatefulWidget {
  final FieldType type;

  /// Backend `widget_type` this dropdown filters/creates (e.g. `text_field`,
  /// `dropdown`). Used only for the hint/empty copy — the bloc already scopes
  /// results by [type].
  final String title;

  final FieldDropdownMode mode;

  /// Currently-selected widget ids (multi) or the single selected id (single).
  final Set<String> selectedIds;

  /// Multi mode: toggled a widget on/off.
  final void Function(WidgetConfig widget, bool selected)? onToggle;

  /// Single mode: picked a widget (null when cleared).
  final void Function(WidgetConfig? widget)? onPicked;

  /// Optional explicit label for the trigger (single mode). Useful when the
  /// selected widget isn't in the currently-loaded page — e.g. the templates
  /// picker rebinds a field's id, so the bloc can't resolve its label.
  final String? triggerLabel;

  /// Whether to show the trailing "+ create field" button.
  final bool showCreate;

  const SearchableFieldDropdown({
    super.key,
    required this.type,
    required this.title,
    required this.mode,
    required this.selectedIds,
    this.onToggle,
    this.onPicked,
    this.triggerLabel,
    this.showCreate = true,
  });

  @override
  State<SearchableFieldDropdown> createState() =>
      _SearchableFieldDropdownState();
}

class _SearchableFieldDropdownState extends State<SearchableFieldDropdown> {
  final _controller = OverlayPortalController();
  final _link = LayerLink();
  final _searchCtrl = TextEditingController();
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
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollCtrl.hasClients) return;
    final pos = _scrollCtrl.position;
    if (pos.pixels >= pos.maxScrollExtent - 120) {
      context.read<FieldsBloc>().add(FieldTypeNextPageRequested(widget.type));
    }
  }

  void _open() {
    // Ensure the first page is loaded when the panel opens.
    context.read<FieldsBloc>().add(FieldTypeOpened(widget.type));
    _controller.show();
  }

  void _close() => _controller.hide();

  Future<void> _createField() async {
    final bloc = context.read<FieldsBloc>();
    await showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.55),
      builder: (_) => BlocProvider.value(
        value: bloc,
        child: CreateFieldDialog(type: widget.type),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _link,
      child: OverlayPortal(
        controller: _controller,
        overlayChildBuilder: _buildPanel,
        child: Row(
          textDirection: TextDirection.rtl,
          children: [
            Expanded(child: _Trigger(
              type: widget.type,
              mode: widget.mode,
              title: widget.title,
              selectedIds: widget.selectedIds,
              triggerLabel: widget.triggerLabel,
              onTap: () => _controller.isShowing ? _close() : _open(),
            )),
            if (widget.showCreate) ...[
              const SizedBox(width: 8),
              _AddButton(onTap: _createField),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPanel(BuildContext context) {
    // Full-screen tap-catcher to dismiss, plus the anchored panel itself.
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
          targetAnchor: Alignment.bottomRight,
          followerAnchor: Alignment.topRight,
          offset: const Offset(0, 8),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Align(
              alignment: Alignment.topRight,
              child: _Panel(
                type: widget.type,
                title: widget.title,
                mode: widget.mode,
                selectedIds: widget.selectedIds,
                searchCtrl: _searchCtrl,
                scrollCtrl: _scrollCtrl,
                onToggle: widget.onToggle,
                onPicked: (w) {
                  widget.onPicked?.call(w);
                  _close();
                },
                onClose: _close,
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
  final FieldType type;
  final FieldDropdownMode mode;
  final String title;
  final Set<String> selectedIds;
  final String? triggerLabel;
  final VoidCallback onTap;

  const _Trigger({
    required this.type,
    required this.mode,
    required this.title,
    required this.selectedIds,
    required this.triggerLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final count = selectedIds.length;
    final hasSelection =
        count > 0 || (triggerLabel != null && triggerLabel!.isNotEmpty);

    // For single mode we show the selected label if the bloc has it loaded.
    String label;
    if (mode == FieldDropdownMode.multi) {
      label = count > 0 ? '$count محدد' : 'اختر $title...';
    } else if (triggerLabel != null && triggerLabel!.isNotEmpty) {
      label = triggerLabel!;
    } else {
      final selectedLabel = context.select<FieldsBloc, String?>((b) {
        if (selectedIds.isEmpty) return null;
        final id = selectedIds.first;
        for (final w in b.state.of(type).items) {
          if (w.widgetId == id) return w.label;
        }
        return null;
      });
      label = selectedLabel ?? (count > 0 ? 'محدد' : 'اختر $title...');
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
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
                label,
                textAlign: TextAlign.right,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color:
                      hasSelection ? AppColors.textPrimary : AppColors.textSecondary,
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
  final FieldType type;
  final String title;
  final FieldDropdownMode mode;
  final Set<String> selectedIds;
  final TextEditingController searchCtrl;
  final ScrollController scrollCtrl;
  final void Function(WidgetConfig widget, bool selected)? onToggle;
  final void Function(WidgetConfig? widget)? onPicked;
  final VoidCallback onClose;

  const _Panel({
    required this.type,
    required this.title,
    required this.mode,
    required this.selectedIds,
    required this.searchCtrl,
    required this.scrollCtrl,
    required this.onToggle,
    required this.onPicked,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context).size;
    final panelWidth = media.width < 420 ? media.width - 32 : 360.0;

    return Material(
      color: Colors.transparent,
      child: Container(
        width: panelWidth,
        constraints: const BoxConstraints(maxHeight: 420),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _SearchBar(
              controller: searchCtrl,
              hint: 'ابحث في $title...',
              onChanged: (q) =>
                  context.read<FieldsBloc>().add(FieldTypeSearchChanged(type, q)),
              onClear: () {
                searchCtrl.clear();
                context.read<FieldsBloc>().add(FieldTypeSearchChanged(type, ''));
              },
            ),
            const Divider(height: 1, color: AppColors.border),
            Flexible(child: _Results(
              type: type,
              mode: mode,
              selectedIds: selectedIds,
              scrollCtrl: scrollCtrl,
              onToggle: onToggle,
              onPicked: onPicked,
            )),
          ],
        ),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _SearchBar({
    required this.controller,
    required this.hint,
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
          hintText: hint,
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
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
          ),
        ),
      ),
    );
  }
}

class _Results extends StatelessWidget {
  final FieldType type;
  final FieldDropdownMode mode;
  final Set<String> selectedIds;
  final ScrollController scrollCtrl;
  final void Function(WidgetConfig widget, bool selected)? onToggle;
  final void Function(WidgetConfig? widget)? onPicked;

  const _Results({
    required this.type,
    required this.mode,
    required this.selectedIds,
    required this.scrollCtrl,
    required this.onToggle,
    required this.onPicked,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FieldsBloc, FieldsState>(
      buildWhen: (p, c) => p.of(type) != c.of(type),
      builder: (context, state) {
        final s = state.of(type);

        if (s.status == RequestStatus.loading && s.items.isEmpty) {
          return const _PanelMessage(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.4),
                ),
              ),
            ),
          );
        }

        if (s.status == RequestStatus.failure && s.items.isEmpty) {
          return _PanelMessage(
            child: _Info(
              icon: Icons.error_outline_rounded,
              color: AppColors.error,
              text: s.error ?? 'تعذّر تحميل القائمة',
            ),
          );
        }

        if (s.items.isEmpty) {
          return _PanelMessage(
            child: _Info(
              icon: Icons.inbox_rounded,
              color: AppColors.textSecondary,
              text: s.search.isEmpty
                  ? 'لا توجد عناصر — أنشئ واحداً عبر زر +'
                  : 'لا نتائج للبحث "${s.search}"',
            ),
          );
        }

        final itemCount = s.items.length + (s.loadingMore ? 1 : 0);

        return ListView.separated(
          controller: scrollCtrl,
          padding: const EdgeInsets.symmetric(vertical: 6),
          shrinkWrap: true,
          itemCount: itemCount,
          separatorBuilder: (_, __) => const SizedBox(height: 2),
          itemBuilder: (context, i) {
            if (i >= s.items.length) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Center(
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              );
            }

            final w = s.items[i];
            final selected = selectedIds.contains(w.widgetId);

            return _Row(
              label: w.label,
              query: s.search,
              selected: selected,
              mode: mode,
              onTap: () {
                if (mode == FieldDropdownMode.multi) {
                  onToggle?.call(w, !selected);
                } else {
                  onPicked?.call(selected ? null : w);
                }
              },
            );
          },
        );
      },
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String query;
  final bool selected;
  final FieldDropdownMode mode;
  final VoidCallback onTap;

  const _Row({
    required this.label,
    required this.query,
    required this.selected,
    required this.mode,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        color: selected ? AppColors.lightPrimary : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Row(
          textDirection: TextDirection.rtl,
          children: [
            if (mode == FieldDropdownMode.multi)
              _MiniCheckbox(checked: selected)
            else
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                size: 20,
                color: selected ? AppColors.primary : AppColors.textSecondary,
              ),
            const SizedBox(width: 8),
            Expanded(
              child: _HighlightedText(
                text: label,
                query: query,
                selected: selected,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Renders [text] with the matched [query] substring highlighted.
class _HighlightedText extends StatelessWidget {
  final String text;
  final String query;
  final bool selected;

  const _HighlightedText({
    required this.text,
    required this.query,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    final base = TextStyle(
      fontSize: 14,
      color: AppColors.textPrimary,
      fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
    );

    if (query.isEmpty) {
      return Text(text,
          textAlign: TextAlign.right,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: base);
    }

    final lower = text.toLowerCase();
    final q = query.toLowerCase();
    final idx = lower.indexOf(q);
    if (idx < 0) {
      return Text(text,
          textAlign: TextAlign.right,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: base);
    }

    return RichText(
      textAlign: TextAlign.right,
      textDirection: TextDirection.rtl,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        style: base,
        children: [
          TextSpan(text: text.substring(0, idx)),
          TextSpan(
            text: text.substring(idx, idx + query.length),
            style: base.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w800,
              backgroundColor: AppColors.lightPrimary,
            ),
          ),
          TextSpan(text: text.substring(idx + query.length)),
        ],
      ),
    );
  }
}

class _MiniCheckbox extends StatelessWidget {
  final bool checked;
  const _MiniCheckbox({required this.checked});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: checked ? AppColors.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: checked ? AppColors.primary : AppColors.border,
          width: 1.6,
        ),
      ),
      child: checked
          ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
          : null,
    );
  }
}

class _PanelMessage extends StatelessWidget {
  final Widget child;
  const _PanelMessage({required this.child});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 90),
      child: Center(child: child),
    );
  }
}

class _Info extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;

  const _Info({required this.icon, required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 30, color: color),
          const SizedBox(height: 10),
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  final VoidCallback onTap;
  const _AddButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 24),
      ),
    );
  }
}
