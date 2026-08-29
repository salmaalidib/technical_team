import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../bloc/process_builder_bloc.dart';
import '../bloc/process_builder_event.dart';
import '../bloc/process_builder_state.dart';
import 'process_animations.dart';
import '../../../../shared/theme/app_dimens.dart';

/// Step 2 — drag/drop or pick a BPMN/XML workflow file.
class Step2UploadBpmn extends StatelessWidget {
  const Step2UploadBpmn({super.key});

  Future<void> _pick(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['bpmn', 'xml'],
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

    if (context.mounted) {
      context
          .read<ProcessBuilderBloc>()
          .add(FileSelected(bytes: bytes, fileName: file.name));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProcessBuilderBloc, ProcessBuilderState>(
      buildWhen: (p, c) => p.fileName != c.fileName || p.hasFile != c.hasFile,
      builder: (context, state) {
        return InkWell(
          borderRadius: BorderRadius.circular(AppRadius.md),
          onTap: () => _pick(context),
          child: DottedBorderBox(
            hasFile: state.hasFile,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 56, horizontal: 24),
              child: Column(
                children: [
                  AnimatedContainer(
                    duration: AppMotion.normal,
                    curve: AppMotion.curve,
                    width: 92,
                    height: 92,
                    decoration: BoxDecoration(
                      color: state.hasFile
                          ? AppColors.lightPrimary
                          : AppColors.inputBackground,
                      shape: BoxShape.circle,
                    ),
                    // اختيار الملف يبدّل الأيقونة إلى علامة صح — تظهر بنبضة
                    // قصيرة لتأكيد نجاح الاختيار.
                    child: AnimatedSwitcher(
                      duration: AppMotion.normal,
                      switchInCurve: Curves.easeOutBack,
                      transitionBuilder: (child, animation) =>
                          ScaleTransition(scale: animation, child: child),
                      child: Icon(
                        state.hasFile
                            ? Icons.check_circle_rounded
                            : Icons.file_upload_outlined,
                        key: ValueKey(state.hasFile),
                        color: AppColors.primary,
                        size: 40,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  AnimatedSwitcher(
                    duration: AppMotion.normal,
                    switchInCurve: AppMotion.curve,
                    child: Text(
                      state.hasFile ? state.fileName! : 'رفع ملف سير العمل',
                      key: ValueKey(state.fileName ?? 'empty'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.hasFile
                        ? 'انقر لاختيار ملف آخر'
                        : 'اسحب وأفلت الملف هنا أو انقر للاختيار',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'الصيغة المدعومة: .bpmn، .xml',
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
        );
      },
    );
  }
}

/// A rounded, dashed-looking drop zone (uses a solid light border for
/// simplicity — no extra dependency).
class DottedBorderBox extends StatelessWidget {
  final Widget child;

  /// يُبرز الإطار بلون أساسي بعد اختيار ملف.
  final bool hasFile;

  const DottedBorderBox({
    super.key,
    required this.child,
    this.hasFile = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppMotion.normal,
      curve: AppMotion.curve,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: hasFile ? AppColors.primary : AppColors.border,
          width: 1.4,
        ),
      ),
      child: child,
    );
  }
}
