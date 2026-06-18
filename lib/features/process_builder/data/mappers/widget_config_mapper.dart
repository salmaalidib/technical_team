import '../../../fields/domain/entities/check_list_entity.dart';
import '../../../fields/domain/entities/date_picker_entity.dart';
import '../../../fields/domain/entities/field_option.dart';
import '../../../fields/domain/entities/file_picker_entity.dart';
import '../../../fields/domain/entities/radio_group_entity.dart';
import '../../../fields/domain/entities/text_dropdown_entity.dart';
import '../../../fields/domain/entities/text_field_entity.dart';
import '../../domain/entities/widget_config.dart';

/// Converts the reusable `fields` entities into [WidgetConfig] objects shaped
/// for the backend `config_json.widgets[]` contract.
///
/// Note the one naming divergence: the fields feature calls dropdowns
/// `text_dropdown`, while the stage-config schema expects `dropdown`.
class WidgetConfigMapper {
  const WidgetConfigMapper._();

  // Group ids used to render the "link fields" sections.
  static const groupTextField = 'text_field';
  static const groupDropdown = 'dropdown';
  static const groupRadioGroup = 'radio_group';
  static const groupCheckList = 'check_list';
  static const groupDatePicker = 'date_picker';
  static const groupFilePicker = 'file_picker';

  static List<Map<String, String>> _options(List<FieldOption> options) =>
      options.map((o) => {'key': o.key, 'value': o.value}).toList();

  static WidgetConfig fromTextField(TextFieldEntity e) {
    final data = <String, dynamic>{
      'id': e.idWidget,
      'label': e.label,
      'is_required': e.isRequired,
      'input_type': e.inputType,
    };
    if (e.regex != null && e.regex!.isNotEmpty) data['regex'] = e.regex;
    if (e.maxLength != null) data['max_length'] = e.maxLength;
    if (e.minLength != null) data['min_length'] = e.minLength;

    return WidgetConfig(
      widgetType: 'text_field',
      groupId: groupTextField,
      widgetId: e.idWidget,
      label: e.label,
      data: data,
    );
  }

  static WidgetConfig fromTextDropdown(TextDropdownEntity e) {
    return WidgetConfig(
      widgetType: 'dropdown', // fields → backend naming
      groupId: groupDropdown,
      widgetId: e.idWidget,
      label: e.label,
      data: {
        'id': e.idWidget,
        'label': e.label,
        'is_required': e.isRequired,
        'options': _options(e.options),
      },
    );
  }

  static WidgetConfig fromRadioGroup(RadioGroupEntity e) {
    return WidgetConfig(
      widgetType: 'radio_group',
      groupId: groupRadioGroup,
      widgetId: e.idWidget,
      label: e.label,
      data: {
        'id': e.idWidget,
        'label': e.label,
        'is_required': e.isRequired,
        'options': _options(e.options),
      },
    );
  }

  static WidgetConfig fromCheckList(CheckListEntity e) {
    return WidgetConfig(
      widgetType: 'check_list',
      groupId: groupCheckList,
      widgetId: e.idWidget,
      label: e.label,
      data: {
        'id': e.idWidget,
        'label': e.label,
        'is_required': e.isRequired,
        'min_selected': e.minSelected,
        'max_selected': e.maxSelected,
        'options': _options(e.options),
      },
    );
  }

  static WidgetConfig fromDatePicker(DatePickerEntity e) {
    return WidgetConfig(
      widgetType: 'date_picker',
      groupId: groupDatePicker,
      widgetId: e.idWidget,
      label: e.label,
      data: {
        'id': e.idWidget,
        'label': e.label,
        'is_required': e.isRequired,
        'min_date': e.minDate,
        'max_date': e.maxDate,
      },
    );
  }

  static WidgetConfig fromFilePicker(FilePickerEntity e) {
    return WidgetConfig(
      widgetType: 'file_picker',
      groupId: groupFilePicker,
      widgetId: e.idWidget,
      label: e.label,
      data: {
        'id': e.idWidget,
        'label': e.label,
        'is_required': e.isRequired,
        'max_size_mb': e.maxSizeMb,
        'allowed_extensions': e.allowedExtensions,
        'allow_multiple': e.allowMultiple,
      },
    );
  }
}
