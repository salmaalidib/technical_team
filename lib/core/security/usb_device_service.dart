import 'usb_device_info.dart';

abstract class UsbDeviceService {
  Future<List<UsbDeviceInfo>> getConnectedUsbDevices();

  Future<UsbDeviceInfo?> getDeviceForPath(String path);

  Future<bool> isRemovableUsbPath(String path);

  Future<String> getStableDeviceFingerprint(UsbDeviceInfo device);
}
