import 'package:equatable/equatable.dart';

class FieldOption extends Equatable {
  final String key;
  final String value;

  const FieldOption({required this.key, required this.value});

  /// Parses a raw `options` JSON array (`[{key, value}, ...]`) into entities,
  /// tolerating nulls/missing keys. Shared by every option-bearing model.
  static List<FieldOption> listFromJson(dynamic raw) {
    final list = raw as List? ?? const [];
    return list
        .map((e) => FieldOption(
              key: (e['key'] ?? '') as String,
              value: (e['value'] ?? '') as String,
            ))
        .toList();
  }

  @override
  List<Object?> get props => [key, value];
}
