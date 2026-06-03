import 'package:flutter/material.dart';

/// Maps a backend `field_type` value to an Arabic label and an icon, and lists
/// the selectable types for the create/edit form.
class FieldTypeMeta {
  final String value; // backend value
  final String label; // arabic display
  final IconData icon;

  const FieldTypeMeta(this.value, this.label, this.icon);
}

/// The field types accepted by `POST /api/fields` (the backend `action` enum
/// value is intentionally excluded — its create validation rejects it).
const List<FieldTypeMeta> kFieldTypes = [
  FieldTypeMeta('string', 'نص قصير', Icons.text_fields_rounded),
  FieldTypeMeta('text', 'نص طويل', Icons.notes_rounded),
  FieldTypeMeta('int', 'رقم صحيح', Icons.tag_rounded),
  FieldTypeMeta('float', 'رقم عشري', Icons.numbers_rounded),
  FieldTypeMeta('phoneNumber', 'رقم هاتف', Icons.phone_outlined),
  FieldTypeMeta('date', 'تاريخ', Icons.calendar_today_outlined),
  FieldTypeMeta('boolean', 'نعم / لا', Icons.toggle_on_outlined),
  FieldTypeMeta('choice', 'قائمة (اختيار واحد)', Icons.radio_button_checked),
  FieldTypeMeta('multiChoice', 'قائمة (اختيار متعدد)', Icons.checklist_rounded),
];

FieldTypeMeta fieldTypeMetaOf(String value) {
  return kFieldTypes.firstWhere(
    (t) => t.value == value,
    orElse: () => FieldTypeMeta(value, value, Icons.help_outline_rounded),
  );
}

/// `choice` / `multiChoice` require a non-empty `list_json` of options.
bool isListFieldType(String value) =>
    value == 'choice' || value == 'multiChoice';
