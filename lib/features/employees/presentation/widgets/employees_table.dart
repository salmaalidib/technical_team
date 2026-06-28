import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syncfusion_flutter_core/theme.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/table/data_pager_widget.dart';
import '../../../../shared/widgets/table/grid_column.dart';
import '../bloc/employees_bloc.dart';
import '../bloc/employees_event.dart';
import '../bloc/employees_state.dart';
import 'employee_dialogs.dart';
import 'employees_data_source.dart';

/// جدول الموظفين مبني على [SfDataGrid] مع ترقيم من جهة الخادم عبر
/// [DataPagerWidget]. يقرأ الصفحة الحالية وحجمها والإجمالي من حالة الـ BLoC،
/// ويطلق [LoadEmployees] عند تغيّر الصفحة أو حجمها.
class EmployeesTable extends StatefulWidget {
  final EmployeesState state;

  const EmployeesTable({super.key, required this.state});

  @override
  State<EmployeesTable> createState() => _EmployeesTableState();
}

class _EmployeesTableState extends State<EmployeesTable> {
  late EmployeesDataSource _dataSource;

  @override
  void initState() {
    super.initState();
    _dataSource = _buildSource();
  }

  @override
  void didUpdateWidget(covariant EmployeesTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    // حدّث الصفوف في نفس المصدر (دون إنشاء مصدر جديد) للحفاظ على تزامن
    // الـ pager عند وصول صفحة جديدة من الخادم.
    if (oldWidget.state.employees != widget.state.employees) {
      _dataSource.updateData(widget.state.employees);
    }
  }

  EmployeesDataSource _buildSource() {
    return EmployeesDataSource(
      employees: widget.state.employees,
      onView: (e) => showEmployeeDetails(context, e),
      onEdit: (e) => showEmployeeEditor(context, e),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final bloc = context.read<EmployeesBloc>();

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
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
                headerColor: Color(0xffF0EFE7),
                gridLineColor: AppColors.border,
              ),
              child: SfDataGrid(
                source: _dataSource,
                rowHeight: 72,
                headerRowHeight: 56,
                // يربط الجدول بالـ pager. الخادم يرسل صفحة واحدة (= limit)،
                // لذا نعرض كل الصفوف الواصلة.
                rowsPerPage: state.limit,
                gridLinesVisibility: GridLinesVisibility.horizontal,
                headerGridLinesVisibility: GridLinesVisibility.horizontal,
                columnWidthMode: ColumnWidthMode.fill,
                columns: _columns,
              ),
            ),
          ),
          DataPagerWidget(
            dataSource: _dataSource,
            pageNumber: state.page,
            pageSize: state.limit,
            total: state.total,
            onPageChanged: (page) => bloc.add(LoadEmployees(page: page)),
            onPageSizeChanged: (size) =>
                bloc.add(LoadEmployees(page: 1, limit: size)),
          ),
        ],
      ),
    );
  }

  List<GridColumn> get _columns => [
        buildGridColumn(columnName: 'name', label: 'اسم الموظف'),
        buildGridColumn(columnName: 'userName', label: 'اسم المستخدم'),
        buildGridColumn(columnName: 'email', label: 'البريد الإلكتروني'),
        buildGridColumn(columnName: 'phone', label: 'الهاتف', width: 130),
        buildGridColumn(columnName: 'department', label: 'الدائرة'),
        buildGridColumn(columnName: 'role', label: 'الدور'),
        buildGridColumn(
          columnName: 'status',
          label: 'الحالة',
          width: 120,
          alignment: Alignment.center,
        ),
        buildGridColumn(
          columnName: 'actions',
          label: 'الإجراءات',
          width: 140,
          alignment: Alignment.center,
        ),
      ];
}
