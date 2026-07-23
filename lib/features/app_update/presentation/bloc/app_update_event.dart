import 'package:equatable/equatable.dart';

abstract class AppUpdateEvent extends Equatable {
  const AppUpdateEvent();

  @override
  List<Object?> get props => [];
}

/// يُطلَق عند الإقلاع (splash) أو عند الضغط على "التحقق من التحديثات" يدوياً.
class CheckForUpdateRequested extends AppUpdateEvent {
  const CheckForUpdateRequested();
}

/// نقطة الدخول الموحّدة لزر "تحديث": direct → تنزيل + تثبيت، وإلا احتياطي مستقبلي.
class StartUpdateRequested extends AppUpdateEvent {
  const StartUpdateRequested();
}

class CancelUpdateRequested extends AppUpdateEvent {
  const CancelUpdateRequested();
}
