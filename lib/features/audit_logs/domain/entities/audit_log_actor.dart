import 'package:equatable/equatable.dart';

/// منفّذ الحدث كما يعيده الخادم داخل `user` لكل سجل تدقيق.
///
/// قد يكون `null` في السجل الأصلي (أحداث النظام أو مستخدم محذوف)، لذلك تتعامل
/// طبقة العرض دائماً مع `AuditLogEntry.user` كقيمة اختيارية.
class AuditLogActor extends Equatable {
  final int id;
  final String userName;
  final String firstName;
  final String lastName;
  final String email;

  const AuditLogActor({
    required this.id,
    this.userName = '',
    this.firstName = '',
    this.lastName = '',
    this.email = '',
  });

  /// الاسم الكامل، ويسقط إلى اسم المستخدم إن كان الاسمان فارغين.
  String get displayName {
    final full =
        [firstName, lastName].where((p) => p.trim().isNotEmpty).join(' ');
    if (full.trim().isNotEmpty) return full.trim();
    return userName.isNotEmpty ? userName : 'مستخدم #$id';
  }

  @override
  List<Object?> get props => [id, userName, firstName, lastName, email];
}
