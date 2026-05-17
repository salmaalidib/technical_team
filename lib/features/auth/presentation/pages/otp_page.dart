import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/app_snackbar.dart';

import '../../di/injection.dart';

import '../bloc/otp/otp_bloc.dart';
import '../bloc/otp/otp_state.dart';

import '../widgets/otp_form.dart';

import '../../../../../shared/theme/app_colors.dart';

class OtpPage extends StatelessWidget {
  final String sessionId;

  const OtpPage({
    super.key,
    required this.sessionId,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    final isDesktop = width >= 1000;

    return BlocProvider(
      create: (_) => getIt<OtpBloc>(),
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        body: BlocListener<OtpBloc, OtpState>(
          listenWhen: (previous, current) =>
              previous.response != current.response ||
              previous.error != current.error,
          listener: (context, state) {
            if (state.response != null) {
              AppSnackBar.show(
                context,
                message: "تم تسجيل الدخول بنجاح",
              );

              Navigator.pushReplacementNamed(
                context,
                "/dashboard",
              );
            }

            if (state.error?.isNotEmpty == true) {
              AppSnackBar.show(
                context,
                message: state.error ?? "حدث خطأ غير متوقع",
                isError: true,
              );
            }
          },
          child: Row(
            children: [
              // LEFT SIDE
              if (isDesktop)
                Expanded(
                  flex: 6,
                  child: Container(
                    color: AppColors.primary,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(60),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.12),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.lock_person_rounded,
                                color: Colors.white,
                                size: 90,
                              ),
                            ),
                            const SizedBox(height: 32),
                            const Text(
                              "التحقق من الهوية",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 42,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              "أدخل رمز التحقق المرسل إلى رقم هاتفك لإكمال عملية تسجيل الدخول",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 18,
                                height: 1.8,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

              // RIGHT SIDE
              Expanded(
                flex: 4,
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(32),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: 430,
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(36),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 30,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Container(
                              height: 90,
                              width: 90,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.sms_rounded,
                                size: 46,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 28),
                            const Text(
                              "رمز التحقق",
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              "تم إرسال رمز التحقق إلى رقم هاتفك",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 15,
                                height: 1.7,
                              ),
                            ),
                            const SizedBox(height: 36),
                            OtpForm(
                              sessionId: sessionId,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
