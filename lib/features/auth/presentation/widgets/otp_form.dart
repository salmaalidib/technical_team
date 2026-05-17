import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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

  @override
  Widget build(BuildContext context) {

    return BlocBuilder<OtpBloc, OtpState>(

      builder: (context, state) {

        return Padding(
          padding: const EdgeInsets.all(24),

          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,

            children: [

              const Text(
                "أدخل رمز التحقق",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              const Text(
                "تم إرسال الرمز إلى رقم الهاتف",
              ),

              const SizedBox(height: 32),

              TextField(
                controller: otpController,

                keyboardType: TextInputType.number,

                decoration: const InputDecoration(
                  hintText: "OTP",
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 55,

                child: ElevatedButton(

                  onPressed: state.isLoading
                      ? null
                      : () {

                          context.read<OtpBloc>().add(
                            OtpSubmitted(
                              sessionId: widget.sessionId,
                              otp: otpController.text,
                            ),
                          );
                        },

                  child: state.isLoading
                      ? const CircularProgressIndicator()
                      : const Text("تحقق"),
                ),
              ),

              const SizedBox(height: 20),

              seconds > 0
                  ? Text(
                      "إعادة الإرسال خلال $seconds ثانية",
                    )
                  : TextButton(
                      onPressed: () {

                        /// TODO:
                        /// RESEND OTP
                      },

                      child: const Text(
                        "إعادة إرسال الرمز",
                      ),
                    ),
            ],
          ),
        );
      },
    );
  }
}