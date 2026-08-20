import 'dart:async';

import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import '../../../../shared/theme/app_colors.dart';
import '../bloc/otp/otp_bloc.dart';
import '../bloc/otp/otp_event.dart';
import '../bloc/otp/otp_state.dart';
import '../../../../shared/theme/app_dimens.dart';

/// الأخضر الأساسي للتطبيق — نفس اللون المستخدم في باقي الواجهات.
const _forest = AppColors.primary;
const _charcoal = AppColors.textCharcoal;

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
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');

    final secs = (seconds % 60).toString().padLeft(2, '0');

    return "$minutes:$secs";
  }

  void _submit() {
    context.read<OtpBloc>().add(
          OtpSubmitted(
            sessionId: widget.sessionId,
            otp: otpController.text.trim(),
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OtpBloc, OtpState>(
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FadeInDown(
              delay: const Duration(milliseconds: 50),
              duration: const Duration(milliseconds: 400),
              child: const Text(
                'رمز التحقق',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: _charcoal,
                ),
              ),
            ),
            const SizedBox(height: 6),
            FadeInDown(
              delay: const Duration(milliseconds: 100),
              duration: const Duration(milliseconds: 400),
              child: const Text(
                'تم إرسال رمز التحقق إلى رقم هاتفك',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textMuted,
                ),
              ),
            ),
            const SizedBox(height: 32),
            FadeInUp(
              delay: const Duration(milliseconds: 150),
              duration: const Duration(milliseconds: 450),
              child: TextFormField(
                controller: otpController,
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: state.isLoading ? null : (_) => _submit(),
                style: const TextStyle(
                  fontSize: 26,
                  letterSpacing: 12,
                  fontWeight: FontWeight.bold,
                  color: _charcoal,
                ),
                decoration: _otpInputDecoration(),
              ),
            ),
            const SizedBox(height: 20),
            FadeInUp(
              delay: const Duration(milliseconds: 200),
              duration: const Duration(milliseconds: 450),
              child: _TimerPill(
                seconds: seconds,
                timerText: timerText,
              ),
            ),
            const SizedBox(height: 32),
            FadeInUp(
              delay: const Duration(milliseconds: 250),
              duration: const Duration(milliseconds: 450),
              child: Container(
                height: 54,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  boxShadow: state.isLoading
                      ? null
                      : [
                          BoxShadow(
                            color: _forest.withValues(alpha: .25),
                            blurRadius: 15,
                            offset: const Offset(0, 6),
                          ),
                        ],
                ),
                child: ElevatedButton(
                  onPressed: state.isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: _forest,
                    disabledBackgroundColor: _forest.withValues(alpha: .6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                  child: state.isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: AppColors.white,
                          ),
                        )
                      : const Text(
                          'تأكيد التحقق',
                          style: TextStyle(
                            color: AppColors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: .5,
                          ),
                        ),
                ),
              ),
            ),
            if (seconds == 0) ...[
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  /// TODO:
                  /// RESEND OTP
                },
                child: const Text(
                  'إعادة إرسال الرمز',
                  style: TextStyle(
                    color: _forest,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

/// عدّاد إعادة الإرسال — بنفس لغة حقول تسجيل الدخول (حواف 14 ورمادي فاتح).
class _TimerPill extends StatelessWidget {
  const _TimerPill({required this.seconds, required this.timerText});

  final int seconds;
  final String timerText;

  @override
  Widget build(BuildContext context) {
    final waiting = seconds > 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.inputBackgroundAlt,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.borderLight, width: 1.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            waiting ? LucideIcons.timer : LucideIcons.refreshCw,
            size: 18,
            color: _forest.withValues(alpha: .7),
          ),
          const SizedBox(width: 10),
          Text(
            waiting ? 'إعادة الإرسال خلال $timerText' : 'يمكنك إعادة إرسال الرمز',
            style: const TextStyle(
              fontSize: 13,
              color: _charcoal,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

InputDecoration _otpInputDecoration() {
  OutlineInputBorder border(Color color, double width) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: BorderSide(color: color, width: width),
      );

  return InputDecoration(
    hintText: '000000',
    hintStyle: const TextStyle(
      fontSize: 26,
      letterSpacing: 12,
      fontWeight: FontWeight.bold,
      color: AppColors.borderStrong,
    ),
    filled: true,
    fillColor: AppColors.inputBackgroundAlt,
    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
    enabledBorder: border(AppColors.borderLight, 1.5),
    focusedBorder: border(_forest, 1.8),
    errorBorder: border(AppColors.error.withValues(alpha: .5), 1.5),
    focusedErrorBorder: border(AppColors.error, 1.8),
  );
}
