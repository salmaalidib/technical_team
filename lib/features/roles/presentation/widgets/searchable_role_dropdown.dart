import 'package:flutter/material.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_dimens.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../domain/entities/role_catalog_item.dart';

/// قائمة اختيار الدور مع بحث محلي.
///
/// الأدوار قائمة صغيرة تصل كاملة من `GET /api/role/catalog`، فالبحث والتصفية
/// يتمّان في الذاكرة بلا أي طلب إضافي — على عكس
/// `SearchableFieldDropdown` المرتبط بـ `FieldsBloc` وترقيم من الخادم.
///
/// يُعرض اسم الدور فقط؛ الكود يبقى في البيانات ويُستخدم في المطابقة أثناء
/// البحث دون أن يظهر في الواجهة.
class SearchableRoleDropdown extends StatefulWidget {
  const SearchableRoleDropdown({
    super.key,
    required this.roles,
    required this.value,
    required this.onChanged,
    this.hint = 'اختر الدور...',
    this.errorText,
  });

  final List<RoleCatalogItem> roles;

  /// `roles.id` المختار حالياً، أو null.
  final int? value;
  final ValueChanged<int?> onChanged;

  final String hint;
  final String? errorText;

  @override
  State<SearchableRoleDropdown> createState() => _SearchableRoleDropdownState();
}

class _SearchableRoleDropdownState extends State<SearchableRoleDropdown> {
  final _controller = OverlayPortalController();
  final _link = LayerLink();
  final _searchCtrl = TextEditingController();
  final _searchFocus = FocusNode();

  String _query = '';

  /// يُقاس مرة عند الفتح ويُثبَّت — إعادة حسابه في كل بناء تجعل اللوحة تقفز
  /// أثناء الكتابة، لأن تقلّص النتائج يغيّر المساحة المتاحة تحت الحقل.
  bool _flip = false;
  double _maxHeight = _kMaxPanelHeight;

  /// عرض الحقل، يُقاس عند الفتح لتطابقه اللوحة تماماً.
  double? _triggerWidth;

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  RoleCatalogItem? get _selected {
    for (final r in widget.roles) {
      if (r.id == widget.value) return r;
    }
    return null;
  }

  /// المطابقة تشمل الكود رغم أنه غير معروض: من يعرف `ACCOUNTING_MANAGER`
  /// يصل إلى «مدير المحاسبة» بكتابته.
  List<RoleCatalogItem> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return widget.roles;
    return widget.roles
        .where((r) =>
            r.name.toLowerCase().contains(q) ||
            r.code.toLowerCase().contains(q))
        .toList();
  }

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

    _triggerWidth = box != null && box.hasSize ? box.size.width : null;
    _flip = below < _kMinPanelHeight && above > below;
    _maxHeight = ((_flip ? above : below) - 16)
        .clamp(_kMinPanelHeight, _kMaxPanelHeight)
        .toDouble();
  }

  void _open() {
    _searchCtrl.clear();
    setState(() => _query = '');
    _measurePlacement();
    _controller.show();
    // التركيز بعد الإطار الأول: الحقل لم يُركَّب بعد لحظة النداء.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _controller.isShowing) _searchFocus.requestFocus();
    });
  }

  void _close() {
    _searchFocus.unfocus();
    _controller.hide();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _link,
      child: OverlayPortal(
        controller: _controller,
        overlayChildBuilder: _buildPanel,
        child: _Trigger(
          label: _selected?.name,
          hint: widget.hint,
          errorText: widget.errorText,
          open: _controller.isShowing,
          onTap: () => _controller.isShowing ? _close() : _open(),
        ),
      ),
    );
  }

  Widget _buildPanel(BuildContext context) {
    final flip = _flip;

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
                width: _triggerWidth,
                maxHeight: _maxHeight,
                searchCtrl: _searchCtrl,
                searchFocus: _searchFocus,
                results: _filtered,
                selectedId: widget.value,
                hasQuery: _query.trim().isNotEmpty,
                onQuery: (q) => setState(() => _query = q),
                onPicked: (r) {
                  widget.onChanged(r.id);
                  _close();
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}

const double _kMinPanelHeight = 220;
const double _kMaxPanelHeight = 340;

// ════════════════════════════ الحقل ════════════════════════════

class _Trigger extends StatelessWidget {
  const _Trigger({
    required this.label,
    required this.hint,
    required this.errorText,
    required this.open,
    required this.onTap,
  });

  final String? label;
  final String hint;
  final String? errorText;
  final bool open;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasError = errorText != null;
    final borderColor = hasError
        ? AppColors.error
        : (open ? AppColors.primary : AppColors.border);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          child: Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(AppRadius.sm),
              border: Border.all(color: borderColor, width: open ? 1.4 : 1),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label ?? hint,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: label == null
                          ? AppColors.textSecondary
                          : AppColors.textPrimary,
                    ),
                  ),
                ),
                AnimatedRotation(
                  turns: open ? .5 : 0,
                  duration: const Duration(milliseconds: 160),
                  child: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Text(
              errorText!,
              style: AppTextStyles.caption.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ],
    );
  }
}

// ════════════════════════════ اللوحة ════════════════════════════

class _Panel extends StatelessWidget {
  const _Panel({
    required this.width,
    required this.maxHeight,
    required this.searchCtrl,
    required this.searchFocus,
    required this.results,
    required this.selectedId,
    required this.hasQuery,
    required this.onQuery,
    required this.onPicked,
  });

  final double? width;
  final double maxHeight;
  final TextEditingController searchCtrl;
  final FocusNode searchFocus;
  final List<RoleCatalogItem> results;
  final int? selectedId;
  final bool hasQuery;
  final ValueChanged<String> onQuery;
  final ValueChanged<RoleCatalogItem> onPicked;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.transparent,
      child: Container(
        width: width,
        constraints: BoxConstraints(maxHeight: maxHeight),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.border),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadowMedium,
              blurRadius: 22,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: TextField(
                controller: searchCtrl,
                focusNode: searchFocus,
                onChanged: onQuery,
                textAlign: TextAlign.right,
                style: AppTextStyles.bodyMedium,
                decoration: InputDecoration(
                  isDense: true,
                  hintText: 'ابحث عن دور...',
                  hintStyle: AppTextStyles.bodySmall,
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    size: 20,
                    color: AppColors.textSecondary,
                  ),
                  prefixIconConstraints: const BoxConstraints(
                    minWidth: 38,
                    minHeight: 38,
                  ),
                  filled: true,
                  fillColor: AppColors.inputBackground,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.md,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const Divider(height: 1, color: AppColors.borderLight),
            Flexible(
              child: results.isEmpty
                  ? const _EmptyResults()
                  : ListView.builder(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.xs,
                      ),
                      itemCount: results.length,
                      itemBuilder: (context, i) {
                        final r = results[i];
                        return _RoleTile(
                          role: r,
                          selected: r.id == selectedId,
                          onTap: () => onPicked(r),
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

class _RoleTile extends StatelessWidget {
  const _RoleTile({
    required this.role,
    required this.selected,
    required this.onTap,
  });

  final RoleCatalogItem role;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        color: selected ? AppColors.lightPrimary : AppColors.transparent,
        child: Row(
          children: [
            Expanded(
              child: Text(
                role.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodyMedium.copyWith(
                  color:
                      selected ? AppColors.primary : AppColors.textPrimary,
                  fontWeight:
                      selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
            if (selected)
              const Icon(
                Icons.check_rounded,
                size: 18,
                color: AppColors.primary,
              ),
          ],
        ),
      ),
    );
  }
}

class _EmptyResults extends StatelessWidget {
  const _EmptyResults();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.xxl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 28,
            color: AppColors.iconMuted,
          ),
          SizedBox(height: AppSpacing.sm),
          Text('لا توجد نتائج مطابقة', style: AppTextStyles.bodySmall),
        ],
      ),
    );
  }
}
