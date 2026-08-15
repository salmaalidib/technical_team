import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:technical_team/core/security/secure_key_exceptions.dart';
import 'package:technical_team/core/security/usb_device_info.dart';
import 'package:technical_team/core/security/windows_usb_device_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('technical_team/usb_devices');
  final service = WindowsUsbDeviceService();

  const supportedDevice = <String, Object?>{
    'driveLetter': 'E:',
    'rootPath': r'E:\',
    'physicalSerialNumber': 'SERIAL-123',
    'pnpDeviceId': r'USBSTOR\DISK&VEN_TEST&PROD_FLASH\SERIAL-123',
    'vendorId': '1234',
    'productId': '5678',
    'volumeLabel': 'KEY USB',
    'isRemovable': true,
    'totalBytes': 16000000000,
    'freeBytes': 8000000000,
  };

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'getConnectedUsbDevices');
      return [supportedDevice];
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('internal and desktop paths are not resolved as USB', () async {
    expect(await service.getDeviceForPath(r'C:\'), isNull);
    expect(
      await service.getDeviceForPath(r'C:\Users\User\Desktop\key.dkey'),
      isNull,
    );
    expect(await service.isRemovableUsbPath(r'D:\keys'), isFalse);
  });

  test('a path under the enumerated removable USB is accepted', () async {
    final device = await service.getDeviceForPath(
      r'E:\DirectorateSecureKeys\user.dkey',
    );
    expect(device?.physicalSerialNumber, 'SERIAL-123');
    expect(device?.isSupported, isTrue);
  });

  test('stable fingerprint does not include the drive letter', () async {
    final first = UsbDeviceInfo.fromMap(supportedDevice);
    final second = UsbDeviceInfo.fromMap({
      ...supportedDevice,
      'driveLetter': 'F:',
      'rootPath': r'F:\',
    });

    expect(
      await service.getStableDeviceFingerprint(first),
      await service.getStableDeviceFingerprint(second),
    );
  });

  test('USB without a reliable serial is unsupported', () async {
    final device = UsbDeviceInfo.fromMap({
      ...supportedDevice,
      'physicalSerialNumber': '',
    });

    expect(device.isSupported, isFalse);
    expect(
      () => service.getStableDeviceFingerprint(device),
      throwsA(isA<UsbFingerprintUnavailableException>()),
    );
  });
}
