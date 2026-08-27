import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/enums/request_status.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/layouts/page_header_row.dart';
import '../../../../shared/theme/app_dimens.dart';
import '../../../../shared/widgets/app_skeleton.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../domain/entities/app_version_row.dart';
import '../../domain/entities/managed_application.dart';
import '../bloc/app_versions_bloc.dart';
import '../bloc/app_versions_event.dart';
import '../bloc/app_versions_state.dart';
import '../widgets/application_settings_dialog.dart';
import '../widgets/version_card.dart';
import '../widgets/version_form_dialog.dart';

/// شاشة إدارة إصدارات التطبيقات الثلاثة — بديل Swagger.
///
/// تتطلب صلاحية `APP_VERSION_MANAGE` (مربوطة بدور «مسؤول تقني»)؛ بدونها يردّ
/// الخادم 403 وتُعرض رسالة الصلاحية بدل قائمة فارغة غامضة.
class AppVersionsPage extends StatelessWidget {
  const AppVersionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<AppVersionsBloc>()..add(const LoadApplications()),
      child: BlocListener<AppVersionsBloc, AppVersionsState>(
        listenWhen: (p, c) =>
            p.successMessage != c.successMessage ||
            p.actionError != c.actionError,
        listener: (context, state) {
          final error = state.actionError;
          final success = state.successMessage;

          if (error != null) {
            AppSnackBar.show(context, message: error, isError: true);
            context.read<AppVersionsBloc>().add(const ClearFormFeedback());
          } else if (success != null) {
            AppSnackBar.show(context, message: success);
            context.read<AppVersionsBloc>().add(const ClearFormFeedback());
          }
        },
        child: const _AppVersionsView(),
      ),
    );
  }
}

class _AppVersionsView extends StatelessWidget {
  const _AppVersionsView();

  @override
  Widget build(BuildContext context) {
    final horizontal = MediaQuery.sizeOf(context).width < 700 ? 16.0 : 40.0;

    return Container(
      color: AppColors.surfaceAlt,
      padding: EdgeInsets.fromLTRB(horizontal, 28, horizontal, 30),
      child: const SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Header(),
            SizedBox(height: 24),
            _ApplicationTabs(),
            SizedBox(height: 20),
            _VersionsBody(),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppVersionsBloc, AppVersionsState>(
      buildWhen: (p, c) =>
          p.selectedAppId != c.selectedAppId ||
          p.applications != c.applications,
      builder: (context, state) {
        final app = state.selectedApplication;

        return PageHeaderRow(
          title: Column(
            // في RTL: start = اليمين (end كانت تُبعد صفّ العنوان عن الحافة).
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                textDirection: TextDirection.rtl,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.system_update_alt_rounded,
                      color: AppColors.primary, size: 34),
                  const SizedBox(width: 10),
                  Text(
                    'إصدارات التطبيقات',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'تسجيل إصدار جديد وإدارة التحديثات للتطبيقات الثلاثة',
                textAlign: TextAlign.right,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
          ),
          // عرض وارتفاع ثابتان مطابقان لزر «إنشاء دور جديد»: بدون تقييد
          // العرض يفرض ثيم الأزرار `minimumSize: infinity` فيتمدّد الزر
          // شريطاً بعرض الصفحة.
          action: app == null
              ? null
              : SizedBox(
                  width: 210,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: () => _openVersionForm(context, app),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      textDirection: TextDirection.rtl,
                      children: [
                        const Icon(Icons.add_rounded, size: 24),
                        const SizedBox(width: 10),
                        Text(
                          'تسجيل إصدار جديد',
                          style:
                              Theme.of(context).textTheme.labelLarge?.copyWith(
                                    color: AppColors.white,
                                    fontWeight: FontWeight.w700,
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

void _openVersionForm(
  BuildContext context,
  ManagedApplication app, {
  AppVersionRow? existing,
}) {
  final bloc = context.read<AppVersionsBloc>();
  // النموذج يقرأ formStatus؛ نصفّره قبل الفتح حتى لا يُغلق فوراً بسبب نجاح
  // عملية سابقة ما زال أثرها في الحالة.
  bloc.add(const ClearFormFeedback());

  showDialog(
    context: context,
    barrierColor: AppColors.scrim,
    builder: (_) => BlocProvider.value(
      value: bloc,
      child: VersionFormDialog(application: app, existing: existing),
    ),
  );
}

void _openSettings(BuildContext context, ManagedApplication app) {
  final bloc = context.read<AppVersionsBloc>();
  bloc.add(const ClearFormFeedback());

  showDialog(
    context: context,
    barrierColor: AppColors.scrim,
    builder: (_) => BlocProvider.value(
      value: bloc,
      child: ApplicationSettingsDialog(application: app),
    ),
  );
}

/// تبويبات التطبيقات الثلاثة (المواطن / الموظف / التقني).
class _ApplicationTabs extends StatelessWidget {
  const _ApplicationTabs();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppVersionsBloc, AppVersionsState>(
      buildWhen: (p, c) =>
          p.applications != c.applications ||
          p.selectedAppId != c.selectedAppId ||
          p.appsStatus != c.appsStatus,
      builder: (context, state) {
        if (state.appsStatus == RequestStatus.loading ||
            state.appsStatus == RequestStatus.initial) {
          return const SizedBox(height: 46);
        }

        if (state.appsStatus == RequestStatus.failure) {
          return _ErrorBox(
            message: state.appsError ?? 'تعذّر تحميل التطبيقات',
            onRetry: () =>
                context.read<AppVersionsBloc>().add(const LoadApplications()),
          );
        }

        return Wrap(
          textDirection: TextDirection.rtl,
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final app in state.applications)
              _AppTab(
                app: app,
                selected: app.id == state.selectedAppId,
                onTap: () => context
                    .read<AppVersionsBloc>()
                    .add(SelectApplication(app.id)),
                // إعدادات التطبيق (الاستراتيجية وروابط المتجر) تُفتح بضغطة
                // مطوّلة على التبويب بدل زر دائم في الرأس — تُستخدم نادراً،
                // وزرّها كان يزاحم زر التسجيل ويُشوّه الرأس.
                onLongPress: () => _openSettings(context, app),
              ),
          ],
        );
      },
    );
  }
}

class _AppTab extends StatelessWidget {
  final ManagedApplication app;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _AppTab({
    required this.app,
    required this.selected,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'ضغطة مطوّلة لإعدادات التطبيق',
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            textDirection: TextDirection.rtl,
            children: [
              Text(
                app.displayName,
                style: TextStyle(
                  color: selected ? AppColors.white : AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.whiteTranslucent
                      : AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  app.isDirect ? 'مباشر' : 'متجر',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color:
                        selected ? AppColors.primary : AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VersionsBody extends StatelessWidget {
  const _VersionsBody();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppVersionsBloc, AppVersionsState>(
      buildWhen: (p, c) =>
          p.versionsStatus != c.versionsStatus ||
          p.versions != c.versions ||
          p.busyIds != c.busyIds ||
          p.selectedAppId != c.selectedAppId,
      builder: (context, state) {
        switch (state.versionsStatus) {
          case RequestStatus.initial:
          case RequestStatus.loading:
            return const AppSkeleton.list();

          case RequestStatus.failure:
            return _ErrorBox(
              message: state.versionsError ?? 'تعذّر تحميل الإصدارات',
              onRetry: () =>
                  context.read<AppVersionsBloc>().add(const ReloadVersions()),
            );

          case RequestStatus.success:
            if (state.versions.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 70),
                child: Center(
                  child: Text(
                    'لا توجد إصدارات مسجَّلة لهذا التطبيق',
                    style: TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 15,
                    ),
                  ),
                ),
              );
            }
            return _VersionsList(state: state);
        }
      },
    );
  }
}

class _VersionsList extends StatelessWidget {
  final AppVersionsState state;

  const _VersionsList({required this.state});

  @override
  Widget build(BuildContext context) {
    final app = state.selectedApplication;
    if (app == null) return const SizedBox.shrink();

    // عدّ تكرار كل (منصة، رقم بناء) لتمييز الصفوف المكرَّرة التي تكسر الترتيب
    // على الخادم.
    final counts = <String, int>{};
    for (final version in state.versions) {
      final key = '${version.platform}#${version.versionCode}';
      counts[key] = (counts[key] ?? 0) + 1;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final version in state.versions)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: VersionCard(
              version: version,
              highestCodeOnPlatform:
                  state.highestVersionCodeFor(version.platform),
              hasDuplicateCode:
                  (counts['${version.platform}#${version.versionCode}'] ?? 0) >
                      1,
              busy: state.busyIds.contains(version.id),
              onEdit: () => _openVersionForm(context, app, existing: version),
              onToggle: () => context
                  .read<AppVersionsBloc>()
                  .add(ToggleVersionStatus(version.id)),
              onDelete: () => _confirmDelete(context, version),
            ),
          ),
      ],
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    AppVersionRow version,
  ) async {
    final bloc = context.read<AppVersionsBloc>();

    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: AppColors.scrim,
      builder: (dialogContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          title: const Text(
            'حذف الإصدار',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
          ),
          content: Text(
            'سيُحذف الإصدار ${version.versionName} (رقم البناء '
            '${version.versionCode}) نهائياً. لا يمكن التراجع.',
            style: const TextStyle(fontSize: 13.5, height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text(
                'إلغاء',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: AppColors.white,
                elevation: 0,
              ),
              child: const Text('حذف'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true) {
      bloc.add(DeleteVersionRequested(version.id));
    }
  }
}

class _ErrorBox extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorBox({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 26),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppColors.error, size: 34),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13.5,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('إعادة المحاولة'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}
