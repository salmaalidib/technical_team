import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import '../active_org/active_organization_cubit.dart';
import '../services/key_generation_service.dart';
import '../network/dio_client.dart';
import '../services/key_storage_service.dart';
import '../security/usb_device_service.dart';
import '../security/windows_usb_device_service.dart';
import '../security/key_binding_material_provider.dart';
import '../security/key_package_crypto_service.dart';
import '../services/push_socket.dart';
import '../services/token_refresh_service.dart';
import '../services/whatsapp_service.dart';
import '../services/api_service.dart';
import '../storage/secure_storage_service.dart';
import '../../features/key_management/domain/usecases/get_connected_usb_devices.dart';
import '../../features/key_management/domain/usecases/create_usb_bound_key.dart';
import '../../features/key_management/domain/usecases/validate_usb_bound_key.dart';

final getIt = GetIt.instance;

Future<void> setupCoreInjection() async {
  // Storage must be registered before Dio: the AuthInterceptor depends on it.
  if (!getIt.isRegistered<SecureStorageService>()) {
    getIt.registerLazySingleton<SecureStorageService>(
      () => SecureStorageService(),
    );
  }

  // Shared token-refresh service. Registered before Dio because the
  // AuthInterceptor (built inside DioClient.create) needs it. It's a singleton
  // so its single-in-flight coalescing is shared with PushSocket — a 401 here
  // and a socket reconnect can never trigger two concurrent refresh calls.
  if (!getIt.isRegistered<TokenRefreshService>()) {
    getIt.registerLazySingleton<TokenRefreshService>(
      () => TokenRefreshService(storage: getIt<SecureStorageService>()),
    );
  }

  if (!getIt.isRegistered<Dio>()) {
    getIt.registerLazySingleton<Dio>(
      () => DioClient.create(
        getIt<SecureStorageService>(),
        getIt<TokenRefreshService>(),
      ),
    );
  }

  // The single network gateway shared by every feature's data source.
  if (!getIt.isRegistered<ApiService>()) {
    getIt.registerLazySingleton<ApiService>(
      () => ApiService(getIt<Dio>()),
    );
  }

  if (!getIt.isRegistered<KeyGenerationService>()) {
    getIt.registerLazySingleton<KeyGenerationService>(
      () => KeyGenerationService(),
    );
  }

  if (!getIt.isRegistered<UsbDeviceService>()) {
    getIt.registerLazySingleton<UsbDeviceService>(
      () => WindowsUsbDeviceService(),
    );
  }

  if (!getIt.isRegistered<GetConnectedUsbDevices>()) {
    getIt.registerLazySingleton<GetConnectedUsbDevices>(
      () => GetConnectedUsbDevices(getIt<UsbDeviceService>()),
    );
  }

  if (!getIt.isRegistered<KeyBindingMaterialProvider>()) {
    getIt.registerLazySingleton<KeyBindingMaterialProvider>(
      () => LocalKeyBindingMaterialProvider(),
    );
  }

  if (!getIt.isRegistered<BackendBindingTokenVerifier>()) {
    getIt.registerLazySingleton<BackendBindingTokenVerifier>(
      () => const NoBackendBindingTokenVerifier(),
    );
  }

  if (!getIt.isRegistered<KeyPackageCryptoService>()) {
    getIt.registerLazySingleton<KeyPackageCryptoService>(
      () => KeyPackageCryptoService(getIt<KeyBindingMaterialProvider>()),
    );
  }

  if (!getIt.isRegistered<ValidateUsbBoundKey>()) {
    getIt.registerLazySingleton<ValidateUsbBoundKey>(
      () => ValidateUsbBoundKey(
        getIt<UsbDeviceService>(),
        getIt<KeyPackageCryptoService>(),
        getIt<BackendBindingTokenVerifier>(),
      ),
    );
  }

  if (!getIt.isRegistered<KeyStorageService>()) {
    getIt.registerLazySingleton<KeyStorageService>(
      () => KeyStorageService(
        getIt<UsbDeviceService>(),
        getIt<KeyPackageCryptoService>(),
        getIt<ValidateUsbBoundKey>(),
      ),
    );
  }

  if (!getIt.isRegistered<CreateUsbBoundKey>()) {
    getIt.registerLazySingleton<CreateUsbBoundKey>(
      () => CreateUsbBoundKey(getIt<KeyStorageService>()),
    );
  }

  if (!getIt.isRegistered<WhatsAppService>()) {
    getIt.registerLazySingleton<WhatsAppService>(
      () => WhatsAppService(),
    );
  }

  // The single source of truth for the user's active organization. It resolves
  // GetInstitutionsUseCase lazily inside load(), so registration order relative
  // to setupInstitutionsInjection doesn't matter.
  if (!getIt.isRegistered<ActiveOrganizationCubit>()) {
    getIt.registerLazySingleton<ActiveOrganizationCubit>(
      () => ActiveOrganizationCubit(getIt<SecureStorageService>()),
    );
  }

  // اتصال إشعارات الـ WebSocket (بديل FCM على سطح مكتب Windows). يقرأ التوكن من
  // SecureStorageService ويعرض الإشعارات عبر NotificationService. يُبدأ صراحةً
  // من main عبر start() بعد تهيئة الإشعارات والـ tray.
  if (!getIt.isRegistered<PushSocket>()) {
    getIt.registerLazySingleton<PushSocket>(
      () => PushSocket(
        storage: getIt<SecureStorageService>(),
        refreshService: getIt<TokenRefreshService>(),
      ),
    );
  }
}
