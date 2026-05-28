import 'package:flutter/material.dart';

import '../../../../shared/layouts/app_shell.dart';
import '../../../../shared/theme/app_colors.dart';
import '../widgets/institutions_header.dart';
import '../widgets/institutions_table.dart';

class InstitutionsPage extends StatelessWidget {
  const InstitutionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xffF0EFE7),
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
    );
  }
}
