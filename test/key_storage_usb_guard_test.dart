import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:technical_team/core/security/key_binding_material_provider.dart';
import 'package:technical_team/core/security/key_package_crypto_service.dart';
import 'package:technical_team/core/security/secure_key_exceptions.dart';
import 'package:technical_team/core/security/usb_device_info.dart';
import 'package:technical_team/core/security/usb_device_service.dart';
import 'package:technical_team/core/services/key_storage_service.dart';
import 'package:technical_team/core/services/key_generation_service.dart';
import 'package:technical_team/features/key_management/domain/usecases/validate_usb_bound_key.dart';

class _FakeUsbDeviceService implements UsbDeviceService {
  UsbDeviceInfo? currentDevice;
  String fingerprint = List.filled(64, 'a').join();

  @override
  Future<List<UsbDeviceInfo>> getConnectedUsbDevices() async =>
      currentDevice == null ? [] : [currentDevice!];

  @override
  Future<UsbDeviceInfo?> getDeviceForPath(String path) async {
    final current = currentDevice;
    if (current == null) return null;
    final normalizedPath = path.replaceAll('/', '\\').toUpperCase();
    var root = current.rootPath.replaceAll('/', '\\').toUpperCase();
    while (root.endsWith('\\')) {
      root = root.substring(0, root.length - 1);
    }
    return normalizedPath == root || normalizedPath.startsWith('$root\\')
        ? current
        : null;
  }

  @override
  Future<String> getStableDeviceFingerprint(UsbDeviceInfo device) async =>
      fingerprint;

  @override
  Future<bool> isRemovableUsbPath(String path) async =>
      await getDeviceForPath(path) != null;
}

class _FailNewInstallOperations implements KeyFileTransactionOperations {
  var failed = false;

  @override
  Future<void> renameDirectory(String source, String destination) async {
    if (!failed && source.contains('.staging')) {
      failed = true;
      throw FileSystemException('simulated install failure', source);
    }
    await Directory(source).rename(destination);
  }
}

void main() {
  late Directory usbRoot;
  late _FakeUsbDeviceService usbService;
  late KeyPackageCryptoService crypto;
  late ValidateUsbBoundKey validator;
  late KeyStorageService storage;
  late UsbDeviceInfo selectedDevice;

  UsbDeviceInfo deviceAt(String root, {String serial = 'SERIAL-123'}) =>
      UsbDeviceInfo(
        driveLetter: 'E:',
        rootPath: root,
        physicalSerialNumber: serial,
        pnpDeviceId: 'PNP-123',
        vendorId: '1234',
        productId: '5678',
        volumeLabel: 'TEST USB',
        isRemovable: true,
        totalBytes: 100 * 1024 * 1024,
        freeBytes: 50 * 1024 * 1024,
      );

  Future<PendingUsbBoundKey> stage({String username = 'employee'}) async {
    final keys = await KeyGenerationService().generateKeys();
    return storage.stageEmployeeKeys(
      selectedDevice: selectedDevice,
      username: username,
      privateKeyBytes: keys.privateKeyBytes,
      publicKey: keys.publicKey,
      pin: '123456',
    );
  }

  setUp(() async {
    usbRoot = await Directory.systemTemp.createTemp('usb_binding_test_');
    selectedDevice = deviceAt(usbRoot.path);
    usbService = _FakeUsbDeviceService()..currentDevice = selectedDevice;
    crypto = KeyPackageCryptoService(LocalKeyBindingMaterialProvider());
    validator = ValidateUsbBoundKey(
      usbService,
      crypto,
      const NoBackendBindingTokenVerifier(),
    );
    storage = KeyStorageService(usbService, crypto, validator);
  });

  tearDown(() async {
    if (await usbRoot.exists()) await usbRoot.delete(recursive: true);
  });

  test('original USB and correct PIN validate successfully', () async {
    final pending = await stage();
    final result = await validator(
      keyDirectoryPath: pending.stagingDirectoryPath,
      pin: '123456',
    );

    expect(result.integrityVerified, isTrue);
    expect(result.usbBindingVerified, isTrue);
    expect(result.publicKeyVerified, isTrue);
    expect(result.metadataVersion, 2);
  });

  test('wrong PIN is rejected', () async {
    final pending = await stage();
    expect(
      () => validator(
        keyDirectoryPath: pending.stagingDirectoryPath,
        pin: '654321',
      ),
      throwsA(isA<KeyDecryptionFailedException>()),
    );
  });

  test('same USB at a different root remains valid', () async {
    final pending = await stage();
    final newRoot = await Directory.systemTemp.createTemp('usb_new_letter_');
    addTearDown(() async {
      if (await newRoot.exists()) await newRoot.delete(recursive: true);
    });
    final destination = Directory(
      '${newRoot.path}${Platform.pathSeparator}DirectorateSecureKeys'
      '${Platform.pathSeparator}.staging${Platform.pathSeparator}'
      '${pending.clientKeyId}',
    );
    await destination.parent.create(recursive: true);
    await Directory(pending.stagingDirectoryPath).rename(destination.path);
    usbService.currentDevice = deviceAt(newRoot.path);

    final result = await validator(
      keyDirectoryPath: destination.path,
      pin: '123456',
    );
    expect(result.usbBindingVerified, isTrue);
  });

  test('another USB is rejected before decryption', () async {
    final pending = await stage();
    usbService.fingerprint = List.filled(64, 'b').join();
    expect(
      () => validator(
        keyDirectoryPath: pending.stagingDirectoryPath,
        pin: '123456',
      ),
      throwsA(isA<KeyBoundToAnotherUsbException>()),
    );
  });

  test('a Desktop copy is rejected', () async {
    final pending = await stage();
    final desktop = await Directory.systemTemp.createTemp('desktop_copy_');
    addTearDown(() async {
      if (await desktop.exists()) await desktop.delete(recursive: true);
    });
    for (final entity in Directory(pending.stagingDirectoryPath).listSync()) {
      if (entity is File) {
        await entity.copy(
          '${desktop.path}${Platform.pathSeparator}'
          '${entity.uri.pathSegments.last}',
        );
      }
    }

    expect(
      () => validator(keyDirectoryPath: desktop.path, pin: '123456'),
      throwsA(isA<KeyMustRemainOnUsbException>()),
    );
  });

  test('metadata tampering is rejected by AAD', () async {
    final pending = await stage();
    final file = File(
      '${pending.stagingDirectoryPath}${Platform.pathSeparator}employee-key.meta',
    );
    final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    json['username'] = 'attacker';
    await file.writeAsString(jsonEncode(json));

    expect(
      () => validator(
        keyDirectoryPath: pending.stagingDirectoryPath,
        pin: '123456',
      ),
      throwsA(isA<KeyDecryptionFailedException>()),
    );
  });

  test('ciphertext tampering is rejected', () async {
    final pending = await stage();
    final file = File(
      '${pending.stagingDirectoryPath}${Platform.pathSeparator}employee-key.enc',
    );
    final bytes = base64Decode(await file.readAsString());
    bytes[0] ^= 0xff;
    await file.writeAsString(base64Encode(bytes));

    expect(
      () => validator(
        keyDirectoryPath: pending.stagingDirectoryPath,
        pin: '123456',
      ),
      throwsA(isA<KeyDecryptionFailedException>()),
    );
  });

  test('replacing public PEM is rejected', () async {
    final pending = await stage();
    await File(
      '${pending.stagingDirectoryPath}${Platform.pathSeparator}employee-public.pem',
    ).writeAsString('different public key');

    expect(
      () => validator(
        keyDirectoryPath: pending.stagingDirectoryPath,
        pin: '123456',
      ),
      throwsA(isA<KeyIntegrityCheckFailedException>()),
    );
  });

  test('missing files are rejected', () async {
    final pending = await stage();
    await File(
      '${pending.stagingDirectoryPath}${Platform.pathSeparator}employee-key.enc',
    ).delete();
    expect(
      () => validator(
        keyDirectoryPath: pending.stagingDirectoryPath,
        pin: '123456',
      ),
      throwsA(isA<InvalidKeyPackageException>()),
    );
  });

  test('metadata version 1 is rejected as legacy', () async {
    final pending = await stage();
    final file = File(
      '${pending.stagingDirectoryPath}${Platform.pathSeparator}employee-key.meta',
    );
    final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    json['version'] = 1;
    await file.writeAsString(jsonEncode(json));
    expect(
      () => validator(
        keyDirectoryPath: pending.stagingDirectoryPath,
        pin: '123456',
      ),
      throwsA(isA<LegacyKeyPackageException>()),
    );
  });

  test('discard removes staging after backend failure', () async {
    final pending = await stage();
    await storage.discardStagedKey(pending);
    expect(await Directory(pending.stagingDirectoryPath).exists(), isFalse);
  });

  test('failed new install restores the previous key directory', () async {
    final oldPending = await stage();
    await storage.commitStagedKey(pendingKey: oldPending, pin: '123456');
    final marker = File(
      '${oldPending.finalDirectoryPath}${Platform.pathSeparator}old.marker',
    );
    await marker.writeAsString('old');

    final operations = _FailNewInstallOperations();
    storage = KeyStorageService(usbService, crypto, validator, operations);
    final newPending = await stage();

    expect(
      () => storage.commitStagedKey(
        pendingKey: newPending,
        pin: '123456',
      ),
      throwsA(isA<UsbWriteFailedException>()),
    );
    expect(await marker.exists(), isTrue);
  });

  test('disconnect during validation fails safely', () async {
    final pending = await stage();
    usbService.currentDevice = null;
    expect(
      () => validator(
        keyDirectoryPath: pending.stagingDirectoryPath,
        pin: '123456',
      ),
      throwsA(isA<KeyMustRemainOnUsbException>()),
    );
  });
}
