import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import '../security/key_package_crypto_service.dart';
import '../security/secure_key_exceptions.dart';
import '../security/usb_device_info.dart';
import '../security/usb_device_service.dart';
import '../../features/key_management/domain/usecases/validate_usb_bound_key.dart';

class PendingUsbBoundKey {
  final String clientKeyId;
  final String username;
  final String publicKey;
  final String stagingDirectoryPath;
  final String finalDirectoryPath;
  final String usbFingerprintHash;

  const PendingUsbBoundKey({
    required this.clientKeyId,
    required this.username,
    required this.publicKey,
    required this.stagingDirectoryPath,
    required this.finalDirectoryPath,
    required this.usbFingerprintHash,
  });
}

abstract class KeyFileTransactionOperations {
  Future<void> renameDirectory(String source, String destination);
}

class IoKeyFileTransactionOperations implements KeyFileTransactionOperations {
  const IoKeyFileTransactionOperations();

  @override
  Future<void> renameDirectory(String source, String destination) async {
    await Directory(source).rename(destination);
  }
}

class KeyStorageService {
  static const keyDirectoryName = 'DirectorateSecureKeys';
  static const _minimumFreeBytes = 1024 * 1024;

  final UsbDeviceService _usbDeviceService;
  final KeyPackageCryptoService _cryptoService;
  final ValidateUsbBoundKey _validateUsbBoundKey;
  final KeyFileTransactionOperations _fileTransactionOperations;

  KeyStorageService(
      this._usbDeviceService, this._cryptoService, this._validateUsbBoundKey,
      [this._fileTransactionOperations =
          const IoKeyFileTransactionOperations()]);

  String generatePin() {
    final random = Random.secure();
    return List.generate(6, (_) => random.nextInt(10)).join();
  }

  String generatePassword() {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789@#\$%';
    final random = Random.secure();
    return List.generate(
      10,
      (_) => chars[random.nextInt(chars.length)],
    ).join();
  }

  Future<bool> hasExistingKey({
    required UsbDeviceInfo selectedDevice,
    required String username,
  }) async {
    final device = await _requireSameConnectedDevice(selectedDevice);
    return Directory(_finalDirectoryPath(device.rootPath, username)).exists();
  }

  Future<PendingUsbBoundKey> stageEmployeeKeys({
    required UsbDeviceInfo selectedDevice,
    required String username,
    required Uint8List privateKeyBytes,
    required String publicKey,
    required String pin,
  }) async {
    Directory? stagingDirectory;
    try {
      final device = await _requireSameConnectedDevice(selectedDevice);
      if (device.freeBytes < _minimumFreeBytes) {
        throw const UsbSecurityException(
          'لا توجد مساحة كافية على وحدة USB لحفظ المفتاح',
        );
      }

      final usbFingerprintHash =
          await _usbDeviceService.getStableDeviceFingerprint(device);
      final clientKeyId = _cryptoService.generateClientKeyId();
      final root = _withoutTrailingSeparator(device.rootPath);
      final sep = Platform.pathSeparator;
      final secureRoot = Directory('$root$sep$keyDirectoryName');
      await secureRoot.create(recursive: true);
      stagingDirectory = Directory(
        '${secureRoot.path}$sep.staging$sep$clientKeyId',
      );
      await stagingDirectory.create(recursive: true);

      final encrypted = await _cryptoService.encryptPrivateKey(
        privateKeyBytes: privateKeyBytes,
        pin: pin,
        username: username,
        publicKey: publicKey,
        usbFingerprintHash: usbFingerprintHash,
        clientKeyId: clientKeyId,
        createdAt: DateTime.now(),
      );

      await File('${stagingDirectory.path}${sep}employee-key.enc')
          .writeAsString(base64Encode(encrypted.cipherText), flush: true);
      await File('${stagingDirectory.path}${sep}employee-key.meta')
          .writeAsString(jsonEncode(encrypted.metadata.toJson()), flush: true);
      await File('${stagingDirectory.path}${sep}employee-public.pem')
          .writeAsString(publicKey, flush: true);

      await _validateUsbBoundKey(
        keyDirectoryPath: stagingDirectory.path,
        pin: pin,
      );

      return PendingUsbBoundKey(
        clientKeyId: clientKeyId,
        username: username,
        publicKey: publicKey,
        stagingDirectoryPath: stagingDirectory.path,
        finalDirectoryPath: _finalDirectoryPath(device.rootPath, username),
        usbFingerprintHash: usbFingerprintHash,
      );
    } on UsbSecurityException {
      if (stagingDirectory != null && await stagingDirectory.exists()) {
        await stagingDirectory.delete(recursive: true);
      }
      rethrow;
    } on FileSystemException {
      if (stagingDirectory != null && await stagingDirectory.exists()) {
        await stagingDirectory.delete(recursive: true);
      }
      throw const UsbWriteFailedException();
    } finally {
      privateKeyBytes.fillRange(0, privateKeyBytes.length, 0);
    }
  }

  Future<void> commitStagedKey({
    required PendingUsbBoundKey pendingKey,
    required String pin,
  }) async {
    final staging = Directory(pendingKey.stagingDirectoryPath);
    if (!await staging.exists()) throw const UsbDisconnectedException();

    final validation = await _validateUsbBoundKey(
      keyDirectoryPath: staging.path,
      pin: pin,
    );
    if (validation.clientKeyId != pendingKey.clientKeyId ||
        validation.publicKey != pendingKey.publicKey) {
      throw const KeyIntegrityCheckFailedException();
    }

    final target = Directory(pendingKey.finalDirectoryPath);
    final secureRoot = target.parent;
    final backup = Directory(
      '${secureRoot.path}${Platform.pathSeparator}.backup'
      '${Platform.pathSeparator}${pendingKey.clientKeyId}',
    );
    var oldMovedToBackup = false;
    try {
      if (await target.exists()) {
        await backup.parent.create(recursive: true);
        if (await backup.exists()) await backup.delete(recursive: true);
        await _fileTransactionOperations.renameDirectory(
          target.path,
          backup.path,
        );
        oldMovedToBackup = true;
      }
      await _fileTransactionOperations.renameDirectory(
        staging.path,
        target.path,
      );
      if (oldMovedToBackup && await backup.exists()) {
        await backup.delete(recursive: true);
      }
      await _deleteIfEmpty(backup.parent);
      await _deleteIfEmpty(staging.parent);
    } on FileSystemException {
      if (!await target.exists() && oldMovedToBackup && await backup.exists()) {
        try {
          await _fileTransactionOperations.renameDirectory(
            backup.path,
            target.path,
          );
        } on FileSystemException {
          // Keep the backup intact for manual recovery if rollback cannot run.
        }
      }
      throw const UsbWriteFailedException();
    }
  }

  Future<void> discardStagedKey(PendingUsbBoundKey? pendingKey) async {
    if (pendingKey == null) return;
    final staging = Directory(pendingKey.stagingDirectoryPath);
    try {
      if (await staging.exists()) await staging.delete(recursive: true);
      await _deleteIfEmpty(staging.parent);
    } on FileSystemException {
      // The USB may already be disconnected; no local fallback copy is made.
    }
  }

  Future<UsbDeviceInfo> _requireSameConnectedDevice(
    UsbDeviceInfo selectedDevice,
  ) async {
    final current =
        await _usbDeviceService.getDeviceForPath(selectedDevice.rootPath);
    if (current == null) throw const UsbDisconnectedException();
    if (!current.isRemovable) throw const UsbRequiredException();
    if (!current.isSupported) throw const UnsupportedUsbDeviceException();

    final selectedFingerprint =
        await _usbDeviceService.getStableDeviceFingerprint(selectedDevice);
    final currentFingerprint =
        await _usbDeviceService.getStableDeviceFingerprint(current);
    if (selectedFingerprint != currentFingerprint) {
      throw const UsbDisconnectedException();
    }
    return current;
  }

  String _finalDirectoryPath(String rootPath, String username) {
    final safeUsername = username.replaceAll(RegExp(r'[^a-zA-Z0-9_.-]'), '_');
    final root = _withoutTrailingSeparator(rootPath);
    final sep = Platform.pathSeparator;
    return '$root$sep$keyDirectoryName$sep$safeUsername-keys';
  }

  String _withoutTrailingSeparator(String path) {
    var result = path;
    while (result.endsWith(Platform.pathSeparator)) {
      result = result.substring(0, result.length - 1);
    }
    return result;
  }

  Future<void> _deleteIfEmpty(Directory directory) async {
    if (!await directory.exists()) return;
    if (!await directory.list().isEmpty) return;
    await directory.delete();
  }
}
