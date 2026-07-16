import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/enums/form_status.dart';
import '../../../../core/enums/request_status.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../../fields/presentation/bloc/fields_bloc.dart';
import '../bloc/process_builder_bloc.dart';
import '../bloc/process_builder_event.dart';
import '../bloc/process_builder_state.dart';
import 'step1_basic_info.dart';
import 'step2_upload_bpmn.dart';
import 'step3_preview_stages.dart';
import 'step4_customize_stages.dart';
import 'wizard_kit.dart';

const _stepTitles = [
  'المعلومات الأساسية',
  'رفع ملف سير العمل',
  'معاينة المعاملة',
  'تخصيص الخطوات',
];

/// Full page (not a dialog) that hosts the create-process wizard.
/// [FieldsBloc] owns the field library (load + inline create); the
/// [ProcessBuilderBloc] owns the wizard state and the per-stage selection.
class CreateProcessPage extends StatelessWidget {
  /// The process type carried in from the type's processes page.
  final int? typeId;
  final String? typeName;

  /// When set, the wizard opens in COMPLETE mode for an existing process:
  /// it loads its stages and jumps straight to step 4 (no create flow).
  final int? existingProcessId;

  const CreateProcessPage({
    super.key,
    this.typeId,
    this.typeName,
    this.existingProcessId,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) {
            final bloc = getIt<ProcessBuilderBloc>();
            if (existingProcessId != null) {
              bloc.add(LoadExistingForStageConfig(existingProcessId!));
            } else {
              bloc.add(InitWizard(typeId: typeId));
            }
            return bloc;
          },
        ),
        // Each field-type dropdown loads its own first page lazily on open.
        BlocProvider(create: (_) => getIt<FieldsBloc>()),
      ],
      child: const _WizardView(),
    );
  }
}

class _WizardView extends StatefulWidget {
  const _WizardView();

  @override
  State<_WizardView> createState() => _WizardViewState();
}

class _WizardViewState extends State<_WizardView> {
  bool _showStep1Errors = false;

  void _close(BuildContext context) =>
      context.canPop() ? context.pop() : context.go('/transactions');

  bool _step1Valid(ProcessBuilderState s) {
    final typeOk = s.isComplaint || s.typeTransId != null;
    return s.name.trim().isNotEmpty &&
        s.organizationId != null &&
        s.startDate != null &&
        typeOk;
  }

  void _onPrimary(BuildContext context, ProcessBuilderState s) {
    final bloc = context.read<ProcessBuilderBloc>();

    switch (s.currentStep) {
      case 1:
        if (!_step1Valid(s)) {
          setState(() => _showStep1Errors = true);
          return;
        }
        bloc.add(const StepRequested(2));
        break;
      case 2:
        if (!s.hasFile) {
          AppSnackBar.show(context,
              message: 'يرجى اختيار ملف سير العمل', isError: true);
          return;
        }
        if (s.createdProcess != null) {
          bloc.add(const StepRequested(3));
        } else {
          bloc.add(const SubmitCreate());
        }
        break;
      case 3:
        bloc.add(const StepRequested(4));
        break;
      case 4:
        bloc.add(const SubmitStageConfigs());
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProcessBuilderBloc, ProcessBuilderState>(
      listenWhen: (p, c) =>
          (p.createError != c.createError && c.createError != null) ||
          (p.actionError != c.actionError && c.actionError != null) ||
          (p.submitStatus != c.submitStatus &&
              c.submitStatus != FormStatus.idle &&
              c.submitStatus != FormStatus.submitting),
      listener: (context, state) {
        if (state.submitStatus == FormStatus.success) {
          AppSnackBar.show(context, message: 'تم حفظ تهيئة المراحل بنجاح');
          if (context.mounted) _close(context);
        } else if (state.submitStatus == FormStatus.failure) {
          AppSnackBar.show(context,
              message: state.submitError ?? 'تعذّر حفظ التهيئة', isError: true);
        } else if (state.createError != null) {
          AppSnackBar.show(context, message: state.createError!, isError: true);
        } else if (state.actionError != null) {
          AppSnackBar.show(context, message: state.actionError!, isError: true);
        }
      },
      builder: (context, state) {
        return Container(
          color: const Color(0xffF0EFE7),
          child: Column(
            children: [
              _Header(
                onClose: () => _close(context),
                completeMode: state.completeMode,
              ),
              // The step indicator is for the create flow; complete-mode opens
              // straight at step 4 and has nothing to step through.
              if (!state.completeMode) ...[
                Container(
                  color: AppColors.surface,
                  padding: const EdgeInsets.fromLTRB(28, 18, 28, 14),
                  child: WizardStepper(
                    currentStep: state.currentStep,
                    titles: _stepTitles,
                  ),
                ),
              ],
              const Divider(height: 1, color: AppColors.border),
              Expanded(
                child: _Body(state: state, showErrors: _showStep1Errors),
              ),
              const Divider(height: 1, color: AppColors.border),
              Container(
                color: AppColors.surface,
                child: _Footer(
                  state: state,
                  onCancel: () => _close(context),
                  onPrev: () => context
                      .read<ProcessBuilderBloc>()
                      .add(StepRequested(state.currentStep - 1)),
                  onPrimary: () => _onPrimary(context, state),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Body extends StatelessWidget {
  final ProcessBuilderState state;
  final bool showErrors;
  const _Body({required this.state, required this.showErrors});

  @override
  Widget build(BuildContext context) {
    if (state.bootStatus == RequestStatus.loading &&
        (state.currentStep == 1 || state.completeMode)) {
      return const Center(child: CircularProgressIndicator());
    }
    // Complete-mode load failed (couldn't fetch the existing process).
    if (state.completeMode &&
        state.bootStatus == RequestStatus.failure) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            state.createError ?? 'تعذّر تحميل المعاملة.',
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 15, fontWeight: FontWeight.w600, color: Colors.redAccent),
          ),
        ),
      );
    }
    if (state.createStatus == RequestStatus.loading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('جاري إنشاء العملية وتوليد المراحل...',
                style: TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      );
    }

    final Widget child;
    switch (state.currentStep) {
      case 1:
        child = Step1BasicInfo(showErrors: showErrors);
        break;
      case 2:
        child = const Step2UploadBpmn();
        break;
      case 3:
        child = const Step3PreviewStages();
        break;
      default:
        child = const Step4CustomizeStages();
    }

    final horizontal = MediaQuery.sizeOf(context).width < 700 ? 16.0 : 40.0;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(horizontal, 28, horizontal, 28),
      child: child,
    );
  }
}

class _Header extends StatelessWidget {
  final VoidCallback onClose;
  final bool completeMode;
  const _Header({required this.onClose, this.completeMode = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 18),
      child: Row(
        children: [
          InkWell(
            onTap: onClose,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.inputBackground,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.arrow_forward_rounded,
                  size: 22, color: AppColors.textPrimary),
            ),
          ),
          const Spacer(),
          Text(
            completeMode ? 'إكمال تهيئة المعاملة' : 'إنشاء معاملة جديدة',
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  final ProcessBuilderState state;
  final VoidCallback onCancel;
  final VoidCallback onPrev;
  final VoidCallback onPrimary;

  const _Footer({
    required this.state,
    required this.onCancel,
    required this.onPrev,
    required this.onPrimary,
  });

  @override
  Widget build(BuildContext context) {
    final isLast = state.currentStep == 4;
    final submitting = state.submitStatus == FormStatus.submitting;
    final creating = state.createStatus == RequestStatus.loading;
    final busy = submitting || creating;

    final primaryLabel = isLast
        ? (state.completeMode ? '✓  حفظ المراحل الناقصة' : '✓  حفظ واعتماد وتفعيل')
        : 'التالي';

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          SizedBox(
            height: 50,
            child: TextButton(
              onPressed: busy ? null : onCancel,
              style: TextButton.styleFrom(
                backgroundColor: AppColors.inputBackground,
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 28),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('إلغاء',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: busy ? null : onPrimary,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: busy
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        primaryLabel,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ),
          // No "previous" in complete-mode: it opens directly at step 4.
          if (state.currentStep > 1 && !state.completeMode) ...[
            const SizedBox(width: 12),
            SizedBox(
              height: 50,
              child: TextButton(
                onPressed: busy ? null : onPrev,
                style: TextButton.styleFrom(
                  backgroundColor: AppColors.inputBackground,
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('السابق',
                    style:
                        TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
