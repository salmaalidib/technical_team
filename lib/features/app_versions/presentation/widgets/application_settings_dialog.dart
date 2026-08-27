import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/enums/form_status.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_dimens.dart';
import '../../domain/entities/managed_application.dart';
import '../bloc/app_versions_bloc.dart';
import '../bloc/app_versions_event.dart';
import '../bloc/app_versions_state.dart';

/// إعدادات التطبيق: استراتيجية التحديث وروابط المتجر.
///
/// `direct` تعني تنزيل الملف وتثبيته داخل التطبيق، وهي مدعومة على ويندوز
/// وأندرويد فقط؛ `store` تفتح رابط المتجر خارجياً. الخادم يتراجع تلقائياً إلى
/// `store` إن لم يتحقّق شرط `direct` — فلا يتعطّل التحديث أبداً.
class ApplicationSettingsDialog extends StatefulWidget {
  final ManagedApplication application;

  const ApplicationSettingsDialog({super.key, required this.application});

  @override
  State<ApplicationSettingsDialog> createState() =>
      _ApplicationSettingsDialogState();
}

class _ApplicationSettingsDialogState extends State<ApplicationSettingsDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _appleUrl;
  late final TextEditingController _googleUrl;
  late String _strategy;

  bool get _isDesktopApp => widget.application.name == 'technical_team';

  @override
  void initState() {
    super.initState();
    _strategy = widget.application.updateStrategy;
    _appleUrl =
        TextEditingController(text: widget.application.appleStoreUrl ?? '');
    _googleUrl =
        TextEditingController(text: widget.application.googlePlayUrl ?? '');
  }

  @override
  void dispose() {
    _appleUrl.dispose();
    _googleUrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    context.read<AppVersionsBloc>().add(UpdateApplicationRequested(
          updateStrategy: _strategy,
          appleStoreUrl: _appleUrl.text.trim(),
          googlePlayUrl: _googleUrl.text.trim(),
        ));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AppVersionsBloc, AppVersionsState>(
      listenWhen: (p, c) => p.formStatus != c.formStatus,
      listener: (context, state) {
        if (state.formStatus == FormStatus.success) {
          Navigator.of(context).pop();
        }
      },
      builder: (context, state) {
        final submitting = state.formStatus == FormStatus.submitting;

        return Directionality(
          textDirection: TextDirection.rtl,
          child: Dialog(
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.tune_rounded,
                              color: AppColors.primary, size: 24),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'إعدادات ${widget.application.displayName}',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.close_rounded,
                                color: AppColors.textSecondary, size: 22),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'طريقة التحديث',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      _StrategyOption(
                        selected: _strategy == 'direct',
                        title: 'تنزيل مباشر',
                        subtitle: 'ينزّل الملف من الرابط ويثبّته داخل التطبيق '
                            '(ويندوز وأندرويد فقط).',
                        onTap: () => setState(() => _strategy = 'direct'),
                      ),
                      const SizedBox(height: 8),
                      _StrategyOption(
                        selected: _strategy == 'store',
                        title: 'فتح المتجر',
                        subtitle:
                            'يفتح رابط المتجر خارجياً ليحدّث المستخدم يدوياً.',
                        onTap: () => setState(() => _strategy = 'store'),
                      ),
                      if (_isDesktopApp && _strategy == 'store') ...[
                        const SizedBox(height: 4),
                        const _Note(
                          message:
                              'هذا تطبيق سطح مكتب ولا متجر له — اختيار «فتح '
                              'المتجر» يعني أن المستخدم لن يجد رابطاً للتحديث.',
                        ),
                      ],
                      if (!_isDesktopApp) ...[
                        const SizedBox(height: 18),
                        const Text(
                          'رابط Google Play',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _googleUrl,
                          textDirection: TextDirection.ltr,
                          textAlign: TextAlign.left,
                          decoration:
                              _decoration('https://play.google.com/...'),
                          validator: _urlValidator,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'رابط App Store',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _appleUrl,
                          textDirection: TextDirection.ltr,
                          textAlign: TextAlign.left,
                          decoration: _decoration('https://apps.apple.com/...'),
                          validator: _urlValidator,
                        ),
                      ],
                      if (state.formError != null) ...[
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppColors.errorLight,
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                          child: Text(
                            state.formError!,
                            style: const TextStyle(
                              color: AppColors.errorDark,
                              fontSize: 12.5,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 22),
                      SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: submitting ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                            ),
                          ),
                          child: submitting
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.2,
                                    color: AppColors.white,
                                  ),
                                )
                              : const Text(
                                  'حفظ',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// الخادم يتحقّق `Joi.string().uri()` — رابط ناقص يُرَدّ بـ 400، فنمنعه هنا.
  static String? _urlValidator(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return null;
    final uri = Uri.tryParse(text);
    if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
      return 'رابط غير صالح';
    }
    return null;
  }

  InputDecoration _decoration(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textTertiary, fontSize: 13),
        filled: true,
        fillColor: AppColors.inputBackgroundAlt,
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
        ),
      );
}

/// بديل [RadioListTile] — واجهته للمجموعات مهجورة في هذا الإصدار من Flutter،
/// وبطاقة قابلة للنقر تؤدي الغرض نفسه بلا اعتماد على API مهجور.
class _StrategyOption extends StatelessWidget {
  final bool selected;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _StrategyOption({
    required this.selected,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.lightPrimary : AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_unchecked_rounded,
              size: 20,
              color: selected ? AppColors.primary : AppColors.borderStrong,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color:
                          selected ? AppColors.primary : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppColors.textSecondary,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Note extends StatelessWidget {
  final String message;
  const _Note({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.lightSecondary,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded,
              size: 17, color: AppColors.warning),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 11.5,
                color: AppColors.warningAlt,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
