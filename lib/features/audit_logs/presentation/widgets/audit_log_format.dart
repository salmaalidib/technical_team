/// دوال العرض المشتركة بين الجدول وحوار التفاصيل ولوحة الفلاتر.
library;

/// ترجمة أكواد الأحداث المعروفة إلى عربية.
///
/// القائمة تطابق `core/security/auditActions.js` في الخادم. أي كود غير مذكور
/// هنا يُعرض كما هو بدل أن يختفي — الخادم قد يضيف أحداثاً قبل تحديث العميل.
const _actionLabels = <String, String>{
  'REFRESH_TOKEN_REUSE': 'إعادة استخدام رمز تحديث',
  'LOGOUT': 'تسجيل خروج',
  'ACCOUNT_ACCESS_BLOCKED': 'حظر وصول حساب',
  'EMPLOYEE_REGISTERED': 'تسجيل موظف',
  'EMPLOYEE_UPDATED': 'تعديل موظف',
  'ROLE_PERMISSIONS_CREATED': 'إضافة صلاحيات دور',
  'ROLE_PERMISSIONS_UPDATED': 'تعديل صلاحيات دور',
  'TRANSACTION_SUBMITTED': 'تقديم معاملة',
  'TASK_COMPLETED': 'إنجاز مهمة',
  'TASK_REJECTED': 'رفض مهمة',
  'TASK_PICKED_UP': 'استلام مهمة',
  'TASK_RELEASED': 'تحرير مهمة',
  'FINAL_DOCUMENT_SAVED': 'حفظ المستند النهائي',
  'FINAL_DOCUMENT_GENERATED': 'توليد المستند النهائي',
  'PROCESS_CREATED': 'إنشاء إجراء',
  'PROCESS_REVIEWED': 'مراجعة إجراء',
  'PROCESS_STATUS_CHANGED': 'تغيير حالة إجراء',
  'ODR_CREATED': 'إنشاء طلب مستند',
  'ODR_STATUS_CHANGED': 'تغيير حالة طلب مستند',
  'ORGANIZATION_CREATED': 'إنشاء مؤسسة',
  'DEPARTMENT_CREATED': 'إنشاء قسم',
  'DEPARTMENT_STATUS_CHANGED': 'تغيير حالة قسم',
  'DEVICE_TOKEN_REGISTERED': 'تسجيل جهاز',
  'CITIZEN_REGISTER_STARTED': 'بدء تسجيل مواطن',
};

/// الاسم العربي للحدث، ويسقط إلى الكود نفسه إن كان غير معروف.
String auditActionLabel(String action) =>
    _actionLabels[action] ?? action.replaceAll('_', ' ');

/// ترجمة أنواع الموارد الشائعة.
const _resourceLabels = <String, String>{
  'user': 'مستخدم',
  'task': 'مهمة',
  'transaction': 'معاملة',
  'process_definition': 'تعريف إجراء',
  'organization': 'مؤسسة',
  'department': 'قسم',
  'role': 'دور',
  'document': 'مستند',
};

String auditResourceLabel(String? resourceType) {
  if (resourceType == null || resourceType.isEmpty) return '—';
  return _resourceLabels[resourceType] ?? resourceType;
}

/// `YYYY-MM-DD` — الصيغة التي يقبلها الخادم في `from_date` / `to_date`.
String auditApiDay(DateTime date) =>
    '${date.year}-${_two(date.month)}-${_two(date.day)}';

/// تاريخ ووقت للعرض في الجدول: `YYYY-MM-DD · HH:mm`.
String auditDateTimeLabel(DateTime? date) {
  if (date == null) return '—';
  return '${auditApiDay(date)} · ${_two(date.hour)}:${_two(date.minute)}';
}

/// تاريخ ووقت كامل بالثواني — لحوار التفاصيل حيث الدقة مهمة.
String auditFullDateTimeLabel(DateTime? date) {
  if (date == null) return '—';
  return '${auditApiDay(date)} · '
      '${_two(date.hour)}:${_two(date.minute)}:${_two(date.second)}';
}

String _two(int value) => value.toString().padLeft(2, '0');
