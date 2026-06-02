import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/enums/request_status.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../domain/entities/institution.dart';
import '../bloc/institutions_bloc.dart';
import '../bloc/institutions_event.dart';
import '../bloc/institutions_state.dart';

class InstitutionsTable extends StatefulWidget {
  const InstitutionsTable({super.key});

  @override
  State<InstitutionsTable> createState() => _InstitutionsTableState();
}

class _InstitutionsTableState extends State<InstitutionsTable> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Institution> _filter(List<Institution> all) {
    final q = _query.trim();
    if (q.isEmpty) return all;
    return all
        .where((i) =>
            i.name.contains(q) || (i.parentName?.contains(q) ?? false))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final tableWidth =
            constraints.maxWidth < 1000 ? 1000.0 : constraints.maxWidth;

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: tableWidth,
            child: Container(
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
              child: BlocBuilder<InstitutionsBloc, InstitutionsState>(
                builder: (context, state) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _TableSearch(
                        controller: _searchController,
                        onChanged: (v) => setState(() => _query = v),
                      ),
                      const _TableHeader(),
                      _buildBody(context, state),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, InstitutionsState state) {
    switch (state.status) {
      case RequestStatus.initial:
      case RequestStatus.loading:
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 60),
          child: Center(child: CircularProgressIndicator()),
        );
      case RequestStatus.failure:
        return _ErrorState(
          message: state.error ?? 'حدث خطأ غير متوقع',
          onRetry: () =>
              context.read<InstitutionsBloc>().add(const LoadInstitutions()),
        );
      case RequestStatus.success:
        final items = _filter(state.institutions);
        if (items.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 60),
            child: Center(
              child: Text(
                'لا توجد مؤسسات لعرضها',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 15,
                ),
              ),
            ),
          );
        }
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ...List.generate(
              items.length,
              (i) => _InstitutionRow(number: '${i + 1}', institution: items[i]),
            ),
            const SizedBox(height: 8),
            _TableFooter(
              shown: items.length,
              total: state.institutions.length,
            ),
          ],
        );
    }
  }
}

class _TableSearch extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _TableSearch({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: SizedBox(
        height: 52,
        child: TextField(
          controller: controller,
          onChanged: onChanged,
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.right,
          decoration: InputDecoration(
            hintText: 'البحث عن مؤسسة...',
            hintStyle: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 15,
            ),
            suffixIcon: const Icon(
              Icons.search,
              color: AppColors.textSecondary,
            ),
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

class _TableHeader extends StatelessWidget {
  const _TableHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      color: const Color(0xffF0EFE7),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: const Row(
        textDirection: TextDirection.rtl,
        children: [
          SizedBox(width: 70, child: Text('#', style: _headerStyle)),
          Expanded(flex: 3, child: Text('اسم المؤسسة', style: _headerStyle)),
          Expanded(flex: 3, child: Text('المؤسسة الأم', style: _headerStyle)),
          Expanded(flex: 2, child: Text('الموقع', style: _headerStyle)),
        ],
      ),
    );
  }
}

class _InstitutionRow extends StatelessWidget {
  final String number;
  final Institution institution;

  const _InstitutionRow({required this.number, required this.institution});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 76,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.border),
        ),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          SizedBox(width: 70, child: Text(number, style: _cellStyle)),
          Expanded(flex: 3, child: Text(institution.name, style: _cellStyle)),
          Expanded(
            flex: 3,
            child: Text(
              institution.parentName ?? '-',
              style: _cellStyle.copyWith(color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              institution.locationName ?? '-',
              style: _cellStyle.copyWith(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 40),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('إعادة المحاولة'),
          ),
        ],
      ),
    );
  }
}

class _TableFooter extends StatelessWidget {
  final int shown;
  final int total;

  const _TableFooter({required this.shown, required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 74,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      alignment: Alignment.centerRight,
      child: Text(
        'عرض $shown من $total',
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }
}

const TextStyle _headerStyle = TextStyle(
  color: AppColors.textPrimary,
  fontSize: 15,
  fontWeight: FontWeight.w800,
);

const TextStyle _cellStyle = TextStyle(
  color: AppColors.textPrimary,
  fontSize: 15,
  fontWeight: FontWeight.w600,
);
