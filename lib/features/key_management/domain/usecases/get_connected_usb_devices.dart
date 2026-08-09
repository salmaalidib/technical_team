import '../../../../core/security/usb_device_info.dart';
import '../../../../core/security/usb_device_service.dart';

class GetConnectedUsbDevices {
  final UsbDeviceService _service;

  const GetConnectedUsbDevices(this._service);

  Future<List<UsbDeviceInfo>> call() => _service.getConnectedUsbDevices();
}
