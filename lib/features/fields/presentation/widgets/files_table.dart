import 'package:flutter/material.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../domain/entities/file_definition.dart';

String _fmtDate(String? raw) {
  if (raw == null || raw.isEmpty) return '—';
  return raw.length >= 10 ? raw.substring(0, 10) : raw;
}

class FilesTable extends StatelessWidget {
  final List<FileDefinition> files;
  final ValueChanged<FileDefinition> onEdit;

  const FilesTable({super.key, required this.files, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < 700;
    if (narrow) {
      return Column(
        children: [
          for (var i = 0; i < files.length; i++) ...[
            _FileCard(
                index: i + 1, file: files[i], onEdit: () => onEdit(files[i])),
            if (i != files.length - 1) const SizedBox(height: 14),
          ],
        ],
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          const _HeaderRow(),
          for (var i = 0; i < files.length; i++)
            _DataRow(
              index: i + 1,
              file: files[i],
              onEdit: () => onEdit(files[i]),
              last: i == files.length - 1,
            ),
        ],
      ),
    );
  }
}

// ===== table cells layout (shared flex weights) =====
Widget _cells({
  required Widget num,
  required Widget name,
  required Widget type,
  required Widget classification,
  required Widget created,
  required Widget updated,
  required Widget actions,
}) {
  return Row(
    textDirection: TextDirection.rtl,
    children: [
      SizedBox(width: 44, child: num),
      Expanded(flex: 3, child: name),
      Expanded(flex: 2, child: type),
      Expanded(flex: 2, child: classification),
      Expanded(flex: 2, child: created),
      Expanded(flex: 2, child: updated),
      SizedBox(width: 70, child: actions),
    ],
  );
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow();

  Widget _h(String text) => Text(
        text,
        textAlign: TextAlign.right,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 13.5,
          fontWeight: FontWeight.w700,
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: _cells(
        num: _h('#'),
        name: _h('اسم الملف'),
        type: _h('نوع الملف'),
        classification: _h('التصنيف'),
        created: _h('تاريخ الإنشاء'),
        updated: _h('آخر تعديل'),
        actions: _h('الإجراءات'),
      ),
    );
  }
}

class _DataRow extends StatelessWidget {
  final int index;
  final FileDefinition file;
  final VoidCallback onEdit;
  final bool last;

  const _DataRow({
    required this.index,
    required this.file,
    required this.onEdit,
    required this.last,
  });

  Widget _t(String text) => Text(
        text,
        textAlign: TextAlign.right,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: last
            ? null
            : const Border(bottom: BorderSide(color: AppColors.border)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: _cells(
        num: _t('$index'),
        name: Row(
          textDirection: TextDirection.rtl,
          children: [
            const Icon(Icons.description_outlined,
                size: 18, color: AppColors.textSecondary),
            const SizedBox(width: 8),
            Expanded(child: _t(file.fileName)),
          ],
        ),
        type: Align(
          alignment: Alignment.centerRight,
          child: FileTypeBadge(fileType: file.fileType),
        ),
        classification: _t(file.classification),
        created: _t(_fmtDate(file.createdAt)),
        updated: _t(_fmtDate(file.updatedAt)),
        actions: Align(
          alignment: Alignment.centerRight,
          child: _EditButton(onTap: onEdit),
        ),
      ),
    );
  }
}

/// Mobile fallback: each file rendered as a card.
class _FileCard extends StatelessWidget {
  final int index;
  final FileDefinition file;
  final VoidCallback onEdit;

  const _FileCard({
    required this.index,
    required this.file,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            textDirection: TextDirection.rtl,
            children: [
              const Icon(Icons.description_outlined,
                  size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  file.fileName,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              _EditButton(onTap: onEdit),
            ],
          ),
          const SizedBox(height: 12),
          _kv('نوع الملف', child: FileTypeBadge(fileType: file.fileType)),
          const SizedBox(height: 8),
          _kv('التصنيف', text: file.classification),
          const SizedBox(height: 8),
          _kv('تاريخ الإنشاء', text: _fmtDate(file.createdAt)),
          const SizedBox(height: 8),
          _kv('آخر تعديل', text: _fmtDate(file.updatedAt)),
        ],
      ),
    );
  }

  Widget _kv(String label, {String? text, Widget? child}) {
    return Row(
      textDirection: TextDirection.rtl,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        child ??
            Text(
              text ?? '—',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
      ],
    );
  }
}

class FileTypeBadge extends StatelessWidget {
  final String fileType;

  const FileTypeBadge({super.key, required this.fileType});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.lightPrimary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        fileType.toUpperCase(),
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 12.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _EditButton extends StatelessWidget {
  final VoidCallback onTap;

  const _EditButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'تعديل',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.inputBackground,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.edit_outlined,
              size: 19, color: AppColors.primary),
        ),
      ),
    );
  }
}
