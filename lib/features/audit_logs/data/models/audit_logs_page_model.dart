import '../../domain/entities/audit_log_entry.dart';
import '../../domain/entities/audit_logs_page.dart';
import 'audit_log_entry_model.dart';

/// يفكّ `data: { items, pagination: {...}, known_actions: [...] }`.
class AuditLogsPageModel {
  const AuditLogsPageModel._();

  static AuditLogsPage fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    final items = <AuditLogEntry>[
      if (rawItems is List)
        for (final e in rawItems)
          if (e is Map)
            AuditLogEntryModel.fromJson(Map<String, dynamic>.from(e)),
    ];

    final pagination = json['pagination'] is Map
        ? Map<String, dynamic>.from(json['pagination'] as Map)
        : const <String, dynamic>{};

    final rawActions = json['known_actions'];
    final knownActions = <String>[
      if (rawActions is List)
        for (final a in rawActions)
          if (a != null && a.toString().isNotEmpty) a.toString(),
    ];

    return AuditLogsPage(
      items: items,
      nextCursor: _nonEmpty(pagination['next_cursor']),
      hasNext: pagination['has_next'] == true,
      limit: _int(pagination['limit']) ?? 20,
      knownActions: knownActions,
    );
  }

  static String? _nonEmpty(dynamic value) {
    if (value == null) return null;
    final text = value.toString();
    return text.isEmpty ? null : text;
  }

  static int? _int(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}
