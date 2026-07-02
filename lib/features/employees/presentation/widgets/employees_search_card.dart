import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../shared/theme/app_colors.dart';
import '../bloc/employees_bloc.dart';
import '../bloc/employees_event.dart';

class EmployeesSearchCard extends StatefulWidget {
  const EmployeesSearchCard({super.key});

  @override
  State<EmployeesSearchCard> createState() => _EmployeesSearchCardState();
}

class _EmployeesSearchCardState extends State<EmployeesSearchCard> {
  final _controller = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      context.read<EmployeesBloc>().add(SearchEmployees(value));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: SizedBox(
        height: 50,
        child: TextField(
          controller: _controller,
          onChanged: _onChanged,
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.right,
          decoration: InputDecoration(
            hintText: 'البحث عن موظف (الاسم، اسم المستخدم، البريد الإلكتروني)...',
            hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
            suffixIcon: const Icon(
              Icons.search_rounded,
              color: AppColors.textSecondary,
              size: 26,
            ),
            filled: true,
            fillColor: AppColors.surface,
            contentPadding: const EdgeInsets.symmetric(horizontal: 18),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
          ),
        ),
      ),
    );
  }
}
