import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/enums/form_status.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_dimens.dart';
import '../../domain/entities/app_version_row.dart';
import '../../domain/entities/managed_application.dart';
import '../bloc/app_versions_bloc.dart';
import '../bloc/app_versions_event.dart';
import '../bloc/app_versions_state.dart';

/// نموذج تسجيل/تعديل إصدار — البديل الكامل عن Swagger.
///
/// الحقل الحرج هو `version_code`: هو وحده ما يقارنه الخادم بالرقم القادم من
/// العميل، وخطأ فيه يكسر الميزة بصمت (رقم مكرَّر أو أصغر = لا يُعرض تحديث
/// إطلاقاً). لذلك يقترح النموذج الرقم التالي تلقائياً ويمنع الإرسال على رقم
/// مستخدَم أو أصغر من الأعلى المسجَّل — وهو ما لا يفعله Swagger.
class VersionFormDialog extends StatefulWidget {
  final ManagedApplication application;

  /// null = إنشاء إصدار جديد · غير null = تعديل إصدار قائم.
  final AppVersionRow? existing;

  const VersionFormDialog({
    super.key,
    required this.application,
    this.existing,
  });

  @override
  State<VersionFormDialog> createState() => _VersionFormDialogState();
}

class _VersionFormDialogState extends State<VersionFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _versionName;
  late final TextEditingController _versionCode;
  late final TextEditingController _apkUrl;
  late final TextEditingController _apkSize;
  late final TextEditingController _changelog;
  late final TextEditingController _forceBelow;
  late final TextEditingController _softBelow;

  late String _platform;
  late bool _isActive;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    final state = context.read<AppVersionsBloc>().state;

    _platform = existing?.platform ?? widget.application.platforms.first;

    // الرقم المقترح = الأعلى المسجَّل + 1. هذا هو السلوك الصحيح دائماً عند
    // إصدار نسخة جديدة، ويزيل أكثر مصادر الخطأ اليدوي شيوعاً.
    final suggested = state.highestVersionCodeFor(_platform) + 1;

    _versionName = TextEditingController(text: existing?.versionName ?? '');
    _versionCode = TextEditingController(
      text: (existing?.versionCode ?? suggested).toString(),
    );
    _apkUrl = TextEditingController(text: existing?.apkUrl ?? '');
    _apkSize = TextEditingController(text: existing?.apkSize?.toString() ?? '');
    _changelog = TextEditingController(text: existing?.changelog ?? '');
    _forceBelow = TextEditingController(
      text: existing?.forceUpdateBelowVersionCode?.toString() ?? '',
    );
    _softBelow = TextEditingController(
      text: existing?.softUpdateBelowVersionCode?.toString() ?? '',
    );

    // الإصدار الجديد يبدأ غير مُفعَّل عمداً (نفس افتراض الخادم): يُفعَّل بعد
    // التأكد أن الرابط يعمل فعلاً، وإلا حُرم كل المستخدمين من التحديث.
    _isActive = existing?.isActive ?? false;
  }

  @override
  void dispose() {
    _versionName.dispose();
    _versionCode.dispose();
    _apkUrl.dispose();
    _apkSize.dispose();
    _changelog.dispose();
    _forceBelow.dispose();
    _softBelow.dispose();
    super.dispose();
  }

  /// عند تغيير المنصة يتغيّر الرقم المقترح، لأن التعادل محسوب لكل منصة على حدة.
  void _onPlatformChanged(String? value) {
    if (value == null || value == _platform) return;
    final state = context.read<AppVersionsBloc>().state;
    setState(() {
      _platform = value;
      _versionCode.text = (state.highestVersionCodeFor(value) + 1).toString();
    });
  }

  String? _nullIfEmpty(TextEditingController controller) {
    final text = controller.text.trim();
    return text.isEmpty ? null : text;
  }

  int? _intOrNull(TextEditingController controller) {
    final text = controller.text.trim();
    return text.isEmpty ? null : int.tryParse(text);
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final bloc = context.read<AppVersionsBloc>();
    final status = _isActive ? 'active' : 'inactive';

    if (_isEdit) {
      bloc.add(UpdateVersionRequested(
        versionId: widget.existing!.id,
        apkUrl: _nullIfEmpty(_apkUrl),
        apkSize: _intOrNull(_apkSize),
        changelog: _nullIfEmpty(_changelog),
        forceUpdateBelowVersionCode: _intOrNull(_forceBelow),
        softUpdateBelowVersionCode: _intOrNull(_softBelow),
        status: status,
      ));
    } else {
      bloc.add(CreateVersionRequested(
        platform: _platform,
        versionName: _versionName.text.trim(),
        versionCode: int.parse(_versionCode.text.trim()),
        apkUrl: _nullIfEmpty(_apkUrl),
        apkSize: _intOrNull(_apkSize),
        changelog: _nullIfEmpty(_changelog),
        forceUpdateBelowVersionCode: _intOrNull(_forceBelow),
        softUpdateBelowVersionCode: _intOrNull(_softBelow),
        status: status,
      ));
    }
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
              constraints: const BoxConstraints(maxWidth: 640, maxHeight: 720),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _header(context),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                      child: Form(
                        key: _formKey,
                        child: _fields(state),
                      ),
                    ),
                  ),
                  if (state.formError != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 4),
                      child: _ErrorBanner(message: state.formError!),
                    ),
                  _actions(context, submitting),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _header(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 18),
      decoration: const BoxDecoration(
        color: AppColors.surfaceMuted,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          const Icon(Icons.system_update_alt_rounded,
              color: AppColors.primary, size: 26),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isEdit ? 'تعديل إصدار' : 'تسجيل إصدار جديد',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.application.displayName,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded,
                color: AppColors.textSecondary, size: 22),
          ),
        ],
      ),
    );
  }

  Widget _fields(AppVersionsState state) {
    final used = state.usedVersionCodesFor(_platform);
    final highest = state.highestVersionCodeFor(_platform);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // المنصة ورقم البناء غير قابلين للتعديل بعد الإنشاء (قيد الخادم).
        if (!_isEdit && widget.application.platforms.length > 1) ...[
          _label('المنصة'),
          DropdownButtonFormField<String>(
            initialValue: _platform,
            decoration: _decoration(),
            items: widget.application.platforms
                .map((p) =>
                    DropdownMenuItem(value: p, child: Text(_platformLabel(p))))
                .toList(),
            onChanged: _onPlatformChanged,
          ),
          const SizedBox(height: 16),
        ],

        _label('اسم الإصدار'),
        TextFormField(
          controller: _versionName,
          enabled: !_isEdit,
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.right,
          decoration: _decoration(hint: 'مثال: 1.0.8'),
          validator: (value) {
            if (_isEdit) return null;
            return (value == null || value.trim().isEmpty)
                ? 'اسم الإصدار مطلوب'
                : null;
          },
        ),
        const SizedBox(height: 16),

        _label('رقم البناء (version_code)'),
        TextFormField(
          controller: _versionCode,
          enabled: !_isEdit,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.right,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: _decoration(
            hint: 'الرقم المقترح: ${highest + 1}',
          ),
          validator: (value) {
            if (_isEdit) return null;
            final parsed = int.tryParse((value ?? '').trim());
            if (parsed == null || parsed < 1) return 'رقم البناء مطلوب';
            // التحقّق الذي يمنع الخطأ الذي وقع فعلاً في قاعدة البيانات:
            // إصداران مختلفان بنفس version_code.
            if (used.contains(parsed)) {
              return 'الرقم $parsed مستخدَم مسبقاً على هذه المنصة';
            }
            if (parsed <= highest) {
              return 'يجب أن يكون أكبر من $highest (أعلى رقم مسجَّل)';
            }
            return null;
          },
        ),
        _hint(
          _isEdit
              ? 'غير قابل للتعديل بعد الإنشاء.'
              : 'يجب أن يطابق رقم البناء في pubspec.yaml (الجزء بعد +).',
        ),
        const SizedBox(height: 16),

        _label('رابط التنزيل'),
        TextFormField(
          controller: _apkUrl,
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.left,
          decoration: _decoration(hint: 'https://www.abukm.com/apps/...'),
          validator: (value) {
            final text = (value ?? '').trim();
            if (text.isEmpty) return null; // مسموح فارغاً (استراتيجية store)
            final uri = Uri.tryParse(text);
            if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
              return 'رابط غير صالح';
            }
            if (uri.scheme != 'https') {
              return 'يجب أن يكون الرابط https';
            }
            return null;
          },
        ),
        _hint('ارفع الملف على الاستضافة أولاً، ثم الصق الرابط هنا.'),
        const SizedBox(height: 16),

        _label('حجم الملف بالبايت (اختياري)'),
        TextFormField(
          controller: _apkSize,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.right,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: _decoration(hint: 'مثال: 31857357'),
        ),
        _hint('يُستخدم لعرض شريط التقدّم أثناء التنزيل.'),
        const SizedBox(height: 16),

        _label('ملاحظات الإصدار (اختياري)'),
        TextFormField(
          controller: _changelog,
          maxLines: 3,
          maxLength: 2000,
          // نص عربي حر — يبدأ من اليمين. أما الرابط والأرقام أدناه فتبقى LTR
          // عمداً لأن عرضها معكوسةً يجعلها غير مقروءة.
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.right,
          decoration: _decoration(hint: 'ما الجديد في هذا الإصدار؟'),
        ),
        const SizedBox(height: 8),

        _label('إجبار التحديث لمن رقمه أقل من (اختياري)'),
        TextFormField(
          controller: _forceBelow,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.right,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: _decoration(hint: 'اتركه فارغاً = لا إجبار لأحد'),
        ),
        _hint('من رقمه أقل من هذا يرى شاشة تحديث إجباري لا يمكن تخطّيها.'),
        const SizedBox(height: 16),

        _label('تحديث اختياري لمن رقمه أقل من (اختياري)'),
        TextFormField(
          controller: _softBelow,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.right,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: _decoration(hint: 'اتركه فارغاً = يُعرض للجميع'),
        ),
        const SizedBox(height: 12),

        SwitchListTile(
          value: _isActive,
          onChanged: (value) => setState(() => _isActive = value),
          activeColor: AppColors.primary,
          contentPadding: EdgeInsets.zero,
          title: const Text(
            'تفعيل الإصدار',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          ),
          subtitle: Text(
            _isActive
                ? 'سيُعرَض للمستخدمين فور الحفظ — تأكّد أن الرابط يعمل.'
                : 'لن يُعرَض لأحد حتى تفعّله.',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _actions(BuildContext context, bool submitting) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 18),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
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
                    : Text(
                        _isEdit ? 'حفظ التعديلات' : 'تسجيل الإصدار',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 120,
            height: 48,
            child: OutlinedButton(
              onPressed: submitting ? null : () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                side: const BorderSide(color: AppColors.border),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
              ),
              child: const Text('إلغاء'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13.5,
            color: AppColors.textPrimary,
          ),
        ),
      );

  Widget _hint(String text) => Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Text(
          text,
          style:
              const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
        ),
      );

  InputDecoration _decoration({String? hint}) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          color: AppColors.textTertiary,
          fontSize: 13,
        ),
        filled: true,
        fillColor: AppColors.inputBackgroundAlt,
        isDense: true,
        counterText: '',
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

  static String _platformLabel(String platform) => switch (platform) {
        'windows' => 'ويندوز',
        'android' => 'أندرويد',
        'ios' => 'آيفون (iOS)',
        _ => platform,
      };
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.errorLight,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppColors.error, size: 19),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style:
                  const TextStyle(color: AppColors.errorDark, fontSize: 12.5),
            ),
          ),
        ],
      ),
    );
  }
}
