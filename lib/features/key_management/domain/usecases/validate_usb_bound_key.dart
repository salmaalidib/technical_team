import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import '../../../../core/security/key_binding_material_provider.dart';
import '../../../../core/security/key_package_crypto_service.dart';
import '../../../../core/security/secure_key_exceptions.dart';
import '../../../../core/security/secure_key_package.dart';
import '../../../../core/security/usb_device_service.dart';

class ValidateUsbBoundKey {
  static const keyDirectoryName = 'DirectorateSecureKeys';

  final UsbDeviceService _usbDeviceService;
  final KeyPackageCryptoService _cryptoService;
  final BackendBindingTokenVerifier _bindingTokenVerifier;

  const ValidateUsbBoundKey(
    this._usbDeviceService,
    this._cryptoService,
    this._bindingTokenVerifier,
  );

  Future<KeyValidationResult> call({
    required String keyDirectoryPath,
    required String pin,
  }) async {
    final device = await _usbDeviceService.getDeviceForPath(keyDirectoryPath);
    if (device == null || !device.isRemovable) {
      throw const KeyMustRemainOnUsbException();
    }
    if (!device.isSupported) throw const UnsupportedUsbDeviceException();
    if (!_isInsideSecureRoot(keyDirectoryPath, device.rootPath)) {
      throw const KeyMustRemainOnUsbException();
    }

    final sep = Platform.pathSeparator;
    final directory = Directory(keyDirectoryPath);
    final encryptedFile = File('${directory.path}${sep}employee-key.enc');
    final metadataFile = File('${directory.path}${sep}employee-key.meta');
    final publicKeyFile = File('${directory.path}${sep}employee-public.pem');
    if (!await encryptedFile.exists() ||
        !await metadataFile.exists() ||
        !await publicKeyFile.exists()) {
      throw const InvalidKeyPackageException();
    }

    final SecureKeyMetadata metadata;
    try {
      final decoded = jsonDecode(await metadataFile.readAsString());
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException();
      }
      final version = decoded['version'];
      if (version != SecureKeyMetadata.supportedVersion ||
          decoded['usb_fingerprint_hash'] == null ||
          decoded['public_key_fingerprint'] == null) {
        throw const LegacyKeyPackageException();
      }
      metadata = SecureKeyMetadata.fromJson(decoded);
    } on LegacyKeyPackageException {
      rethrow;
    } on FormatException {
      throw const InvalidKeyPackageException();
    }

    if (metadata.packageVersion != SecureKeyMetadata.supportedVersion ||
        metadata.algorithm != 'AES-256-GCM' ||
        metadata.keyAlgorithm != 'Ed25519' ||
        metadata.kdf != 'HKDF-SHA256') {
      throw const InvalidKeyPackageException();
    }

    final currentUsbFingerprint =
        await _usbDeviceService.getStableDeviceFingerprint(device);
    if (!_constantTimeEquals(
      currentUsbFingerprint,
      metadata.usbFingerprintHash,
    )) {
      throw const KeyBoundToAnotherUsbException();
    }

    final publicKey = await publicKeyFile.readAsString();
    final currentPublicKeyFingerprint =
        await _cryptoService.fingerprintPublicKey(publicKey);
    if (!_constantTimeEquals(
      currentPublicKeyFingerprint,
      metadata.publicKeyFingerprint,
    )) {
      throw const KeyIntegrityCheckFailedException();
    }

    await _bindingTokenVerifier.verify(
      SecureKeyMetadataView(
        clientKeyId: metadata.clientKeyId,
        username: metadata.username,
        usbFingerprintHash: metadata.usbFingerprintHash,
        publicKeyFingerprint: metadata.publicKeyFingerprint,
        bindingToken: metadata.bindingToken,
      ),
    );

    Uint8List? decryptedBytes;
    try {
      final cipherText = Uint8List.fromList(
        base64Decode(await encryptedFile.readAsString()),
      );
      decryptedBytes = await _cryptoService.decryptPrivateKey(
        cipherText: cipherText,
        metadata: metadata,
        pin: pin,
      );
      if (decryptedBytes.isEmpty) {
        throw const KeyIntegrityCheckFailedException();
      }
      if (!await _cryptoService.privateKeyMatchesPublicKey(
        decryptedBytes,
        publicKey,
      )) {
        throw const KeyIntegrityCheckFailedException();
      }
    } on FormatException {
      throw const InvalidKeyPackageException();
    } finally {
      decryptedBytes?.fillRange(0, decryptedBytes.length, 0);
    }

    final createdAt = DateTime.tryParse(metadata.createdAt);
    if (createdAt == null) throw const InvalidKeyPackageException();
    return KeyValidationResult(
      clientKeyId: metadata.clientKeyId,
      username: metadata.username,
      publicKey: publicKey,
      publicKeyFingerprint: metadata.publicKeyFingerprint,
      usbFingerprintHash: metadata.usbFingerprintHash,
      createdAt: createdAt,
      metadataVersion: metadata.version,
      integrityVerified: true,
      usbBindingVerified: true,
      publicKeyVerified: true,
    );
  }

  bool _isInsideSecureRoot(String path, String rootPath) {
    String normalize(String value) {
      var result = value.replaceAll('/', '\\').toUpperCase();
      while (result.endsWith('\\')) {
        result = result.substring(0, result.length - 1);
      }
      return result;
    }

    final normalizedRoot = normalize(rootPath);
    final secureRoot = '$normalizedRoot\\${keyDirectoryName.toUpperCase()}';
    final normalizedPath = normalize(path);
    return normalizedPath == secureRoot ||
        normalizedPath.startsWith('$secureRoot\\');
  }

  bool _constantTimeEquals(String left, String right) {
    var difference = left.length ^ right.length;
    final length = left.length > right.length ? left.length : right.length;
    for (var index = 0; index < length; index++) {
      final leftCode = index < left.length ? left.codeUnitAt(index) : 0;
      final rightCode = index < right.length ? right.codeUnitAt(index) : 0;
      difference |= leftCode ^ rightCode;
    }
    return difference == 0;
  }
}
