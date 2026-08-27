import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syncfusion_flutter_core/theme.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_dimens.dart';
import '../../../../shared/widgets/table/data_pager_widget.dart';
import '../../../../shared/widgets/table/grid_column.dart';
import '../bloc/institutions_bloc.dart';
import '../bloc/institutions_event.dart';
import '../bloc/institutions_state.dart';
import 'institutions_data_source.dart';

/// جدول المؤسسات مبني على [SfDataGrid] بنفس تصميم جدول الأقسام. الترقيم من جهة
/// العميل داخل المستوى الحالي (الجذور أو المؤسسات التابعة)، عبر
/// [DataPagerWidget].
class InstitutionsTable extends StatefulWidget {
  final InstitutionsState state;

  const InstitutionsTable({super.key, required this.state});

  @override
  State<InstitutionsTable> createState() => _InstitutionsTableState();
}

class _InstitutionsTableState extends State<InstitutionsTable> {
  late InstitutionsDataSource _dataSource;

  @override
  void initState() {
    super.initState();
    _dataSource = _buildSource();
  }

  @override
  void didUpdateWidget(covariant InstitutionsTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    final old = oldWidget.state;
    final now = widget.state;
    // أعد بناء الصفوف عند تغيّر محتوى المستوى أو حجم الصفحة. نُبقي نفس المصدر
    // حفاظاً على تزامن الـ pager.
    if (old.levelInstitutions != now.levelInstitutions ||
        old.pageSize != now.pageSize) {
      _dataSource.updateData(now.levelInstitutions, pageSize: now.pageSize);
    }
  }

  InstitutionsDataSource _buildSource() {
    final bloc = context.read<InstitutionsBloc>();
    return InstitutionsDataSource(
      institutions: widget.state.levelInstitutions,
      pageSize: widget.state.pageSize,
      onOpenChildren: (i) => bloc.add(
        NavigateToChildren(parentId: i.id, parentName: i.name),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final bloc = context.read<InstitutionsBloc>();
    final total = state.levelInstitutions.length;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowSoft,
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Expanded(
            child: SfDataGridTheme(
              data: const SfDataGridThemeData(
                headerColor: AppColors.surfaceAlt,
                gridLineColor: AppColors.border,
              ),
              child: SfDataGrid(
                source: _dataSource,
                rowHeight: 72,
                headerRowHeight: 56,
                rowsPerPage: state.pageSize,
                gridLinesVisibility: GridLinesVisibility.horizontal,
                headerGridLinesVisibility: GridLinesVisibility.horizontal,
                columnWidthMode: ColumnWidthMode.fill,
                columns: _columns,
              ),
            ),
          ),
          DataPagerWidget(
            dataSource: _dataSource,
            pageNumber: state.currentPage,
            pageSize: state.pageSize,
            total: total,
            onPageChanged: (page) => bloc.add(PageChanged(page)),
            onPageSizeChanged: (size) => bloc.add(PageSizeChanged(size)),
          ),
        ],
      ),
    );
  }

  List<GridColumn> get _columns => [
        buildGridColumn(columnName: 'id', label: '#', width: 90),
        buildGridColumn(columnName: 'name', label: 'اسم المؤسسة'),
        buildGridColumn(columnName: 'parent', label: 'المؤسسة الأم'),
        buildGridColumn(columnName: 'location', label: 'الموقع'),
        buildGridColumn(
          columnName: 'actions',
          label: 'الإجراءات',
          width: 140,
          alignment: Alignment.center,
        ),
      ];
}
