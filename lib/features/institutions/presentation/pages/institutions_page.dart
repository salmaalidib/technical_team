import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../bloc/institutions_bloc.dart';
import '../bloc/institutions_event.dart';
import '../widgets/institutions_header.dart';
import '../widgets/institutions_table.dart';
import '../../../../shared/theme/app_colors.dart';

class InstitutionsPage extends StatelessWidget {
  const InstitutionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<InstitutionsBloc>()..add(const LoadInstitutions()),
      child: Container(
        color: AppColors.surfaceAlt,
        padding: const EdgeInsets.fromLTRB(40, 28, 40, 30),
        child: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              InstitutionsHeader(),
              SizedBox(height: 28),
              InstitutionsTable(),
            ],
          ),
        ),
      ),
    );
  }
}
