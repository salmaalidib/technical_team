import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syncfusion_flutter_core/theme.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import '../../../../shared/widgets/table/grid_font_scope.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/table/data_pager_widget.dart';
import '../../../../shared/widgets/table/grid_column.dart';
import '../../domain/entities/department.dart';
import '../bloc/departments_bloc.dart';
import '../bloc/departments_event.dart';
import '../bloc/departments_state.dart';
import 'department_details_dialog.dart';
import 'departments_data_source.dart';
import '../../../../shared/theme/app_dimens.dart';

/// جدول الأقسام مبني على [SfDataGrid] بنفس تصميم جدول الموظفين. الترقيم من جهة
/// العميل داخل المستوى الحالي (الجذور أو شعب قسم)، عبر [DataPagerWidget].
class DepartmentsTable extends StatefulWidget {
  final DepartmentsState state;

  const DepartmentsTable({super.key, required this.state});

  @override
  State<DepartmentsTable> createState() => _DepartmentsTableState();
}

class _DepartmentsTableState extends State<DepartmentsTable> {
  late DepartmentsDataSource _dataSource;

  @override
  void initState() {
    super.initState();
    _dataSource = _buildSource();
  }

  @override
  void didUpdateWidget(covariant DepartmentsTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    final old = oldWidget.state;
    final now = widget.state;
    // أعد بناء الصفوف عند تغيّر محتوى المستوى، البحث، حجم الصفحة، أو حالة
    // التبديل (لتحديث زر الحالة). نُبقي نفس المصدر حفاظاً على تزامن الـ pager.
    if (old.levelDepartments != now.levelDepartments ||
        old.pageSize != now.pageSize ||
        old.togglingIds != now.togglingIds) {
      _dataSource.updateData(now.levelDepartments, pageSize: now.pageSize);
    }
  }

  DepartmentsDataSource _buildSource() {
    final bloc = context.read<DepartmentsBloc>();
    return DepartmentsDataSource(
      departments: widget.state.levelDepartments,
      pageSize: widget.state.pageSize,
      onOpenChildren: (d) => bloc.add(
        NavigateToChildren(parentId: d.id, parentName: d.name),
      ),
      onView: (d) => DepartmentDetailsDialog.show(context, d),
      onToggleStatus: _confirmAndToggle,
      isToggling: (d) =>
          context.read<DepartmentsBloc>().state.togglingIds.contains(d.id),
    );
  }

  /// اطلب تأكيداً قبل تفعيل/تعطيل القسم — الإجراء كان يُنفَّذ فوراً عند الضغط.
  Future<void> _confirmAndToggle(Department department) async {
    final activate = !department.isActive;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          // الحوار يتمدّد افتراضياً لعرض الشاشة — قيّده ليبقى مضغوطاً.
          contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
          title: Text(
            activate ? 'تفعيل القسم' : 'تعطيل القسم',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Text(
              activate
                  ? 'سيتم تفعيل القسم «${department.name}» وإتاحته للاستخدام. متابعة؟'
                  : 'سيتم تعطيل القسم «${department.name}» وإيقاف استخدامه. متابعة؟',
              style: const TextStyle(fontSize: 14, height: 1.6),
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              style: TextButton.styleFrom(
                minimumSize: const Size(96, 42),
                foregroundColor: AppColors.textSecondary,
              ),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: activate ? AppColors.primary : AppColors.error,
                foregroundColor: AppColors.white,
                // ألغِ عرض double.infinity القادم من الثيم العام.
                minimumSize: const Size(112, 42),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(activate ? 'تفعيل' : 'تعطيل'),
            ),
          ],
        ),
      ),
    );

    if (ok == true && mounted) {
      context
          .read<DepartmentsBloc>()
          .add(ToggleDepartmentStatus(department.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final bloc = context.read<DepartmentsBloc>();
    final total = state.levelDepartments.length;

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
            child: GridFontScope(
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
        buildGridColumn(columnName: 'name', label: 'اسم القسم'),
        buildGridColumn(columnName: 'organization', label: 'المؤسسة'),
        buildGridColumn(
          columnName: 'status',
          label: 'الحالة',
          width: 130,
          alignment: Alignment.center,
        ),
        buildGridColumn(
          columnName: 'actions',
          label: 'الإجراءات',
          width: 180,
          alignment: Alignment.center,
        ),
      ];
}
