import 'dart:async';

import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import '../../../../shared/theme/app_colors.dart';
import '../bloc/otp/otp_bloc.dart';
import '../bloc/otp/otp_event.dart';
import '../bloc/otp/otp_state.dart';

/// الأخضر الأساسي للتطبيق — نفس اللون المستخدم في باقي الواجهات.
const _forest = AppColors.primary;
const _charcoal = Color(0xFF3D3A3B);

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
                  fontFamily: 'Cairo',
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
                  fontFamily: 'Cairo',
                  fontSize: 14,
                  color: Color(0xFF9E9E9E),
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
                  fontFamily: 'Cairo',
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
                  borderRadius: BorderRadius.circular(14),
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
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: state.isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'تأكيد التحقق',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            color: Colors.white,
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
                    fontFamily: 'Cairo',
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
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEEEEEE), width: 1.5),
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
              fontFamily: 'Cairo',
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
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: color, width: width),
      );

  return InputDecoration(
    hintText: '000000',
    hintStyle: const TextStyle(
      fontFamily: 'Cairo',
      fontSize: 26,
      letterSpacing: 12,
      fontWeight: FontWeight.bold,
      color: Color(0xFFBDBDBD),
    ),
    filled: true,
    fillColor: const Color(0xFFFAFAFA),
    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
    enabledBorder: border(const Color(0xFFEEEEEE), 1.5),
    focusedBorder: border(_forest, 1.8),
    errorBorder: border(Colors.redAccent.withValues(alpha: .5), 1.5),
    focusedErrorBorder: border(Colors.redAccent, 1.8),
  );
}
