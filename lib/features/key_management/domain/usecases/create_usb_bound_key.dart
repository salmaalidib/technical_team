import 'dart:typed_data';

import '../../../../core/security/usb_device_info.dart';
import '../../../../core/services/key_storage_service.dart';

class CreateUsbBoundKey {
  final KeyStorageService _storageService;

  const CreateUsbBoundKey(this._storageService);

  Future<PendingUsbBoundKey> call({
    required UsbDeviceInfo selectedDevice,
    required String username,
    required Uint8List privateKeyBytes,
    required String publicKey,
    required String pin,
  }) =>
      _storageService.stageEmployeeKeys(
        selectedDevice: selectedDevice,
        username: username,
        privateKeyBytes: privateKeyBytes,
        publicKey: publicKey,
        pin: pin,
      );
}
