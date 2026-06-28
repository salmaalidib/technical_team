import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_core/theme.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';

import '../../theme/app_colors.dart';
import 'data_table_config.dart';

/// شريط ترقيم مشترك مبني على [SfDataPager].
///
/// مخصّص للترقيم من جهة الخادم: [pageNumber] هو رقم الصفحة الحالي (يبدأ من 1)،
/// و[total] إجمالي عدد العناصر، و[pageSize] حجم الصفحة. عند تغيّر الصفحة أو حجمها
/// يُستدعى الـ callback المناسب — تتكفّل الجهة المستدعية بإطلاق حدث الـ BLoC
/// لجلب البيانات الجديدة.
class DataPagerWidget extends StatelessWidget {
  /// مصدر بيانات الجدول (delegate الخاص بالـ pager). يقبل null أثناء التحميل
  /// الأول قبل توفّر أي بيانات.
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

    final pageCount = (total / pageSize).ceil().toDouble();

    return Directionality(
      // الـ pager يتعامل مع الفهارس من اليسار لليمين داخلياً؛ نُبقيه LTR ليبقى
      // ترتيب الأسهم وأرقام الصفحات متّسقاً.
      textDirection: TextDirection.ltr,
      child: Container(
        height: 70,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(
            top: BorderSide(color: AppColors.border),
          ),
        ),
        child: SfDataPagerTheme(
          data: const SfDataPagerThemeData(
            selectedItemColor: AppColors.primary,
            selectedItemTextStyle: TextStyle(
              color: Colors.white,
              fontFamily: 'Cairo',
              fontWeight: FontWeight.w700,
            ),
            itemColor: AppColors.surface,
            itemTextStyle: TextStyle(
              color: AppColors.textPrimary,
              fontFamily: 'Cairo',
            ),
          ),
          child: SfDataPager(
            delegate: dataSource!,
            // SfDataPager يستخدم فهرساً يبدأ من 0.
            initialPageIndex: (pageNumber - 1).clamp(0, 1 << 30),
            pageCount: pageCount < 1 ? 1 : pageCount,
            availableRowsPerPage: DataTableConfigs.pageSizes,
            onRowsPerPageChanged: (int? newPageSize) {
              if (newPageSize != null && newPageSize != pageSize) {
                onPageSizeChanged(newPageSize);
              }
            },
            onPageNavigationEnd: (int pageIndex) {
              final newPage = pageIndex + 1;
              if (newPage != pageNumber) {
                onPageChanged(newPage);
              }
            },
          ),
        ),
      ),
    );
  }
}
