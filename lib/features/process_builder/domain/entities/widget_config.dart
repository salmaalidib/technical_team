import 'package:equatable/equatable.dart';

/// A field widget, already shaped for `config_json.widgets[]` in the backend
/// contract: `{ widget_type, data: { id, label, is_required, ... } }`.
///
/// Built from the reusable `fields` entities via `widgetConfigMapper`. [groupId]
/// + [widgetId] uniquely identify it inside the "link fields" picker; [label]
/// is for display only.
class WidgetConfig extends Equatable {
  /// Backend `widget_type` (note: `text_dropdown` is mapped to `dropdown`).
  final String widgetType;

  /// The field-library group this came from (text_field, dropdown, ...), used
  /// only to render the grouped checkboxes.
  final String groupId;

  /// `data.id` — must be unique within a stage's widgets (backend validates).
  final String widgetId;

  final String label;

  /// The full `data` object sent verbatim inside `config_json.widgets[i].data`.
  final Map<String, dynamic> data;

  const WidgetConfig({
    required this.widgetType,
    required this.groupId,
    required this.widgetId,
    required this.label,
    required this.data,
  });

  Map<String, dynamic> toJson() => {
        'widget_type': widgetType,
        'data': data,
      };

  /// Rebuilds a [WidgetConfig] from a stored `config_json.widgets[i]` object
  /// (`{ widget_type, data }`). Used when editing an existing template — the
  /// [groupId] mirrors the `widget_type` so the field groups into the matching
  /// picker section.
  factory WidgetConfig.fromJson(Map<String, dynamic> json) {
    final type = (json['widget_type'] ?? '') as String;
    final data = (json['data'] as Map?)?.cast<String, dynamic>() ?? const {};
    return WidgetConfig(
      widgetType: type,
      groupId: type,
      widgetId: (data['id'] ?? '') as String,
      label: (data['label'] ?? data['id'] ?? '') as String,
      data: data,
    );
  }

  @override
  List<Object?> get props => [widgetType, groupId, widgetId, label, data];
}
