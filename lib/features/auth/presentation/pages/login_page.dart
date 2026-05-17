import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../di/injection.dart';
import '../bloc/login/login_bloc.dart';

import '../../../../../shared/theme/app_colors.dart';
import '../widgets/login_form.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 1000;

    return BlocProvider(
      create: (_) => getIt<LoginBloc>(),
      child: Scaffold(
        body: Row(
          children: [
            if (isDesktop)
              Expanded(
                flex: 6,
                child: Container(
                  color: AppColors.primary,
                  child: const Center(
                    child: Text(
                      'مديرية التربية في ريف دمشق',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),

            Expanded(
              flex: 4,
              child: Container(
                color: const Color(0xFFF5F7FA),
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(32),
                    child:  ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: 420),
                      child: LoginForm(),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}