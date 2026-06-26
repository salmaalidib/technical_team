import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/app_snackbar.dart';

/// A picked template file held in the form (bytes kept for multipart upload).
class PickedFile {
  final List<int> bytes;
  final String name;

  const PickedFile({required this.bytes, required this.name});

  int get sizeBytes => bytes.length;
}

/// File-upload field for a document template: a dashed drop zone that, once a
/// file is picked, shows its name / size / extension with a remove action.
///
/// In edit mode an [existingFileName] can be shown when no new file is picked
/// (the backend keeps the old file if none is sent). Allowed extensions match
/// the backend upload filter: pdf / docx / html.
class TemplateFileUpload extends StatelessWidget {
  final PickedFile? picked;
  final String? existingFileName;
  final ValueChanged<PickedFile> onPicked;
  final VoidCallback onCleared;

  const TemplateFileUpload({
    super.key,
    required this.picked,
    required this.onPicked,
    required this.onCleared,
    this.existingFileName,
  });

  static const _allowed = ['pdf', 'docx', 'html'];

  Future<void> _pick(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: _allowed,
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    final bytes = file.bytes;

    if (bytes == null) {
      if (context.mounted) {
        AppSnackBar.show(context,
            message: 'تعذّر قراءة محتوى الملف', isError: true);
      }
      return;
    }

    onPicked(PickedFile(bytes: bytes, name: file.name));
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final hasNewFile = picked != null;
    final hasExisting = !hasNewFile &&
        existingFileName != null &&
        existingFileName!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (hasNewFile || hasExisting)
          _FileChip(
            name: hasNewFile ? picked!.name : existingFileName!,
            subtitle: hasNewFile
                ? _formatSize(picked!.sizeBytes)
                : 'الملف الحالي',
            onReplace: () => _pick(context),
            onRemove: hasNewFile ? onCleared : null,
          )
        else
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => _pick(context),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.border,
                  width: 1.4,
                ),
              ),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 40, horizontal: 24),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: AppColors.inputBackground,
                      child: Icon(Icons.file_upload_outlined,
                          color: AppColors.primary, size: 34),
                    ),
                    SizedBox(height: 14),
                    Text(
                      'رفع ملف القالب',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'انقر لاختيار ملف — الصيغ المدعومة: PDF، DOCX، HTML',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _FileChip extends StatelessWidget {
  final String name;
  final String subtitle;
  final VoidCallback onReplace;
  final VoidCallback? onRemove;

  const _FileChip({
    required this.name,
    required this.subtitle,
    required this.onReplace,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 1.4),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.lightPrimary,
            child: Icon(Icons.description_outlined,
                color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: onReplace,
            icon: const Icon(Icons.swap_horiz_rounded, size: 18),
            label: const Text('استبدال'),
            style: TextButton.styleFrom(foregroundColor: AppColors.primary),
          ),
          if (onRemove != null)
            IconButton(
              onPressed: onRemove,
              tooltip: 'إزالة',
              icon: const Icon(Icons.close_rounded,
                  color: AppColors.error, size: 20),
            ),
        ],
      ),
    );
  }
}
