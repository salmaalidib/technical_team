import 'package:url_launcher/url_launcher.dart';

/// Opens WhatsApp (app or web) with a pre-filled message to a given phone
/// number. The actual "send" is one manual tap by the user — wa.me cannot
/// auto-send, by WhatsApp's design.
class WhatsAppService {
  /// Default country dialing code used when a local number is entered.
  /// Syria = 963. Change this if the deployment targets another country.
  static const String _defaultCountryCode = '963';

  /// Normalizes a user-entered phone number into the international form
  /// WhatsApp expects: digits only, no leading '+' or '00', no leading '0'.
  ///
  /// Examples (Syria):
  ///   0988341827      -> 963988341827
  ///   +963988341827   -> 963988341827
  ///   00963988341827  -> 963988341827
  ///   963988341827    -> 963988341827
  static String normalizePhone(String raw) {
    // Keep digits only (drops spaces, dashes, parentheses, leading '+').
    var digits = raw.replaceAll(RegExp(r'\D'), '');

    // International prefix written as 00 -> drop it.
    if (digits.startsWith('00')) {
      digits = digits.substring(2);
    }

    // Already starts with the country code -> use as-is.
    if (digits.startsWith(_defaultCountryCode)) {
      return digits;
    }

    // Local number starting with 0 -> replace the 0 with the country code.
    if (digits.startsWith('0')) {
      return '$_defaultCountryCode${digits.substring(1)}';
    }

    // Bare local number without a leading 0 -> prepend the country code.
    return '$_defaultCountryCode$digits';
  }

  /// Builds the credentials message sent to the employee.
  static String buildCredentialsMessage({
    required String userName,
    required String password,
    required String pin,
  }) {
    return 'مرحباً،\n'
        'تم إنشاء حسابك في النظام. هذه بيانات الدخول المؤقتة:\n\n'
        'اسم المستخدم: $userName\n'
        'كلمة المرور المؤقتة: $password\n'
        'رمز PIN: $pin\n\n'
        'يرجى الحفاظ على هذه البيانات وعدم مشاركتها مع أي شخص.';
  }

  /// Opens WhatsApp with [message] addressed to [phone]. Returns false if no
  /// WhatsApp/browser handler could be launched.
  Future<bool> sendCredentials({
    required String phone,
    required String message,
  }) async {
    final normalized = normalizePhone(phone);
    final uri = Uri.parse(
      'https://wa.me/$normalized?text=${Uri.encodeComponent(message)}',
    );

    if (!await canLaunchUrl(uri)) {
      return false;
    }

    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
