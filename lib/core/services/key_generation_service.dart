import 'dart:convert';

import 'package:cryptography/cryptography.dart';

class KeyGenerationService {
  final _algorithm = Ed25519();

  Future<KeyPairResult> generateKeys() async {
    final keyPair = await _algorithm.newKeyPair();

    final publicKey = await keyPair.extractPublicKey();
    final privateBytes = await keyPair.extractPrivateKeyBytes();

    return KeyPairResult(
      privateKey: base64Encode(privateBytes),
      publicKey: _ed25519PublicKeyToPem(publicKey.bytes),
    );
  }

  String _ed25519PublicKeyToPem(List<int> rawPublicKeyBytes) {
    const ed25519SpkiPrefix = <int>[
      0x30,
      0x2a,
      0x30,
      0x05,
      0x06,
      0x03,
      0x2b,
      0x65,
      0x70,
      0x03,
      0x21,
      0x00,
    ];

    final derBytes = [
      ...ed25519SpkiPrefix,
      ...rawPublicKeyBytes,
    ];

    return '''-----BEGIN PUBLIC KEY-----
${base64Encode(derBytes)}
-----END PUBLIC KEY-----''';
  }
}

class KeyPairResult {
  final String privateKey;
  final String publicKey;

  KeyPairResult({
    required this.privateKey,
    required this.publicKey,
  });
}
