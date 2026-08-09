import 'dart:io';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/services.dart';

import 'secure_key_exceptions.dart';
import 'usb_device_info.dart';
import 'usb_device_service.dart';

class WindowsUsbDeviceService implements UsbDeviceService {
  static const _channel = MethodChannel('technical_team/usb_devices');

  @override
  Future<List<UsbDeviceInfo>> getConnectedUsbDevices() async {
    if (!Platform.isWindows) return const [];

    final raw =
        await _channel.invokeListMethod<Object?>('getConnectedUsbDevices') ??
            const <Object?>[];
    return raw
        .whereType<Map<Object?, Object?>>()
        .map(UsbDeviceInfo.fromMap)
        .where((device) => device.isRemovable)
        .toList(growable: false);
  }

  @override
  Future<UsbDeviceInfo?> getDeviceForPath(String path) async {
    final normalizedPath = _normalizePath(path);
    final devices = await getConnectedUsbDevices();
    for (final device in devices) {
      final root = _normalizePath(device.rootPath);
      if (normalizedPath == root || normalizedPath.startsWith('$root\\')) {
        return device;
      }
    }
    return null;
  }

  @override
  Future<bool> isRemovableUsbPath(String path) async {
    final device = await getDeviceForPath(path);
    return device?.isRemovable == true;
  }

  @override
  Future<String> getStableDeviceFingerprint(UsbDeviceInfo device) async {
    if (!device.isRemovable) throw const UsbRequiredException();
    if (!device.hasReliableSerial) {
      throw const UsbFingerprintUnavailableException();
    }

    final source = [
      device.physicalSerialNumber,
      device.pnpDeviceId,
      device.vendorId,
      device.productId,
    ].map((value) => _normalizeComponent(value ?? '')).join('|');

    final digest = await Sha256().hash(source.codeUnits);
    return digest.bytes
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();
  }

  String _normalizePath(String value) {
    var normalized = value.trim().replaceAll('/', '\\').toUpperCase();
    while (normalized.endsWith('\\')) {
      normalized = normalized.substring(0, normalized.length - 1);
    }
    return normalized;
  }

  String _normalizeComponent(String value) =>
      value.trim().toUpperCase().replaceAll(RegExp(r'\s+'), '');
}
