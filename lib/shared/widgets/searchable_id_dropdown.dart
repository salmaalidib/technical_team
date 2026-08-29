import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_dimens.dart';

/// Searchable, RTL replacement for `DropdownButtonFormField<int>` over an
/// already-loaded `{ id: name }` map (departments, roles, …).
///
/// Unlike [SearchableFieldDropdown] — which pages a bloc from the server —
/// every option is in memory here, so filtering is local. What it fixes over a
/// plain dropdown:
///
/// * a search box, so long lists (dozens of departments/roles) are typeable
///   instead of scrollable;
/// * the panel is measured against the free space around the trigger and
///   flipped/clamped, so it never runs off the bottom of the screen — the
///   Material menu happily grew past it;
/// * [allowClear] gives an optional field a way back to no-selection.
class SearchableIdDropdown extends StatefulWidget {
  final String hint;
  final int? value;
  final Map<int, String> items;

  /// Null disables the field (loading, empty list, form submitting) — same
  /// contract as `DropdownButtonFormField.onChanged`.
  final ValueChanged<int?>? onChanged;

  final String? errorText;

  /// Prepends a null-valued entry so an optional field can be reset.
  final bool allowClear;
  final String clearLabel;

  /// Label of the search box; defaults to a generic "ابحث...".
  final String? searchHint;

  const SearchableIdDropdown({
    super.key,
    required this.hint,
    required this.value,
    required this.items,
    required this.onChanged,
    this.errorText,
    this.allowClear = false,
    this.clearLabel = '',
    this.searchHint,
  });

  @override
  State<SearchableIdDropdown> createState() => _SearchableIdDropdownState();
}

class _SearchableIdDropdownState extends State<SearchableIdDropdown> {
  final _controller = OverlayPortalController();
  final _link = LayerLink();
  final _searchCtrl = TextEditingController();

  /// Placement decided when the panel opens, then held until it closes — the
  /// host form can grow while the panel is up (an error line appears, a chip is
  /// added), and recomputing would make the open panel jump.
  bool _flip = false;
  double _maxHeight = _kMaxPanelHeight;

  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
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

    // Flip up only when below is genuinely cramped and above has more room.
    _flip = below < _kMinPanelHeight && above > below;
    _maxHeight = ((_flip ? above : below) - 16)
        .clamp(_kMinPanelHeight, _kMaxPanelHeight)
        .toDouble();
  }

  void _open() {
    if (widget.onChanged == null) return;
    _searchCtrl.clear();
    _query = '';
    _measurePlacement();
    _controller.show();
    // The trigger's border/arrow reflect the open state, and showing the
    // overlay alone doesn't rebuild this widget.
    setState(() {});
  }

  void _close() {
    _controller.hide();
    if (mounted) setState(() {});
  }

  /// Case-insensitive contains, with the Arabic definite article and diacritics
  /// left alone — the names are short enough that a plain match is enough.
  List<MapEntry<int, String>> get _filtered {
    final q = _query.trim().toLowerCase();
    final entries = widget.items.entries.toList();
    if (q.isEmpty) return entries;
    return entries.where((e) => e.value.toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    // A value no longer present in [items] (e.g. departments reloaded after the
    // org changed) must not keep showing a stale label.
    final selectedLabel = widget.items[widget.value];
    final enabled = widget.onChanged != null;

    return CompositedTransformTarget(
      link: _link,
      child: OverlayPortal(
        controller: _controller,
        overlayChildBuilder: _buildPanel,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Trigger(
              hint: widget.hint,
              label: selectedLabel,
              enabled: enabled,
              hasError: widget.errorText != null,
              open: _controller.isShowing,
              onTap: () => _controller.isShowing ? _close() : _open(),
            ),
            if (widget.errorText != null)
              Padding(
                padding: const EdgeInsets.only(top: 6, right: 12),
                child: Text(
                  widget.errorText!,
                  textAlign: TextAlign.right,
                  style: const TextStyle(color: AppColors.error, fontSize: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPanel(BuildContext context) {
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
                // Match the trigger's width so the panel reads as part of the
                // field rather than a floating box.
                width: _triggerWidth(),
                searchCtrl: _searchCtrl,
                searchHint: widget.searchHint ?? 'ابحث...',
                query: _query,
                onQueryChanged: (q) => setState(() => _query = q),
                entries: _filtered,
                selected: widget.value,
                allowClear: widget.allowClear,
                clearLabel: widget.clearLabel,
                onPicked: (id) {
                  widget.onChanged?.call(id);
                  _close();
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  double? _triggerWidth() {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    return box.size.width;
  }
}

/// Never shrink the panel below this — anything smaller can't show the search
/// box plus a couple of rows.
const double _kMinPanelHeight = 220;
const double _kMaxPanelHeight = 380;

// ════════════════════════════ trigger ════════════════════════════

class _Trigger extends StatelessWidget {
  final String hint;
  final String? label;
  final bool enabled;
  final bool hasError;
  final bool open;
  final VoidCallback onTap;

  const _Trigger({
    required this.hint,
    required this.label,
    required this.enabled,
    required this.hasError,
    required this.open,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasSelection = label != null && label!.isNotEmpty;

    final borderColor = hasError
        ? AppColors.error
        : open
            ? AppColors.primary
            : hasSelection
                ? AppColors.primary
                : AppColors.border;

    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: enabled ? AppColors.white : AppColors.background,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(
            color: enabled ? borderColor : AppColors.border,
            width: (open || hasSelection) && !hasError ? 1.4 : 1.1,
          ),
        ),
        child: Row(
          textDirection: TextDirection.rtl,
          children: [
            Icon(
              Icons.search_rounded,
              size: 18,
              color: hasSelection && enabled
                  ? AppColors.primary
                  : AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                hasSelection ? label! : hint,
                textAlign: TextAlign.right,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: hasSelection && enabled
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                  fontSize: 15,
                  fontWeight: hasSelection ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
            AnimatedRotation(
              duration: const Duration(milliseconds: 150),
              turns: open ? 0.5 : 0,
              child: Icon(
                Icons.keyboard_arrow_down_rounded,
                color:
                    enabled ? AppColors.textPrimary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════ panel ════════════════════════════

class _Panel extends StatelessWidget {
  final double maxHeight;
  final double? width;
  final TextEditingController searchCtrl;
  final String searchHint;
  final String query;
  final ValueChanged<String> onQueryChanged;
  final List<MapEntry<int, String>> entries;
  final int? selected;
  final bool allowClear;
  final String clearLabel;
  final ValueChanged<int?> onPicked;

  const _Panel({
    required this.maxHeight,
    required this.width,
    required this.searchCtrl,
    required this.searchHint,
    required this.query,
    required this.onQueryChanged,
    required this.entries,
    required this.selected,
    required this.allowClear,
    required this.clearLabel,
    required this.onPicked,
  });

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context).size;
    // Follow the trigger, but never overflow a narrow window.
    final panelWidth =
        (width ?? 320).clamp(240.0, (media.width - 32).clamp(240.0, 640.0));

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
            _SearchBar(
              controller: searchCtrl,
              hint: searchHint,
              onChanged: onQueryChanged,
              onClear: () {
                searchCtrl.clear();
                onQueryChanged('');
              },
            ),
            const Divider(height: 1, color: AppColors.border),
            Flexible(
              child: entries.isEmpty
                  ? _Empty(query: query)
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      shrinkWrap: true,
                      itemCount: entries.length + (allowClear ? 1 : 0),
                      separatorBuilder: (_, __) => const SizedBox(height: 2),
                      itemBuilder: (context, i) {
                        if (allowClear && i == 0) {
                          return _Row(
                            label: clearLabel,
                            query: '',
                            selected: selected == null,
                            muted: true,
                            onTap: () => onPicked(null),
                          );
                        }
                        final e = entries[allowClear ? i - 1 : i];
                        return _Row(
                          label: e.value,
                          query: query,
                          selected: e.key == selected,
                          onTap: () => onPicked(e.key),
                        );
                      },
                    ),
            ),
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
            borderRadius: BorderRadius.circular(AppRadius.sm),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
          ),
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String query;
  final bool selected;
  final bool muted;
  final VoidCallback onTap;

  const _Row({
    required this.label,
    required this.query,
    required this.selected,
    required this.onTap,
    this.muted = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        color: selected ? AppColors.lightPrimary : AppColors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          textDirection: TextDirection.rtl,
          children: [
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
                muted: muted,
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
  final bool muted;

  const _HighlightedText({
    required this.text,
    required this.query,
    required this.selected,
    this.muted = false,
  });

  @override
  Widget build(BuildContext context) {
    // fontFamily صريح: هذا النمط يُستخدم أيضاً داخل RichText أدناه، وهو لا
    // يرث DefaultTextStyle كما يفعل Text.
    final base = TextStyle(
      fontFamily: AppTextStyles.fontFamily,
      fontSize: 14,
      color: muted ? AppColors.textSecondary : AppColors.textPrimary,
      fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
    );

    final q = query.trim().toLowerCase();
    final idx = q.isEmpty ? -1 : text.toLowerCase().indexOf(q);

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
            text: text.substring(idx, idx + q.length),
            style: base.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w800,
              backgroundColor: AppColors.lightPrimary,
            ),
          ),
          TextSpan(text: text.substring(idx + q.length)),
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  final String query;
  const _Empty({required this.query});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 90),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.inbox_rounded,
                  size: 30, color: AppColors.textSecondary),
              const SizedBox(height: 10),
              Text(
                query.trim().isEmpty
                    ? 'لا توجد عناصر'
                    : 'لا نتائج للبحث "$query"',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
