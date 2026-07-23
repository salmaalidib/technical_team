import 'dart:io';

import 'package:dio/dio.dart' as dio;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';

import '../../data/datasources/app_update_remote_data_source.dart';
import '../../domain/entities/app_update_info.dart';
import '../../domain/usecases/check_for_update_usecase.dart';
import 'app_update_event.dart';
import 'app_update_state.dart';

/// يدير دورة حياة التحديث كاملة: الفحص → التنزيل (شريط تقدّم) → التثبيت
/// الصامت. مطابق في البنية لتوثيق الميزة الأصلي (SettingController)، لكن
/// آلية التثبيت هنا مختلفة جذرياً: هذا التطبيق يُوزَّع كمثبِّت Inno Setup
/// (.exe) وليس حزمة MSIX، فالتثبيت الصامت يكون بتشغيل الملف المُنزَّل بوسائط
/// `/VERYSILENT /SUPPRESSMSGBOXES /NORESTART` بدل `Start-Process` على MSIX.
class AppUpdateBloc extends Bloc<AppUpdateEvent, AppUpdateState> {
  final CheckForUpdateUseCase checkForUpdate;
  final AppUpdateRemoteDataSource remote;
  final int currentVersionCode;

  dio.CancelToken? _cancelToken;

  AppUpdateBloc({
    required this.checkForUpdate,
    required this.remote,
    required this.currentVersionCode,
  }) : super(const AppUpdateState()) {
    on<CheckForUpdateRequested>(_onCheck);
    on<StartUpdateRequested>(_onStart);
    on<CancelUpdateRequested>(_onCancel);
  }

  Future<void> _onCheck(
    CheckForUpdateRequested event,
    Emitter<AppUpdateState> emit,
  ) async {
    emit(state.copyWith(phase: AppUpdatePhase.checking, clearError: true));

    final result = await checkForUpdate(currentVersionCode: currentVersionCode);

    result.fold(
      (failure) => emit(state.copyWith(
        phase: AppUpdatePhase.error,
        errorMessage: failure.message,
      )),
      (check) {
        if (!check.hasUpdate) {
          emit(state.copyWith(phase: AppUpdatePhase.upToDate, clearInfo: true));
          return;
        }
        emit(state.copyWith(
          phase: AppUpdatePhase.updateAvailable,
          forceUpdateEnabled: check.forceUpdateEnabled,
          softUpdateEnabled: check.softUpdateEnabled,
          info: check.info,
        ));
      },
    );
  }

  Future<void> _onStart(
    StartUpdateRequested event,
    Emitter<AppUpdateState> emit,
  ) async {
    final info = state.info;
    if (info == null) return;

    // احتياطي: لا رابط تنزيل مباشر صالح على هذه المنصة → لا شيء نقدر نفعله
    // آلياً هنا (لا يوجد متجر لتطبيق سطح مكتب مستقل)؛ نُبقي الحالة كما هي
    // ونترك الواجهة تعرض رسالة "تواصل مع الدعم التقني" حسب info.updateStrategy.
    if (!info.isDirectInstall) return;

    await _downloadAndInstall(info, emit);
  }

  void _onCancel(CancelUpdateRequested event, Emitter<AppUpdateState> emit) {
    _cancelToken?.cancel('cancelled_by_user');
    emit(state.copyWith(phase: AppUpdatePhase.updateAvailable, downloadProgress: 0.0));
  }

  Future<void> _downloadAndInstall(
    AppUpdateInfo info,
    Emitter<AppUpdateState> emit,
  ) async {
    final url = info.downloadUrl?.trim() ?? '';
    if (url.isEmpty) return;

    emit(state.copyWith(
      phase: AppUpdatePhase.downloading,
      downloadProgress: 0.0,
      clearError: true,
    ));

    try {
      final dir = await getTemporaryDirectory();
      final savePath = '${dir.path}/technical_team_update_${info.versionCode}.exe';
      final file = File(savePath);
      // تنظيف بقايا محاولة سابقة ناقصة/تالفة قبل التنزيل — استئناف Dio.download
      // فوق ملف جزئي ينتج مثبتاً تالفاً يفشل بصمت لاحقاً.
      if (await file.exists()) {
        await file.delete();
      }

      _cancelToken = dio.CancelToken();

      await remote.downloadClient.download(
        url,
        savePath,
        cancelToken: _cancelToken,
        options: dio.Options(
          headers: const {}, // بلا Authorization عمداً — الرابط عام (§2.4 من التوثيق)
          followRedirects: true,
        ),
        onReceiveProgress: (received, total) {
          final known = total > 0 ? total : (info.fileSize ?? 0);
          final progress = known > 0 ? (received / known).clamp(0.0, 1.0) : -1.0;
          if (!isClosed) {
            emit(state.copyWith(downloadProgress: progress));
          }
        },
      );

      if (isClosed) return;
      emit(state.copyWith(phase: AppUpdatePhase.installing, downloadProgress: 1.0));

      await _launchSilentInstaller(savePath, emit);
    } on dio.DioException catch (e) {
      if (isClosed) return;
      if (dio.CancelToken.isCancel(e)) {
        emit(state.copyWith(
          phase: AppUpdatePhase.updateAvailable,
          downloadProgress: 0.0,
        ));
      } else {
        emit(state.copyWith(
          phase: AppUpdatePhase.error,
          errorMessage: 'فشل تنزيل التحديث، يرجى المحاولة مرة أخرى.',
        ));
      }
    } catch (_) {
      if (isClosed) return;
      emit(state.copyWith(
        phase: AppUpdatePhase.error,
        errorMessage: 'حدث خطأ غير متوقع أثناء التحديث.',
      ));
    }
  }

  /// يشغّل مثبِّت Inno Setup المُنزَّل بصمت تام (بلا أي نافذة أو رسالة) عبر
  /// وسائط سطر الأوامر القياسية لـ Inno Setup:
  ///   /VERYSILENT         — بلا واجهة إطلاقاً (لا حتى شريط التقدم)
  ///   /SUPPRESSMSGBOXES   — بلا أي صندوق رسائل تفاعلي
  ///   /NORESTART          — لا تعيد تشغيل الجهاز تلقائياً
  /// `CloseApplications=yes` في installer/technical_team.iss يجعل المثبِّت
  /// نفسه يُغلق عملية `technical_team.exe` القديمة عبر Restart Manager؛ رغم
  /// ذلك نُشغّله كعملية منفصلة (detached) ثم نُنهي التطبيق الحالي بعد تأخير
  /// قصير، بدل الاعتماد فقط على إغلاق المثبِّت القسري — تفادياً لتنازع اللحظة
  /// التي يحاول فيها المثبِّت الكتابة فوق technical_team.exe بينما هو لا يزال
  /// قيد التشغيل (نافذة الحظ في Restart Manager ليست مضمونة 100% صامتاً).
  Future<void> _launchSilentInstaller(
    String installerPath,
    Emitter<AppUpdateState> emit,
  ) async {
    try {
      final process = await Process.start(
        installerPath,
        ['/VERYSILENT', '/SUPPRESSMSGBOXES', '/NORESTART'],
        mode: ProcessStartMode.detached,
      );

      if (process.pid <= 0) {
        if (!isClosed) {
          emit(state.copyWith(
            phase: AppUpdatePhase.error,
            errorMessage: 'تعذّر بدء عملية التثبيت.',
          ));
        }
        return;
      }

      // نافذة قصيرة تسمح للمثبِّت بالانطلاق فعلياً (فتح ملف، حجز موارد) قبل
      // أن يُغلَق هذا التطبيق ويحرّر قفل technical_team.exe للاستبدال.
      await Future<void>.delayed(const Duration(seconds: 2));
      exit(0);
    } catch (e) {
      if (!isClosed) {
        emit(state.copyWith(
          phase: AppUpdatePhase.error,
          errorMessage: 'تعذّر تشغيل ملف التثبيت: $e',
        ));
      }
    }
  }
}
