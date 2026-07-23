import 'package:equatable/equatable.dart';

import '../../domain/entities/app_update_info.dart';

enum AppUpdatePhase {
  idle,
  checking,
  upToDate,
  updateAvailable,
  downloading,
  installing,
  error,
}

class AppUpdateState extends Equatable {
  final AppUpdatePhase phase;
  final bool forceUpdateEnabled;
  final bool softUpdateEnabled;
  final AppUpdateInfo? info;

  /// 0..1 نسبة التحميل، أو -1 عند تعذّر معرفة الحجم الكلي (indeterminate).
  final double downloadProgress;
  final String? errorMessage;

  const AppUpdateState({
    this.phase = AppUpdatePhase.idle,
    this.forceUpdateEnabled = false,
    this.softUpdateEnabled = false,
    this.info,
    this.downloadProgress = 0.0,
    this.errorMessage,
  });

  bool get isBusy =>
      phase == AppUpdatePhase.downloading || phase == AppUpdatePhase.installing;

  bool get hasUpdate => info != null;

  AppUpdateState copyWith({
    AppUpdatePhase? phase,
    bool? forceUpdateEnabled,
    bool? softUpdateEnabled,
    AppUpdateInfo? info,
    bool clearInfo = false,
    double? downloadProgress,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AppUpdateState(
      phase: phase ?? this.phase,
      forceUpdateEnabled: forceUpdateEnabled ?? this.forceUpdateEnabled,
      softUpdateEnabled: softUpdateEnabled ?? this.softUpdateEnabled,
      info: clearInfo ? null : (info ?? this.info),
      downloadProgress: downloadProgress ?? this.downloadProgress,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        phase,
        forceUpdateEnabled,
        softUpdateEnabled,
        info,
        downloadProgress,
        errorMessage,
      ];
}
