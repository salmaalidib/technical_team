import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:cryptography/cryptography.dart';
import 'package:file_picker/file_picker.dart';

class KeyStorageService {
  final _aes = AesGcm.with256bits();
  final _pbkdf2 = Pbkdf2(
    macAlgorithm: Hmac.sha256(),
    iterations: 100000,
    bits: 256,
  );

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

  Future<String?> pickExternalDirectory() async {
    final path = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'اختاري مجلد على الفلاشة لحفظ مفاتيح الموظف',
    );

    if (path == null) return null;

    if (!_isExternalDrive(path)) {
      throw Exception('يجب اختيار مجلد على قرص خارجي مثل الفلاشة');
    }

    return path;
  }

  Future<void> saveEmployeeKeys({
    required String directoryPath,
    required String userName,
    required String privateKey,
    required String publicKey,
    required String pin,
  }) async {
    final safeUserName = userName.replaceAll(RegExp(r'[^a-zA-Z0-9_.-]'), '_');
    final employeeDir = Directory('$directoryPath\\$safeUserName-keys');

    if (!await employeeDir.exists()) {
      await employeeDir.create(recursive: true);
    }

    final salt = _randomBytes(16);
    final nonce = _randomBytes(12);

    final secretKey = await _pbkdf2.deriveKey(
      secretKey: SecretKey(utf8.encode(pin)),
      nonce: salt,
    );

    final secretBox = await _aes.encrypt(
      utf8.encode(privateKey),
      secretKey: secretKey,
      nonce: nonce,
    );

    await File('${employeeDir.path}\\employee-key.enc').writeAsString(
      base64Encode(secretBox.cipherText),
      flush: true,
    );

    await File('${employeeDir.path}\\employee-key.meta').writeAsString(
      jsonEncode({
        'algorithm': 'AES-GCM-256',
        'kdf': 'PBKDF2-HMAC-SHA256',
        'iterations': 100000,
        'salt': base64Encode(salt),
        'nonce': base64Encode(nonce),
        'mac': base64Encode(secretBox.mac.bytes),
        'created_at': DateTime.now().toIso8601String(),
      }),
      flush: true,
    );

    await File('${employeeDir.path}\\employee-public.pem').writeAsString(
      publicKey,
      flush: true,
    );
  }

  List<int> _randomBytes(int length) {
    final random = Random.secure();
    return List.generate(length, (_) => random.nextInt(256));
  }

  bool _isExternalDrive(String path) {
    final normalized = path.replaceAll('/', '\\');

    if (normalized.toUpperCase().startsWith('C:\\')) {
      return false;
    }

    return RegExp(r'^[A-Z]:\\', caseSensitive: false).hasMatch(normalized);
  }
}