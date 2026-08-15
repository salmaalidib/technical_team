import 'dart:convert';

class SecureKeyMetadata {
  static const supportedVersion = 2;

  final int version;
  final int packageVersion;
  final String clientKeyId;
  final String username;
  final String algorithm;
  final String keyAlgorithm;
  final String kdf;
  final String usbFingerprintHash;
  final String publicKeyFingerprint;
  final String salt;
  final String nonce;
  final String mac;
  final String createdAt;
  final String? bindingToken;

  const SecureKeyMetadata({
    required this.version,
    required this.packageVersion,
    required this.clientKeyId,
    required this.username,
    required this.algorithm,
    required this.keyAlgorithm,
    required this.kdf,
    required this.usbFingerprintHash,
    required this.publicKeyFingerprint,
    required this.salt,
    required this.nonce,
    required this.mac,
    required this.createdAt,
    required this.bindingToken,
  });

  Map<String, Object?> toJson() => {
        'version': version,
        'package_version': packageVersion,
        'client_key_id': clientKeyId,
        'username': username,
        'algorithm': algorithm,
        'key_algorithm': keyAlgorithm,
        'kdf': kdf,
        'usb_fingerprint_hash': usbFingerprintHash,
        'public_key_fingerprint': publicKeyFingerprint,
        'salt': salt,
        'nonce': nonce,
        'mac': mac,
        'created_at': createdAt,
        'binding_token': bindingToken,
      };

  factory SecureKeyMetadata.fromJson(Map<String, Object?> json) {
    String requiredString(String key) {
      final value = json[key];
      if (value is! String || value.trim().isEmpty) {
        throw FormatException('Missing metadata field: $key');
      }
      return value;
    }

    final version = json['version'];
    final packageVersion = json['package_version'];
    if (version is! int || packageVersion is! int) {
      throw const FormatException('Invalid metadata version');
    }

    return SecureKeyMetadata(
      version: version,
      packageVersion: packageVersion,
      clientKeyId: requiredString('client_key_id'),
      username: requiredString('username'),
      algorithm: requiredString('algorithm'),
      keyAlgorithm: requiredString('key_algorithm'),
      kdf: requiredString('kdf'),
      usbFingerprintHash: requiredString('usb_fingerprint_hash'),
      publicKeyFingerprint: requiredString('public_key_fingerprint'),
      salt: requiredString('salt'),
      nonce: requiredString('nonce'),
      mac: requiredString('mac'),
      createdAt: requiredString('created_at'),
      bindingToken: json['binding_token'] as String?,
    );
  }

  List<int> canonicalAad() => utf8.encode(jsonEncode({
        'version': version,
        'packageVersion': packageVersion,
        'clientKeyId': clientKeyId,
        'username': username,
        'algorithm': algorithm,
        'keyAlgorithm': keyAlgorithm,
        'kdf': kdf,
        'usbFingerprintHash': usbFingerprintHash,
        'publicKeyFingerprint': publicKeyFingerprint,
        'createdAt': createdAt,
      }));
}

class KeyValidationResult {
  final String clientKeyId;
  final String username;
  final String publicKey;
  final String publicKeyFingerprint;
  final String usbFingerprintHash;
  final DateTime createdAt;
  final int metadataVersion;
  final bool integrityVerified;
  final bool usbBindingVerified;
  final bool publicKeyVerified;

  const KeyValidationResult({
    required this.clientKeyId,
    required this.username,
    required this.publicKey,
    required this.publicKeyFingerprint,
    required this.usbFingerprintHash,
    required this.createdAt,
    required this.metadataVersion,
    required this.integrityVerified,
    required this.usbBindingVerified,
    required this.publicKeyVerified,
  });
}
