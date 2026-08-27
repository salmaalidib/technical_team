import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_dimens.dart';
import '../../theme/app_text_styles.dart';
import 'data_table_config.dart';

/// شريط ترقيم مشترك لجداول التطبيق.
///
/// مبني يدوياً بدل [SfDataPager] لأن الأخير يفرض تخطيطاً LTR وتسميات
/// إنجليزية لا يمكن تعريبها، ولا يسمح بضبط أشكال الأزرار والمسافات.
///
/// مخصّص للترقيم من جهة الخادم: [pageNumber] رقم الصفحة الحالي (يبدأ من 1)،
/// و[total] إجمالي العناصر، و[pageSize] حجم الصفحة. عند التنقّل أو تغيير
/// الحجم يُستدعى الـ callback المناسب — الجهة المستدعية تُطلق حدث الـ BLoC.
class DataPagerWidget extends StatelessWidget {
  /// مصدر بيانات الجدول. يقبل null أثناء التحميل الأول.
  final DataGridSource? dataSource;

  /// رقم الصفحة الحالي كما يعيده الخادم (يبدأ من 1).
  final int pageNumber;

  /// عدد الصفوف المعروضة في الصفحة.
  final int pageSize;

  /// إجمالي عدد العناصر عبر كل الصفحات.
  final int total;

  /// يُستدعى مع رقم الصفحة الجديد (يبدأ من 1) عند التنقّل.
  final ValueChanged<int> onPageChanged;

  /// يُستدعى مع حجم الصفحة الجديد عند تغييره.
  final ValueChanged<int> onPageSizeChanged;

  const DataPagerWidget({
    super.key,
    required this.dataSource,
    required this.pageNumber,
    required this.pageSize,
    required this.total,
    required this.onPageChanged,
    required this.onPageSizeChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (dataSource == null || total == 0) {
      return const SizedBox.shrink();
    }

    final pageCount = (total / pageSize).ceil().clamp(1, 1 << 30);
    final current = pageNumber.clamp(1, pageCount);
    final firstRow = (current - 1) * pageSize + 1;
    final lastRow = (current * pageSize).clamp(0, total);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.md,
      ),
      decoration: const BoxDecoration(
        // خلفية مميّزة بدل حدّ علوي: آخر صف في الجدول يرسم خطّه السفلي
        // أصلاً، فإضافة حدّ هنا كانت تُنتج خطّين ملتصقين.
        color: AppColors.surfaceMuted,
      ),
      child: Row(
        children: [
          _RowsPerPage(
            value: pageSize,
            onChanged: onPageSizeChanged,
          ),
          const SizedBox(width: AppSpacing.xl),
          // ملخّص النطاق المعروض — أوضح للمستخدم من رقم الصفحة وحده.
          Expanded(
            child: Text(
              'عرض $firstRow–$lastRow من $total',
              style: AppTextStyles.bodySmall,
            ),
          ),
          _Nav(
            current: current,
            pageCount: pageCount,
            onPageChanged: onPageChanged,
          ),
        ],
      ),
    );
  }
}

/// مُنتقي عدد الصفوف لكل صفحة.
class _RowsPerPage extends StatelessWidget {
  const _RowsPerPage({required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('صفوف لكل صفحة', style: AppTextStyles.bodySmall),
        const SizedBox(width: AppSpacing.sm),
        Container(
          // ارتفاع أدنى بدل ارتفاع ثابت: الثابت كان يقصّ نزول الأرقام.
          constraints: const BoxConstraints(minHeight: 36),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: AppColors.surfaceAlt,
            borderRadius: AppRadius.allSm,
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: value,
              isDense: true,
              borderRadius: AppRadius.allSm,
              focusColor: AppColors.transparent,
              icon: const Padding(
                padding: EdgeInsets.only(right: AppSpacing.xs),
                child: Icon(Icons.keyboard_arrow_down_rounded,
                    size: 18, color: AppColors.textSecondary),
              ),
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
              items: [
                for (final size in DataTableConfigs.pageSizes)
                  DropdownMenuItem(value: size, child: Text('$size')),
              ],
              onChanged: (v) {
                if (v != null && v != value) onChanged(v);
              },
            ),
          ),
        ),
      ],
    );
  }
}

/// أزرار التنقّل بين الصفحات.
class _Nav extends StatelessWidget {
  const _Nav({
    required this.current,
    required this.pageCount,
    required this.onPageChanged,
  });

  final int current;
  final int pageCount;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // في RTL الاتجاه البصري معكوس: "السابق" يشير لليمين.
        _ArrowButton(
          icon: Icons.keyboard_arrow_right_rounded,
          tooltip: 'الصفحة السابقة',
          onTap: current > 1 ? () => onPageChanged(current - 1) : null,
        ),
        const SizedBox(width: AppSpacing.xs),
        for (final page in _pageWindow(current, pageCount)) ...[
          if (page == null)
            const _Ellipsis()
          else
            _PageButton(
              page: page,
              selected: page == current,
              onTap: () => onPageChanged(page),
            ),
          const SizedBox(width: AppSpacing.xs),
        ],
        _ArrowButton(
          icon: Icons.keyboard_arrow_left_rounded,
          tooltip: 'الصفحة التالية',
          onTap: current < pageCount ? () => onPageChanged(current + 1) : null,
        ),
      ],
    );
  }

  /// نافذة الصفحات المعروضة: تُبقي الأولى والأخيرة ظاهرتين دائماً وتختصر
  /// ما بينهما بـ «…» كي لا يطول الشريط مع كثرة الصفحات.
  static List<int?> _pageWindow(int current, int pageCount) {
    if (pageCount <= 7) {
      return [for (var i = 1; i <= pageCount; i++) i];
    }
    if (current <= 4) {
      return [1, 2, 3, 4, 5, null, pageCount];
    }
    if (current >= pageCount - 3) {
      return [
        1,
        null,
        pageCount - 4,
        pageCount - 3,
        pageCount - 2,
        pageCount - 1,
        pageCount,
      ];
    }
    return [1, null, current - 1, current, current + 1, null, pageCount];
  }
}

class _PageButton extends StatelessWidget {
  const _PageButton({
    required this.page,
    required this.selected,
    required this.onTap,
  });

  final int page;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primary : AppColors.transparent,
      borderRadius: AppRadius.allSm,
      child: InkWell(
        onTap: selected ? null : onTap,
        borderRadius: AppRadius.allSm,
        hoverColor: AppColors.lightPrimary,
        child: Container(
          constraints: const BoxConstraints(minWidth: 34),
          height: 34,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: Text(
            '$page',
            style: AppTextStyles.bodySmall.copyWith(
              color: selected ? AppColors.white : AppColors.textPrimary,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _ArrowButton extends StatelessWidget {
  const _ArrowButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;

  /// null يعني معطّل (بداية/نهاية القائمة).
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: AppColors.transparent,
        borderRadius: AppRadius.allSm,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.allSm,
          hoverColor: AppColors.lightPrimary,
          child: Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            child: Icon(
              icon,
              size: 20,
              color: enabled ? AppColors.textPrimary : AppColors.iconMuted,
            ),
          ),
        ),
      ),
    );
  }
}

class _Ellipsis extends StatelessWidget {
  const _Ellipsis();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 24,
      height: 34,
      child: Center(
        child: Text('…', style: AppTextStyles.bodySmall),
      ),
    );
  }
}
