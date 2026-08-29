import 'package:flutter/material.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_dimens.dart';
import 'process_animations.dart';
import '../../../../shared/theme/app_text_styles.dart';

/// Shared, styled building blocks for the create-process wizard, matching the
/// look of the existing create dialogs (roles / employees).

class WizardLabel extends StatelessWidget {
  final String text;
  const WizardLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.right,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 15,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class WizardSectionTitle extends StatelessWidget {
  final String text;
  const WizardSectionTitle(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.right,
      style: const TextStyle(
        color: AppColors.primary,
        fontSize: 18,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class WizardTextInput extends StatelessWidget {
  final TextEditingController? controller;
  final String hint;
  final String? errorText;
  final TextDirection? textDirection;
  final ValueChanged<String>? onChanged;

  const WizardTextInput({
    super.key,
    this.controller,
    required this.hint,
    this.errorText,
    this.textDirection,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      textAlign: TextAlign.right,
      textDirection: textDirection ?? TextDirection.rtl,
      decoration: _wizardInputDecoration(hint: hint, errorText: errorText),
    );
  }
}

/// قائمة منسدلة قابلة للبحث — نفس واجهة الاستدعاء القديمة
/// (`hint` / `value` / `items` / `onChanged` / `errorText` / `enabled`)، لكن
/// القائمة تُفتح كلوحة Overlay تحوي حقل بحث بدل قائمة Material الثابتة.
///
/// السبب: قوائم المؤسسات والأقسام والأدوار تصل إلى عشرات العناصر، وكان
/// التمرير هو الطريقة الوحيدة للوصول إلى عنصر. اللوحة هنا:
///
/// * تُصفّي محلياً (كل العناصر محمّلة في `items` أصلاً)؛
/// * تُقاس المساحة حول الحقل فتنقلب للأعلى عند ضيق الأسفل بدل الخروج من الشاشة؛
/// * تُبرز نص البحث داخل الاسم المطابق.
class WizardDropdown<T> extends StatefulWidget {
  final String hint;
  final T? value;
  final Map<T, String> items;
  final ValueChanged<T?> onChanged;
  final String? errorText;
  final bool enabled;

  /// نص حقل البحث داخل اللوحة.
  final String? searchHint;

  const WizardDropdown({
    super.key,
    required this.hint,
    required this.value,
    required this.items,
    required this.onChanged,
    this.errorText,
    this.enabled = true,
    this.searchHint,
  });

  @override
  State<WizardDropdown<T>> createState() => _WizardDropdownState<T>();
}

class _WizardDropdownState<T> extends State<WizardDropdown<T>> {
  final _portal = OverlayPortalController();
  final _link = LayerLink();
  final _searchCtrl = TextEditingController();

  /// يُحسم موضع اللوحة عند الفتح ويبقى ثابتاً حتى الإغلاق — النموذج المضيف قد
  /// ينمو أثناء فتح اللوحة (ظهور سطر خطأ، إضافة شريحة) وإعادة الحساب تجعلها
  /// تقفز.
  bool _flip = false;
  double _maxHeight = _kWizardMaxPanelHeight;
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
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

    _flip = below < _kWizardMinPanelHeight && above > below;
    _maxHeight = ((_flip ? above : below) - 16)
        .clamp(_kWizardMinPanelHeight, _kWizardMaxPanelHeight)
        .toDouble();
  }

  void _open() {
    if (!widget.enabled) return;
    _searchCtrl.clear();
    _query = '';
    _measurePlacement();
    _portal.show();
    // الحدّ والسهم في الحقل يعكسان حالة الفتح، وإظهار الـ overlay وحده لا
    // يُعيد بناء هذا الودجت.
    setState(() {});
  }

  void _close() {
    _portal.hide();
    if (mounted) setState(() {});
  }

  List<MapEntry<T, String>> get _filtered {
    final q = _query.trim().toLowerCase();
    final entries = widget.items.entries.toList();
    if (q.isEmpty) return entries;
    return entries.where((e) => e.value.toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    // قيمة لم تعد ضمن [items] (أعيد تحميل الأقسام بعد تغيير المؤسسة مثلاً) يجب
    // ألّا تُبقي اسماً قديماً معروضاً.
    final selectedLabel = widget.items[widget.value];

    return CompositedTransformTarget(
      link: _link,
      child: OverlayPortal(
        controller: _portal,
        overlayChildBuilder: _buildPanel,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _WizardDropdownTrigger(
              hint: widget.hint,
              label: selectedLabel,
              enabled: widget.enabled,
              hasError: widget.errorText != null,
              open: _portal.isShowing,
              onTap: () => _portal.isShowing ? _close() : _open(),
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
              child: _WizardDropdownPanel<T>(
                maxHeight: _maxHeight,
                // بعرض الحقل نفسه لتقرأ اللوحة كجزء منه لا كصندوق عائم.
                width: _triggerWidth(),
                searchCtrl: _searchCtrl,
                searchHint: widget.searchHint ?? 'ابحث...',
                query: _query,
                onQueryChanged: (q) => setState(() => _query = q),
                entries: _filtered,
                selected: widget.value,
                onPicked: (v) {
                  widget.onChanged(v);
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

/// لا تصغر اللوحة عن هذا الحد — أقل منه لا يتسع لحقل البحث وسطرين.
const double _kWizardMinPanelHeight = 220;
const double _kWizardMaxPanelHeight = 340;

/// الحقل المغلق — يحاكي شكل `_wizardInputDecoration` نفسه.
class _WizardDropdownTrigger extends StatelessWidget {
  final String hint;
  final String? label;
  final bool enabled;
  final bool hasError;
  final bool open;
  final VoidCallback onTap;

  const _WizardDropdownTrigger({
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
        : (open || hasSelection)
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
          color: enabled ? AppColors.white : AppColors.inputBackground,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(
            color: enabled ? borderColor : AppColors.border,
            width: (open || hasSelection) && !hasError ? 1.4 : 1.0,
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
                  fontSize: 15,
                  color: hasSelection && enabled
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                  fontWeight:
                      hasSelection ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
            AnimatedRotation(
              duration: const Duration(milliseconds: 150),
              turns: open ? 0.5 : 0,
              child: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: enabled ? AppColors.textSecondary : AppColors.iconMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WizardDropdownPanel<T> extends StatelessWidget {
  final double maxHeight;
  final double? width;
  final TextEditingController searchCtrl;
  final String searchHint;
  final String query;
  final ValueChanged<String> onQueryChanged;
  final List<MapEntry<T, String>> entries;
  final T? selected;
  final ValueChanged<T> onPicked;

  const _WizardDropdownPanel({
    required this.maxHeight,
    required this.width,
    required this.searchCtrl,
    required this.searchHint,
    required this.query,
    required this.onQueryChanged,
    required this.entries,
    required this.selected,
    required this.onPicked,
  });

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context).size;
    // يتبع عرض الحقل، لكنه لا يتجاوز نافذة ضيّقة.
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
            _WizardDropdownSearchBar(
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
                  ? _WizardDropdownEmpty(query: query)
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      shrinkWrap: true,
                      itemCount: entries.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 2),
                      itemBuilder: (context, i) {
                        final e = entries[i];
                        return _WizardDropdownRow(
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

class _WizardDropdownSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _WizardDropdownSearchBar({
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
          fillColor: AppColors.inputBackground,
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

class _WizardDropdownRow extends StatelessWidget {
  final String label;
  final String query;
  final bool selected;
  final VoidCallback onTap;

  const _WizardDropdownRow({
    required this.label,
    required this.query,
    required this.selected,
    required this.onTap,
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
              child: _WizardHighlightedText(
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

/// يعرض [text] مع إبراز الجزء المطابق لـ [query].
class _WizardHighlightedText extends StatelessWidget {
  final String text;
  final String query;
  final bool selected;

  const _WizardHighlightedText({
    required this.text,
    required this.query,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    // fontFamily صريح: هذا النمط يُستخدم داخل RichText أدناه، وهو لا يرث
    // DefaultTextStyle كما يفعل Text.
    final base = TextStyle(
      fontFamily: AppTextStyles.fontFamily,
      fontSize: 14,
      color: AppColors.textPrimary,
      fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
    );

    final q = query.trim().toLowerCase();
    final idx = q.isEmpty ? -1 : text.toLowerCase().indexOf(q);

    if (idx < 0) {
      return Text(
        text,
        textAlign: TextAlign.right,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: base,
      );
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

class _WizardDropdownEmpty extends StatelessWidget {
  final String query;
  const _WizardDropdownEmpty({required this.query});

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

/// Tappable date field — opens the platform date picker. Only month/day matter
/// to the backend, but the full date is shown for clarity.
class WizardDateField extends StatelessWidget {
  final DateTime? value;
  final String hint;
  final String? errorText;
  final ValueChanged<DateTime> onPicked;

  const WizardDateField({
    super.key,
    required this.value,
    required this.hint,
    required this.onPicked,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    final text =
        value == null ? hint : '${value!.day}/${value!.month}/${value!.year}';

    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.sm),
      onTap: () async {
        final now = DateTime.now();
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? now,
          firstDate: DateTime(now.year - 1),
          lastDate: DateTime(now.year + 5),
        );
        if (picked != null) onPicked(picked);
      },
      child: InputDecorator(
        decoration: _wizardInputDecoration(hint: null, errorText: errorText),
        child: Row(
          textDirection: TextDirection.rtl,
          children: [
            Expanded(
              child: Text(
                text,
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 15,
                  color: value == null
                      ? AppColors.textSecondary
                      : AppColors.textPrimary,
                ),
              ),
            ),
            const Icon(Icons.calendar_today_rounded,
                size: 18, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

InputDecoration _wizardInputDecoration({String? hint, String? errorText}) {
  return InputDecoration(
    hintText: hint,
    errorText: errorText,
    filled: true,
    fillColor: AppColors.white,
    hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 15),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.sm),
      borderSide: const BorderSide(color: AppColors.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.sm),
      borderSide: const BorderSide(color: AppColors.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.sm),
      borderSide: const BorderSide(color: AppColors.primary),
    ),
  );
}

/// The 4-step progress header (RTL: step 1 on the right).
class WizardStepper extends StatelessWidget {
  final int currentStep;
  final List<String> titles;

  const WizardStepper({
    super.key,
    required this.currentStep,
    required this.titles,
  });

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    for (var i = 0; i < titles.length; i++) {
      final step = i + 1;
      children.add(_StepNode(
        step: step,
        title: titles[i],
        state: step < currentStep
            ? _NodeState.done
            : (step == currentStep ? _NodeState.current : _NodeState.upcoming),
      ));
      if (i < titles.length - 1) {
        children.add(Expanded(
          // الوصلة تمتلئ باللون تدريجياً بدل أن تنقلب دفعة واحدة.
          child: _StepConnector(done: step < currentStep),
        ));
      }
    }

    return Row(
      textDirection: TextDirection.rtl,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }
}

enum _NodeState { done, current, upcoming }

class _StepNode extends StatelessWidget {
  final int step;
  final String title;
  final _NodeState state;

  const _StepNode({
    required this.step,
    required this.title,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final isUpcoming = state == _NodeState.upcoming;
    final isCurrent = state == _NodeState.current;
    final circleColor =
        isUpcoming ? AppColors.inputBackground : AppColors.primary;
    final textColor = isUpcoming ? AppColors.textSecondary : AppColors.primary;

    return SizedBox(
      width: 96,
      child: Column(
        children: [
          // الخطوة الحالية تكبر قليلاً وتُحاط بهالة، فيُقرأ التقدّم كحركة
          // واحدة متصلة عبر شريط الخطوات.
          AnimatedScale(
            duration: AppMotion.normal,
            curve: AppMotion.curve,
            scale: isCurrent ? 1.08 : 1,
            child: AnimatedContainer(
              duration: AppMotion.normal,
              curve: AppMotion.curve,
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: circleColor,
                shape: BoxShape.circle,
                boxShadow: isCurrent
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.28),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : const [],
              ),
              alignment: Alignment.center,
              child: AnimatedSwitcher(
                duration: AppMotion.fast,
                transitionBuilder: (child, animation) =>
                    ScaleTransition(scale: animation, child: child),
                child: state == _NodeState.done
                    ? const Icon(Icons.check_rounded,
                        key: ValueKey('done'), color: AppColors.white, size: 24)
                    : Text(
                        '$step',
                        key: ValueKey('n$step-$isUpcoming'),
                        style: TextStyle(
                          color: isUpcoming
                              ? AppColors.textSecondary
                              : AppColors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          AnimatedDefaultTextStyle(
            duration: AppMotion.normal,
            curve: AppMotion.curve,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textColor,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
            child: Text(title, textAlign: TextAlign.center, maxLines: 2),
          ),
        ],
      ),
    );
  }
}

/// الوصلة بين عقدتي خطوة — تمتلئ باللون من جهة البداية (اليمين في RTL).
class _StepConnector extends StatelessWidget {
  final bool done;

  const _StepConnector({required this.done});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 2,
      margin: const EdgeInsets.only(bottom: 28),
      color: AppColors.border,
      child: AnimatedFractionallySizedBox(
        duration: AppMotion.normal,
        curve: AppMotion.curve,
        alignment: AlignmentDirectional.centerStart,
        widthFactor: done ? 1 : 0,
        child: const ColoredBox(color: AppColors.primary),
      ),
    );
  }
}
