import '../../../core/di/injection.dart';
import '../../../core/services/api_service.dart';

import '../data/datasources/notification_remote_data_source.dart';
import '../data/repositories/notification_repository_impl.dart';
import '../domain/repositories/notification_repository.dart';
import '../domain/usecases/get_my_notifications_usecase.dart';
import '../domain/usecases/mark_notification_read_usecase.dart';
import '../domain/usecases/mark_notifications_read_usecase.dart';
import '../presentation/cubit/notifications_cubit.dart';

Future<void> setupNotificationsInjection() async {
  if (!getIt.isRegistered<NotificationRemoteDataSource>()) {
    getIt.registerLazySingleton<NotificationRemoteDataSource>(
      () => NotificationRemoteDataSource(getIt<ApiService>()),
    );
  }

  if (!getIt.isRegistered<NotificationRepository>()) {
    getIt.registerLazySingleton<NotificationRepository>(
      () => NotificationRepositoryImpl(getIt<NotificationRemoteDataSource>()),
    );
  }

  if (!getIt.isRegistered<GetMyNotificationsUseCase>()) {
    getIt.registerLazySingleton<GetMyNotificationsUseCase>(
      () => GetMyNotificationsUseCase(getIt<NotificationRepository>()),
    );
  }

  if (!getIt.isRegistered<MarkNotificationReadUseCase>()) {
    getIt.registerLazySingleton<MarkNotificationReadUseCase>(
      () => MarkNotificationReadUseCase(getIt<NotificationRepository>()),
    );
  }

  if (!getIt.isRegistered<MarkNotificationsReadUseCase>()) {
    getIt.registerLazySingleton<MarkNotificationsReadUseCase>(
      () => MarkNotificationsReadUseCase(getIt<NotificationRepository>()),
    );
  }

  // Singleton لا factory: الشارة في الشريط العلوي والقائمة المنسدلة وحدثُ
  // الـ WebSocket كلها تشترك في نفس الحالة.
  if (!getIt.isRegistered<NotificationsCubit>()) {
    getIt.registerLazySingleton<NotificationsCubit>(
      () => NotificationsCubit(
        getMyNotifications: getIt<GetMyNotificationsUseCase>(),
        markRead: getIt<MarkNotificationReadUseCase>(),
        markManyRead: getIt<MarkNotificationsReadUseCase>(),
      ),
    );
  }
}
