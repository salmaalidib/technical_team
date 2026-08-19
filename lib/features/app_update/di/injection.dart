import 'package:flutter/foundation.dart' show debugPrint;
import 'package:package_info_plus/package_info_plus.dart';

import '../../../core/di/injection.dart';
import '../data/datasources/app_update_remote_data_source.dart';
import '../data/repositories/app_update_repository_impl.dart';
import '../domain/repositories/app_update_repository.dart';
import '../domain/usecases/check_for_update_usecase.dart';
import '../presentation/bloc/app_update_bloc.dart';

/// رقم البناء (version_code) المحقون وقت الترجمة عبر:
///   flutter build windows --dart-define=APP_VERSION_CODE=<N>
///
/// لماذا لا نكتفي بـ `PackageInfo.buildNumber`؟ لأنه **لا يعمل على ويندوز**:
/// المكوّن الويندوزي في package_info_plus لا يقرأ pubspec.yaml إطلاقاً، بل
/// يقرأ حقل `ProductVersion` من داخل الـ .exe ثم يقسمه على '+':
///
///   // package_info_plus/lib/src/package_info_plus_windows.dart
///   final versions = info.productVersion.split('+');
///   buildNumber: versions.getOrNull(1) ?? '',   // ← ما بعد الـ +
///
/// لكن Flutter يكتب في `ProductVersion` قيمة `FLUTTER_VERSION` وحدها — أي
/// "1.0.2" بلا "+3" — لأن رقم البناء يُمرَّر منفصلاً في `FLUTTER_VERSION_BUILD`
/// ليُستعمل في `FILEVERSION` الرقمي فقط (انظر windows/runner/Runner.rc).
/// فالنتيجة الحتمية: split('+') يعطي عنصراً واحداً → getOrNull(1) = null →
/// buildNumber = "" → int.tryParse("") = null → **currentVersionCode = 0 دائماً**.
///
/// وأثر ذلك أن التطبيق يرسل `current_version_code=0` مهما كان الإصدار المثبَّت،
/// فيردّ الخادم دوماً بوجود تحديث، فتتكرّر شاشة التحديث الإجباري على نسخة
/// محدَّثة أصلاً — حلقة لا تنتهي تبدو كأن ميزة التحديث «لا تعمل».
const int _kInjectedVersionCode =
    int.fromEnvironment('APP_VERSION_CODE', defaultValue: 0);

/// يحسم رقم الإصدار الحالي بترتيب ثقة تنازلي:
///   1. القيمة المحقونة وقت الترجمة (مضمونة على كل المنصات).
///   2. `PackageInfo.buildNumber` (يعمل على أندرويد/iOS، ويفشل على ويندوز).
/// عند فشل الاثنين نُرجع 0 مع تحذير صريح في السجل بدل الفشل الصامت.
int resolveCurrentVersionCode(PackageInfo info) {
  if (_kInjectedVersionCode > 0) return _kInjectedVersionCode;

  final fromPackage = int.tryParse(info.buildNumber.trim()) ?? 0;
  if (fromPackage > 0) return fromPackage;

  debugPrint(
    '[AppUpdate] تحذير: تعذّر تحديد رقم الإصدار الحالي '
    '(buildNumber="${info.buildNumber}", version="${info.version}"). '
    'ابنِ التطبيق مع --dart-define=APP_VERSION_CODE=<رقم البناء من pubspec.yaml> '
    'وإلا سيُرسَل 0 وستتكرّر شاشة التحديث بلا نهاية.',
  );
  return 0;
}

Future<void> setupAppUpdateInjection() async {
  final packageInfo = await PackageInfo.fromPlatform();
  final currentVersionCode = resolveCurrentVersionCode(packageInfo);

  if (!getIt.isRegistered<AppUpdateRemoteDataSource>()) {
    getIt.registerLazySingleton<AppUpdateRemoteDataSource>(
      () => AppUpdateRemoteDataSource(),
    );
  }

  if (!getIt.isRegistered<AppUpdateRepository>()) {
    getIt.registerLazySingleton<AppUpdateRepository>(
      () => AppUpdateRepositoryImpl(getIt<AppUpdateRemoteDataSource>()),
    );
  }

  if (!getIt.isRegistered<CheckForUpdateUseCase>()) {
    getIt.registerLazySingleton<CheckForUpdateUseCase>(
      () => CheckForUpdateUseCase(getIt<AppUpdateRepository>()),
    );
  }

  // Singleton (لا factory): يجب أن تبقى نفس نسخة البلوك حية من splash وحتى
  // شاشة settings — لو أُعيد إنشاؤها لكل شاشة لَفَقَدنا حالة "جارٍ التحميل"
  // عند التنقّل بعيداً عن ForceUpdatePage أثناء تنزيل مستمر في الخلفية.
  if (!getIt.isRegistered<AppUpdateBloc>()) {
    getIt.registerLazySingleton<AppUpdateBloc>(
      () => AppUpdateBloc(
        checkForUpdate: getIt<CheckForUpdateUseCase>(),
        remote: getIt<AppUpdateRemoteDataSource>(),
        currentVersionCode: currentVersionCode,
      ),
    );
  }
}
