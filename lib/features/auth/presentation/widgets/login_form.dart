import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:technical_team/features/auth/presentation/bloc/login/login_bloc.dart';
import 'package:technical_team/features/auth/presentation/bloc/login/login_event.dart';
import 'package:technical_team/features/auth/presentation/bloc/login/login_state.dart';
import 'package:technical_team/shared/widgets/app_snackbar.dart';

const _forest = Color(0xFF054239);
const _charcoal = Color(0xFF3D3A3B);

class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  bool obscurePassword = true;

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    context.read<LoginBloc>().add(
          LoginSubmitted(
            username: usernameController.text.trim(),
            password: passwordController.text.trim(),
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<LoginBloc, LoginState>(
      listenWhen: (previous, current) =>
          previous.response != current.response ||
          previous.error != current.error,
      listener: (context, state) {
        if (state.response != null) {
          AppSnackBar.show(context, message: 'تم إرسال OTP');
          context.go('/otp', extra: state.response!.sessionId);
        }
        if (state.error != null) {
          AppSnackBar.show(context, message: state.error!, isError: true);
        }
      },
      child: BlocBuilder<LoginBloc, LoginState>(
        builder: (context, state) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FadeInDown(
                delay: const Duration(milliseconds: 50),
                duration: const Duration(milliseconds: 400),
                child: const Text(
                  'تسجيل الدخول',
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
                  'أدخل بيانات حسابك للمتابعة',
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
                  controller: usernameController,
                  textInputAction: TextInputAction.next,
                  style: _inputStyle,
                  decoration: _inputDecoration(
                    hint: 'اسم المستخدم',
                    prefixIcon: LucideIcons.user,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              FadeInUp(
                delay: const Duration(milliseconds: 200),
                duration: const Duration(milliseconds: 450),
                child: TextFormField(
                  controller: passwordController,
                  obscureText: obscurePassword,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: state.isLoading ? null : (_) => _submit(),
                  style: _inputStyle,
                  decoration: _inputDecoration(
                    hint: 'كلمة المرور',
                    prefixIcon: LucideIcons.lock,
                    suffixIcon: IconButton(
                      onPressed: () => setState(
                        () => obscurePassword = !obscurePassword,
                      ),
                      icon: Icon(
                        obscurePassword ? LucideIcons.eyeOff : LucideIcons.eye,
                        size: 20,
                        color: _forest.withValues(alpha: .7),
                      ),
                    ),
                  ),
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
                            'تسجيل الدخول',
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
            ],
          );
        },
      ),
    );
  }
}

const _inputStyle = TextStyle(fontFamily: 'Cairo', fontSize: 15);

InputDecoration _inputDecoration({
  required String hint,
  required IconData prefixIcon,
  Widget? suffixIcon,
}) {
  OutlineInputBorder border(Color color, double width) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: color, width: width),
      );

  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(
      fontFamily: 'Cairo',
      fontSize: 14,
      color: Color(0xFFBDBDBD),
    ),
    filled: true,
    fillColor: const Color(0xFFFAFAFA),
    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
    prefixIcon: Icon(
      prefixIcon,
      size: 20,
      color: _forest.withValues(alpha: .7),
    ),
    suffixIcon: suffixIcon,
    enabledBorder: border(const Color(0xFFEEEEEE), 1.5),
    focusedBorder: border(_forest, 1.8),
    errorBorder: border(Colors.redAccent.withValues(alpha: .5), 1.5),
    focusedErrorBorder: border(Colors.redAccent, 1.8),
    errorStyle: const TextStyle(
      fontFamily: 'Cairo',
      fontSize: 12,
      color: Colors.redAccent,
    ),
  );
}
