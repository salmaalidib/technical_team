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
      dialogTitle: 'اختر مجلداً على فلاشة USB لحفظ مفاتيح الموظف',
    );

    if (path == null) return null;

    if (!_isExternalDrive(path)) {
      throw Exception(_externalDriveHint);
    }

    return path;
  }

  /// Platform-specific guidance shown when the chosen folder is not on a
  /// removable drive.
  String get _externalDriveHint {
    if (Platform.isMacOS) {
      return 'يجب اختيار مجلد على فلاشة USB (يظهر مسارها تحت \u200E/Volumes\u200E)، '
          'وليس على القرص الداخلي';
    }
    if (Platform.isLinux) {
      return 'يجب اختيار مجلد على فلاشة USB (تحت \u200E/media\u200E أو \u200E/mnt\u200E)، '
          'وليس على القرص الداخلي';
    }
    return 'يجب اختيار مجلد على فلاشة USB أو قرص خارجي (غير القرص :C)، '
        'وليس على القرص الداخلي';
  }

  Future<void> saveEmployeeKeys({
    required String directoryPath,
    required String userName,
    required String privateKey,
    required String publicKey,
    required String pin,
  }) async {
    final safeUserName = userName.replaceAll(RegExp(r'[^a-zA-Z0-9_.-]'), '_');
    final sep = Platform.pathSeparator;
    final employeeDir = Directory('$directoryPath$sep$safeUserName-keys');

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

    await File('${employeeDir.path}${sep}employee-key.enc').writeAsString(
      base64Encode(secretBox.cipherText),
      flush: true,
    );

    await File('${employeeDir.path}${sep}employee-key.meta').writeAsString(
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

    await File('${employeeDir.path}${sep}employee-public.pem').writeAsString(
      publicKey,
      flush: true,
    );
  }

  List<int> _randomBytes(int length) {
    final random = Random.secure();
    return List.generate(length, (_) => random.nextInt(256));
  }

  /// Returns true only when [path] lives on a removable / external volume
  /// (e.g. a USB flash drive), so employee keys are never written to the
  /// machine's internal disk. The notion of "external" differs per platform.
  bool _isExternalDrive(String path) {
    if (Platform.isWindows) {
      final normalized = path.replaceAll('/', '\\');

      // The system disk is C:\ — anything on it is internal. Any other
      // drive letter (D:\, E:\, ...) is treated as removable.
      if (normalized.toUpperCase().startsWith('C:\\')) {
        return false;
      }
      return RegExp(r'^[A-Z]:\\', caseSensitive: false).hasMatch(normalized);
    }

    if (Platform.isMacOS) {
      // External volumes mount under /Volumes/<name>. The internal disk is
      // also exposed there (usually "/Volumes/Macintosh HD"), so exclude the
      // bare /Volumes and the root device name; require a real sub-volume.
      final normalized = path.replaceAll('\\', '/');
      if (!normalized.startsWith('/Volumes/')) {
        return false;
      }
      final volumeName = normalized
          .substring('/Volumes/'.length)
          .split('/')
          .first
          .trim();
      if (volumeName.isEmpty) return false;
      // Reject the internal boot volume by its default name.
      return volumeName.toLowerCase() != 'macintosh hd';
    }

    if (Platform.isLinux) {
      // USB drives are auto-mounted under one of these on common distros.
      final normalized = path.replaceAll('\\', '/');
      return normalized.startsWith('/media/') ||
          normalized.startsWith('/run/media/') ||
          normalized.startsWith('/mnt/');
    }

    // Unknown platform: fail closed so keys are never written internally.
    return false;
  }
}
