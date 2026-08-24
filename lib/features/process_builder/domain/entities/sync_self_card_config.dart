import 'package:equatable/equatable.dart';

import 'widget_config.dart';

/// The `employee_picker` widget that selects an **employee self card**
/// (`employee_self_cards.id`) — the HR file, NOT a login account.
///
/// Unlike every other widget in a stage form, this one is NOT sourced from the
/// reusable field library: the backend schema (`employeePickerDataSchema` in
/// `stageConfigSchema.js`) accepts only `{ id, label, is_required,
/// options_source }` with `unknown(false)`, and the options are fetched at
/// run-time from `GET /api/self-cards/search`. There is nothing to pick from a
/// library, so the widget is built here as a fixed constant instead.
///
/// `data.id` MUST stay `self_card_id`: a `SYNC_SELF_CARD` action references it
/// by name through `self_card_id_widget` to know which card to write to.
const kSelfCardWidgetId = 'self_card_id';

/// Builds the canonical `employee_picker` widget for a USER_TASK stage.
WidgetConfig buildSelfCardPickerWidget() => const WidgetConfig(
      widgetType: 'employee_picker',
      groupId: 'employee_picker',
      widgetId: kSelfCardWidgetId,
      label: 'البطاقة الذاتية',
      data: {
        'id': kSelfCardWidgetId,
        'label': 'البطاقة الذاتية',
        'is_required': true,
        // The only source that yields a self_card_id; `employees_search`
        // returns user accounts, which the sync service cannot write to.
        'options_source': 'self_cards_search',
      },
    );

/// The table a `SYNC_SELF_CARD` action writes to, with the columns the backend
/// accepts for it and which of them are mandatory.
///
/// Mirrors `VALID_TARGETS` / the per-target column lists in
/// `syncSelfCardService.js`. `profile_header` updates the card itself; every
/// other target appends a history row.
enum SelfCardTarget {
  profileHeader,
  trainingCourse,
  employmentStatus,
  irregularAbsence,
  leave,
  reward,
  sanction,
}

extension SelfCardTargetX on SelfCardTarget {
  /// The `payload.target` value sent to the backend.
  String get apiValue => switch (this) {
        SelfCardTarget.profileHeader => 'profile_header',
        SelfCardTarget.trainingCourse => 'training_course',
        SelfCardTarget.employmentStatus => 'employment_status',
        SelfCardTarget.irregularAbsence => 'irregular_absence',
        SelfCardTarget.leave => 'leave',
        SelfCardTarget.reward => 'reward',
        SelfCardTarget.sanction => 'sanction',
      };

  String get label => switch (this) {
        SelfCardTarget.profileHeader => 'المعلومات الذاتية',
        SelfCardTarget.trainingCourse => 'دورة تدريبية',
        SelfCardTarget.employmentStatus => 'الوضع الوظيفي',
        SelfCardTarget.irregularAbsence => 'غياب غير أصولي',
        SelfCardTarget.leave => 'إجازة',
        SelfCardTarget.reward => 'مكافأة',
        SelfCardTarget.sanction => 'عقوبة',
      };

  /// Columns the backend accepts for this target. The keys of `field_map` must
  /// come from this list — an unknown column is silently dropped by the sync
  /// service, so offering free text here would fail invisibly at run-time.
  List<String> get columns => switch (this) {
        SelfCardTarget.profileHeader => const [
            'self_number',
            'national_id',
            'insurance_number',
            'full_name',
            'father_name',
            'mother_name',
            'birth_place',
            'birth_date',
            'registry_place',
            'registry_number',
            'gender',
            'nationality',
            'foreign_language',
            'education_degree',
            'current_residence',
          ],
        SelfCardTarget.trainingCourse => const [
            'title',
            'provider',
            'topic',
            'start_date',
            'end_date',
            'duration',
            'certificate_number',
            'notes',
          ],
        SelfCardTarget.employmentStatus => const [
            'work_center',
            'job_title',
            'job_type',
            'category',
            'salary',
            'start_date',
            'emergency_change_date',
            'document_reason',
            'document_type',
            'document_number',
            'document_date',
          ],
        SelfCardTarget.irregularAbsence => const [
            'duration',
            'start_date',
            'end_date',
            'document_type',
            'document_number',
            'document_date',
          ],
        SelfCardTarget.leave => const [
            'leave_type',
            'start_date',
            'end_date',
            'duration',
            'reason',
            'document_type',
            'document_number',
            'document_date',
          ],
        SelfCardTarget.reward => const [
            'reward_type',
            'reason',
            'document_type',
            'document_number',
            'document_date',
          ],
        SelfCardTarget.sanction => const [
            'sanction_type',
            'reason',
            'document_type',
            'document_number',
            'document_date',
          ],
      };

  /// Columns the backend REQUIRES for this target: the sync fails at run-time
  /// if the mapped value is missing. Taken from the NOT NULL columns of each
  /// history model in `employeeSelfCardRepository.js`.
  Set<String> get requiredColumns => switch (this) {
        SelfCardTarget.trainingCourse => const {'title'},
        SelfCardTarget.leave => const {'leave_type'},
        SelfCardTarget.reward => const {'reward_type'},
        SelfCardTarget.sanction => const {'sanction_type'},
        _ => const {},
      };

  /// Arabic label for a column, for display in the mapping editor.
  String labelFor(String column) => _columnLabels[column] ?? column;
}

const _columnLabels = <String, String>{
  'self_number': 'الرقم الذاتي',
  'national_id': 'الرقم الوطني',
  'insurance_number': 'الرقم التأميني',
  'full_name': 'الاسم الكامل',
  'father_name': 'اسم الأب',
  'mother_name': 'اسم الأم',
  'birth_place': 'مكان الولادة',
  'birth_date': 'تاريخ الولادة',
  'registry_place': 'مكان القيد',
  'registry_number': 'رقم القيد',
  'gender': 'الجنس',
  'nationality': 'الجنسية',
  'foreign_language': 'اللغة الأجنبية',
  'education_degree': 'المؤهل العلمي',
  'current_residence': 'مكان الإقامة',
  'title': 'عنوان الدورة',
  'provider': 'الجهة المانحة',
  'topic': 'الموضوع',
  'start_date': 'تاريخ البداية',
  'end_date': 'تاريخ النهاية',
  'duration': 'المدة',
  'certificate_number': 'رقم الشهادة',
  'notes': 'ملاحظات',
  'work_center': 'مركز العمل',
  'job_title': 'المسمى الوظيفي',
  'job_type': 'نوع العمل',
  'category': 'الفئة',
  'salary': 'الراتب',
  'emergency_change_date': 'تاريخ التغيير الطارئ',
  'document_reason': 'سبب الوثيقة',
  'document_type': 'نوع الوثيقة',
  'document_number': 'رقم الوثيقة',
  'document_date': 'تاريخ الوثيقة',
  'leave_type': 'نوع الإجازة',
  'reason': 'السبب',
  'reward_type': 'نوع المكافأة',
  'sanction_type': 'نوع العقوبة',
};

/// Configuration for a `SYNC_SELF_CARD` service-task action.
///
/// At run-time the backend reads the sealed snapshot of an earlier USER_TASK,
/// resolves the self card from the `employee_picker` value, and writes the
/// mapped columns onto that card. See `syncSelfCardService.js`.
class SyncSelfCardConfig extends Equatable {
  /// Which table to write to (`payload.target`).
  final SelfCardTarget target;

  /// `payload.field_map` — `{ table_column: source_widget_id }`.
  ///
  /// The backend requires at least one entry (`.min(1).required()`), so an
  /// empty map makes the WHOLE stage_config batch fail with a 400.
  final Map<String, String> fieldMap;

  const SyncSelfCardConfig({
    this.target = SelfCardTarget.leave,
    this.fieldMap = const {},
  });

  /// The backend rejects an empty `field_map`, and the sync fails at run-time
  /// if a required column of the target is not mapped. Mirrored here so the UI
  /// can block submit instead of surfacing a 400 (or a silent run-time skip).
  bool get isComplete {
    if (fieldMap.isEmpty) return false;
    return target.requiredColumns.every(fieldMap.containsKey);
  }

  /// Required columns of the target that are still unmapped.
  List<String> get missingRequiredColumns =>
      target.requiredColumns.where((c) => !fieldMap.containsKey(c)).toList();

  SyncSelfCardConfig copyWith({
    SelfCardTarget? target,
    Map<String, String>? fieldMap,
  }) {
    return SyncSelfCardConfig(
      target: target ?? this.target,
      fieldMap: fieldMap ?? this.fieldMap,
    );
  }

  /// `config_json.actions[i].payload` for `SYNC_SELF_CARD`.
  Map<String, dynamic> toPayloadJson() => {
        'target': target.apiValue,
        // The only mode the schema accepts — the card owner comes from the
        // picker widget, never from the authenticated user.
        'employee_user_id_from': 'WIDGET',
        'self_card_id_widget': kSelfCardWidgetId,
        // Read the most recent sealed USER_TASK snapshot before this stage.
        'source_stage': 'PREVIOUS_USER_TASK',
        'field_map': fieldMap,
      };

  @override
  List<Object?> get props => [target, fieldMap];
}
