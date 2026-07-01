import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../shared/theme/app_colors.dart';
import '../bloc/departments_bloc.dart';
import '../bloc/departments_event.dart';
import '../bloc/departments_state.dart';

/// بطاقة بحث الأقسام — بنفس تصميم بطاقة بحث الموظفين. البحث من جهة العميل ضمن
/// المستوى الحالي، مع debounce، ويتزامن مع الـ BLoC (يُفرَّغ الحقل عند التنقّل).
class DepartmentSearchBar extends StatefulWidget {
  const DepartmentSearchBar({super.key});

  @override
  State<DepartmentSearchBar> createState() => _DepartmentSearchBarState();
}

class _DepartmentSearchBarState extends State<DepartmentSearchBar> {
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
      context.read<DepartmentsBloc>().add(SearchChanged(value));
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<DepartmentsBloc, DepartmentsState>(
      listenWhen: (p, c) => p.searchQuery != c.searchQuery,
      listener: (context, state) {
        // إعادة تعيين خارجية (بعد التنقّل بين المستويات): نُفرّغ الحقل.
        if (state.searchQuery.isEmpty && _controller.text.isNotEmpty) {
          _controller.clear();
        }
      },
      child: Container(
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
              hintText: 'البحث عن قسم بالاسم...',
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
      ),
    );
  }
}
