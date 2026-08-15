import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

import 'key_binding_material_provider.dart';
import 'secure_key_exceptions.dart';
import 'secure_key_package.dart';

class EncryptedKeyPackageData {
  final Uint8List cipherText;
  final SecureKeyMetadata metadata;

  const EncryptedKeyPackageData({
    required this.cipherText,
    required this.metadata,
  });
}

class KeyPackageCryptoService {
  final KeyBindingMaterialProvider _bindingMaterialProvider;
  final _aes = AesGcm.with256bits();
  final _sha256 = Sha256();
  final _random = Random.secure();

  KeyPackageCryptoService(this._bindingMaterialProvider);

  Future<EncryptedKeyPackageData> encryptPrivateKey({
    required Uint8List privateKeyBytes,
    required String pin,
    required String username,
    required String publicKey,
    required String usbFingerprintHash,
    required String clientKeyId,
    required DateTime createdAt,
  }) async {
    final salt = _randomBytes(32);
    final nonce = _randomBytes(12);
    final publicKeyFingerprint = await fingerprintPublicKey(publicKey);

    var metadata = SecureKeyMetadata(
      version: SecureKeyMetadata.supportedVersion,
      packageVersion: SecureKeyMetadata.supportedVersion,
      clientKeyId: clientKeyId,
      username: username,
      algorithm: 'AES-256-GCM',
      keyAlgorithm: 'Ed25519',
      kdf: 'HKDF-SHA256',
      usbFingerprintHash: usbFingerprintHash,
      publicKeyFingerprint: publicKeyFingerprint,
      salt: base64Encode(salt),
      nonce: base64Encode(nonce),
      mac: '',
      createdAt: createdAt.toUtc().toIso8601String(),
      bindingToken: null,
    );

    final secretKey = await _bindingMaterialProvider.deriveEncryptionKey(
      pin: pin,
      usbFingerprintHash: usbFingerprintHash,
      salt: salt,
    );
    final secretBox = await _aes.encrypt(
      privateKeyBytes,
      secretKey: secretKey,
      nonce: nonce,
      aad: metadata.canonicalAad(),
    );
    metadata = SecureKeyMetadata(
      version: metadata.version,
      packageVersion: metadata.packageVersion,
      clientKeyId: metadata.clientKeyId,
      username: metadata.username,
      algorithm: metadata.algorithm,
      keyAlgorithm: metadata.keyAlgorithm,
      kdf: metadata.kdf,
      usbFingerprintHash: metadata.usbFingerprintHash,
      publicKeyFingerprint: metadata.publicKeyFingerprint,
      salt: metadata.salt,
      nonce: metadata.nonce,
      mac: base64Encode(secretBox.mac.bytes),
      createdAt: metadata.createdAt,
      bindingToken: metadata.bindingToken,
    );

    return EncryptedKeyPackageData(
      cipherText: Uint8List.fromList(secretBox.cipherText),
      metadata: metadata,
    );
  }

  Future<Uint8List> decryptPrivateKey({
    required Uint8List cipherText,
    required SecureKeyMetadata metadata,
    required String pin,
  }) async {
    try {
      final salt = base64Decode(metadata.salt);
      final nonce = base64Decode(metadata.nonce);
      final mac = Mac(base64Decode(metadata.mac));
      final secretKey = await _bindingMaterialProvider.deriveEncryptionKey(
        pin: pin,
        usbFingerprintHash: metadata.usbFingerprintHash,
        salt: salt,
      );
      final clearText = await _aes.decrypt(
        SecretBox(cipherText, nonce: nonce, mac: mac),
        secretKey: secretKey,
        aad: metadata.canonicalAad(),
      );
      return Uint8List.fromList(clearText);
    } on SecretBoxAuthenticationError {
      throw const KeyDecryptionFailedException();
    } on FormatException {
      throw const InvalidKeyPackageException();
    } on ArgumentError {
      throw const InvalidKeyPackageException();
    }
  }

  Future<String> fingerprintPublicKey(String publicKey) async {
    final hash = await _sha256.hash(utf8.encode(publicKey));
    return _hex(hash.bytes);
  }

  Future<bool> privateKeyMatchesPublicKey(
    Uint8List privateKeyBytes,
    String publicKeyPem,
  ) async {
    try {
      final keyPair = await Ed25519().newKeyPairFromSeed(privateKeyBytes);
      final derivedPublicKey = await keyPair.extractPublicKey();
      final pemBody = publicKeyPem
          .replaceAll('-----BEGIN PUBLIC KEY-----', '')
          .replaceAll('-----END PUBLIC KEY-----', '')
          .replaceAll(RegExp(r'\s+'), '');
      final der = base64Decode(pemBody);
      if (der.length < derivedPublicKey.bytes.length) return false;
      final pemRawKey = der.sublist(der.length - derivedPublicKey.bytes.length);
      var difference = 0;
      for (var index = 0; index < pemRawKey.length; index++) {
        difference |= pemRawKey[index] ^ derivedPublicKey.bytes[index];
      }
      return difference == 0;
    } on FormatException {
      return false;
    } on ArgumentError {
      return false;
    }
  }

  String generateClientKeyId() {
    final bytes = _randomBytes(16);
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = _hex(bytes);
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-'
        '${hex.substring(20)}';
  }

  Uint8List _randomBytes(int length) =>
      Uint8List.fromList(List.generate(length, (_) => _random.nextInt(256)));

  String _hex(List<int> bytes) =>
      bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
}
