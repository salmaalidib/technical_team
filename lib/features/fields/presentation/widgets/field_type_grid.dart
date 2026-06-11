import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/field_type.dart';
import '../bloc/fields_bloc.dart';
import '../bloc/fields_event.dart';
import '../bloc/fields_state.dart';
import 'field_type_card.dart';

class FieldTypeGrid extends StatelessWidget {
  const FieldTypeGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FieldsBloc, FieldsState>(
      buildWhen: (p, c) =>
          p.selectedType != c.selectedType ||
          p.textFields.length != c.textFields.length ||
          p.radioGroups.length != c.radioGroups.length ||
          p.textDropdowns.length != c.textDropdowns.length ||
          p.checkLists.length != c.checkLists.length ||
          p.datePickers.length != c.datePickers.length ||
          p.filePickers.length != c.filePickers.length,
      builder: (context, state) {
        return LayoutBuilder(
          builder: (context, constraints) {
            const gap = 18.0;
            const minCardWidth = 260.0;
            final w = constraints.maxWidth;
            // Fit as many ~260px cards as possible, capped at 3 per row.
            final columns =
                (w / (minCardWidth + gap)).floor().clamp(1, 3);
            final cardWidth = (w - (columns - 1) * gap) / columns;

            return Wrap(
              spacing: gap,
              runSpacing: gap,
              textDirection: TextDirection.rtl,
              children: [
                for (final type in FieldType.values)
                  SizedBox(
                    width: cardWidth,
                    child: FieldTypeCard(
                      type: type,
                      count: state.countOf(type),
                      isSelected: state.selectedType == type,
                      onTap: () => context
                          .read<FieldsBloc>()
                          .add(SelectFieldType(type)),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}
