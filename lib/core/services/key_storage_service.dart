import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';

class KeyStorageService {
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
  }) async {
    final safeUserName = userName.replaceAll(RegExp(r'[^a-zA-Z0-9_.-]'), '_');

    final employeeDir = Directory('$directoryPath\\$safeUserName-keys');

    if (!await employeeDir.exists()) {
      await employeeDir.create(recursive: true);
    }

    await File('${employeeDir.path}\\employee-private.key').writeAsString(
      privateKey,
      flush: true,
    );

    await File('${employeeDir.path}\\employee-public.pem').writeAsString(
      publicKey,
      flush: true,
    );

    await File('${employeeDir.path}\\employee-meta.json').writeAsString(
      jsonEncode({
        'userName': userName,
        'created_at': DateTime.now().toIso8601String(),
        'public_key_file': 'employee-public.pem',
        'private_key_file': 'employee-private.key',
      }),
      flush: true,
    );
  }

  bool _isExternalDrive(String path) {
    final normalized = path.replaceAll('/', '\\');

    // ممنوع C:
    if (normalized.toUpperCase().startsWith('C:\\')) {
      return false;
    }

    // يسمح فقط بمسارات Windows drive مثل D:\ E:\ F:\
    final driveRegex = RegExp(r'^[A-Z]:\\', caseSensitive: false);
    return driveRegex.hasMatch(normalized);
  }
}