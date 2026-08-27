import 'package:flutter/material.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_dimens.dart';
import '../../domain/entities/audit_log_entry.dart';
import 'audit_log_details_dialog.dart';
import 'audit_log_format.dart';
import 'audit_log_status_badge.dart';

/// جدول السجلات. أعمدة بعرض ثابت داخل تمرير أفقي: محتوى الخانات (وكيل
/// المستخدم، معرّفات الموارد) متفاوت الطول ويكسر أي تخطيط مرن.
class AuditLogsTable extends StatelessWidget {
  final List<AuditLogEntry> items;

  const AuditLogsTable({super.key, required this.items});

  static const _columns = <_Column>[
    _Column('الوقت', 150),
    _Column('الحدث', 200),
    _Column('المستخدم', 170),
    _Column('المورد', 150),
    _Column('الحالة', 110),
    _Column('عنوان IP', 130),
    _Column('', 60),
  ];

  static double get _tableWidth =>
      _columns.fold<double>(0, (sum, c) => sum + c.width);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.allMd,
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowSoft,
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // الجدول يتمدّد ليملأ العرض المتاح، ويتحوّل إلى تمرير أفقي على
          // الشاشات الأضيق من مجموع الأعمدة.
          final width = constraints.maxWidth > _tableWidth
              ? constraints.maxWidth
              : _tableWidth;

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: width,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _HeaderRow(totalWidth: width),
                  for (var i = 0; i < items.length; i++)
                    _DataRow(
                      entry: items[i],
                      totalWidth: width,
                      isLast: i == items.length - 1,
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Column {
  final String title;
  final double width;
  const _Column(this.title, this.width);
}

/// يوزّع أي عرض فائض على الأعمدة بالتناسب، فلا يبقى فراغ على اليسار.
List<double> _resolvedWidths(double totalWidth) {
  final base = AuditLogsTable._tableWidth;
  final scale = totalWidth > base ? totalWidth / base : 1.0;
  return [for (final c in AuditLogsTable._columns) c.width * scale];
}

class _HeaderRow extends StatelessWidget {
  final double totalWidth;

  const _HeaderRow({required this.totalWidth});

  @override
  Widget build(BuildContext context) {
    final widths = _resolvedWidths(totalWidth);

    return Container(
      height: 48,
      color: AppColors.surfaceAlt,
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          for (var i = 0; i < AuditLogsTable._columns.length; i++)
            SizedBox(
              width: widths[i],
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    AuditLogsTable._columns[i].title,
                    textDirection: TextDirection.rtl,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DataRow extends StatefulWidget {
  final AuditLogEntry entry;
  final double totalWidth;
  final bool isLast;

  const _DataRow({
    required this.entry,
    required this.totalWidth,
    required this.isLast,
  });

  @override
  State<_DataRow> createState() => _DataRowState();
}

class _DataRowState extends State<_DataRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    final widths = _resolvedWidths(widget.totalWidth);

    final cells = <Widget>[
      _TextCell(auditDateTimeLabel(entry.createdAt), ltr: true),
      _ActionCell(action: entry.action),
      _TextCell(
        entry.user?.displayName ??
            (entry.userId != null ? 'مستخدم #${entry.userId}' : 'النظام'),
      ),
      _TextCell(
        entry.resourceId == null
            ? auditResourceLabel(entry.resourceType)
            : '${auditResourceLabel(entry.resourceType)} #${entry.resourceId}',
      ),
      Align(
        alignment: AlignmentDirectional.centerStart,
        child: AuditLogStatusBadge(status: entry.status),
      ),
      _TextCell(entry.ipAddress ?? '—', ltr: true),
      Align(
        alignment: AlignmentDirectional.center,
        child: IconButton(
          tooltip: 'عرض التفاصيل',
          icon: const Icon(Icons.visibility_outlined, size: 19),
          color: AppColors.primary,
          splashRadius: 20,
          onPressed: () => AuditLogDetailsDialog.show(context, entry),
        ),
      ),
    ];

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () => AuditLogDetailsDialog.show(context, entry),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          constraints: const BoxConstraints(minHeight: 56),
          decoration: BoxDecoration(
            color: _hovered ? AppColors.surfaceMuted : AppColors.surface,
            border: widget.isLast
                ? null
                : const Border(
                    bottom: BorderSide(color: AppColors.borderLight),
                  ),
          ),
          child: Row(
            textDirection: TextDirection.rtl,
            children: [
              for (var i = 0; i < cells.length; i++)
                SizedBox(
                  width: widths[i],
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: cells[i],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TextCell extends StatelessWidget {
  final String text;
  final bool ltr;

  const _TextCell(this.text, {this.ltr = false});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Text(
        text,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        textDirection: ltr ? TextDirection.ltr : TextDirection.rtl,
        style: const TextStyle(
          fontSize: 13,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}

/// الاسم العربي فوق الكود التقني — الأول للقراءة السريعة والثاني للفلترة.
class _ActionCell extends StatelessWidget {
  final String action;

  const _ActionCell({required this.action});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          auditActionLabel(action),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textDirection: TextDirection.rtl,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          action,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textDirection: TextDirection.ltr,
          style: const TextStyle(
            fontSize: 11,
            fontFamily: 'monospace',
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
