import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/enums/form_status.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../domain/entities/field_type.dart';
import '../bloc/fields_bloc.dart';
import '../bloc/fields_state.dart';
import 'check_list_form.dart';
import 'date_picker_form.dart';
import 'field_type_card.dart';
import 'file_picker_form.dart';
import 'options_form.dart';
import 'text_field_form.dart';

/// Modal entry point: shows the create form for [type], and on success/failure
/// surfaces a snackbar and closes itself. Each form lives in its own file; this
/// widget only wires up the shell, the bloc listener, and the dispatcher below.
class CreateFieldDialog extends StatelessWidget {
  final FieldType type;

  const CreateFieldDialog({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    return BlocListener<FieldsBloc, FieldsState>(
      listenWhen: (p, c) => p.createStatus != c.createStatus,
      listener: (context, state) {
        if (state.createStatus == FormStatus.success) {
          AppSnackBar.show(context, message: 'تم الإنشاء بنجاح');
          Navigator.of(context).pop();
        } else if (state.createStatus == FormStatus.failure) {
          AppSnackBar.show(
            context,
            message: state.createError ?? 'تعذّر الإنشاء',
            isError: true,
          );
        }
      },
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Dialog(
          backgroundColor: AppColors.surface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680, maxHeight: 780),
            child: _FormBody(type: type),
          ),
        ),
      ),
    );
  }
}

/// Picks the right form widget for [type].
class _FormBody extends StatelessWidget {
  final FieldType type;

  const _FormBody({required this.type});

  @override
  Widget build(BuildContext context) {
    final meta = kFieldTypeMeta[type]!;
    return switch (type) {
      FieldType.textField => TextFieldForm(meta: meta),
      FieldType.radioGroup => OptionsForm(type: type, meta: meta),
      FieldType.textDropdown => OptionsForm(type: type, meta: meta),
      FieldType.checkList => CheckListForm(meta: meta),
      FieldType.datePicker => DatePickerForm(meta: meta),
      FieldType.filePicker => FilePickerForm(meta: meta),
    };
  }
}
