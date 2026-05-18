import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../shared/theme/app_colors.dart';

import '../bloc/otp/otp_bloc.dart';
import '../bloc/otp/otp_event.dart';
import '../bloc/otp/otp_state.dart';

class OtpForm extends StatefulWidget {
  final String sessionId;

  const OtpForm({
    super.key,
    required this.sessionId,
  });

  @override
  State<OtpForm> createState() => _OtpFormState();
}

class _OtpFormState extends State<OtpForm> {
  final otpController = TextEditingController();

  int seconds = 120;

  Timer? timer;

  @override
  void initState() {
    super.initState();

    startTimer();
  }

  void startTimer() {
    timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        if (seconds == 0) {
          timer?.cancel();
        } else {
          setState(() {
            seconds--;
          });
        }
      },
    );
  }

  @override
  void dispose() {
    timer?.cancel();

    otpController.dispose();

    super.dispose();
  }

  String get timerText {
    final minutes = (seconds ~/ 60)
        .toString()
        .padLeft(2, '0');

    final secs = (seconds % 60)
        .toString()
        .padLeft(2, '0');

    return "$minutes:$secs";
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OtpBloc, OtpState>(
      builder: (context, state) {
        return Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: const Color(0xffF8FAFC),

                borderRadius: BorderRadius.circular(20),

                border: Border.all(
                  color: AppColors.primary.withOpacity(0.08),
                ),
              ),

              child: TextField(
                controller: otpController,

                textAlign: TextAlign.center,

                keyboardType: TextInputType.number,

                style: const TextStyle(
                  fontSize: 28,
                  letterSpacing: 12,
                  fontWeight: FontWeight.bold,
                ),

                decoration: InputDecoration(
                  hintText: "000000",

                  hintStyle: TextStyle(
                    color: Colors.grey.shade400,
                    letterSpacing: 12,
                  ),

                  border: InputBorder.none,

                  contentPadding:
                      const EdgeInsets.symmetric(
                    vertical: 24,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 14,
              ),

              decoration: BoxDecoration(
                color: AppColors.secondary.withOpacity(0.12),

                borderRadius: BorderRadius.circular(16),
              ),

              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.timer_outlined,
                    size: 20,
                    color: AppColors.primary,
                  ),

                  const SizedBox(width: 8),

                  Text(
                    seconds > 0
                        ? "إعادة الإرسال خلال $timerText"
                        : "يمكنك إعادة إرسال الرمز",

                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 58,

              child: ElevatedButton(
                onPressed: state.isLoading
                    ? null
                    : () {
                        context.read<OtpBloc>().add(
                              OtpSubmitted(
                                sessionId: widget.sessionId,
                                otp: otpController.text.trim(),
                              ),
                            );
                      },

                style: ElevatedButton.styleFrom(
                  backgroundColor:AppColors.primary,

                  elevation: 0,

                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(18),
                  ),
                ),

                child: state.isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        "تأكيد التحقق",

                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 18),

            if (seconds == 0)
              TextButton(
                onPressed: () {
                  /// TODO:
                  /// RESEND OTP
                },

                child: const Text(
                  "إعادة إرسال الرمز",

                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}