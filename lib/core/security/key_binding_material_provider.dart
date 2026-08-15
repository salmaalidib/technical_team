import 'dart:convert';

import 'package:cryptography/cryptography.dart';

import 'secure_key_exceptions.dart';

abstract class KeyBindingMaterialProvider {
  Future<SecretKey> deriveEncryptionKey({
    required String pin,
    required String usbFingerprintHash,
    required List<int> salt,
  });
}

class LocalKeyBindingMaterialProvider implements KeyBindingMaterialProvider {
  final _hkdf = Hkdf(hmac: Hmac.sha256(), outputLength: 32);

  @override
  Future<SecretKey> deriveEncryptionKey({
    required String pin,
    required String usbFingerprintHash,
    required List<int> salt,
  }) {
    final inputMaterial = utf8.encode(
      'pinLength=${pin.length}:$pin|usbSha256=$usbFingerprintHash',
    );
    return _hkdf.deriveKey(
      secretKey: SecretKey(inputMaterial),
      nonce: salt,
      info: utf8.encode('technical-team/usb-bound-key/v2'),
    );
  }
}

abstract class BackendBindingTokenVerifier {
  Future<void> verify(SecureKeyMetadataView metadata);
}

class SecureKeyMetadataView {
  final String clientKeyId;
  final String username;
  final String usbFingerprintHash;
  final String publicKeyFingerprint;
  final String? bindingToken;

  const SecureKeyMetadataView({
    required this.clientKeyId,
    required this.username,
    required this.usbFingerprintHash,
    required this.publicKeyFingerprint,
    required this.bindingToken,
  });
}

class NoBackendBindingTokenVerifier implements BackendBindingTokenVerifier {
  const NoBackendBindingTokenVerifier();

  @override
  Future<void> verify(SecureKeyMetadataView metadata) async {
    if (metadata.bindingToken != null) {
      throw const KeyIntegrityCheckFailedException();
    }
  }
}
