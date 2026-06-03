import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/enums/request_status.dart';
import '../../domain/entities/dynamic_field.dart';
import '../../domain/entities/file_definition.dart';
import '../bloc/fields_bloc.dart';
import '../bloc/fields_event.dart';
import '../bloc/fields_state.dart';
import '../bloc/files_bloc.dart';
import '../bloc/files_event.dart';
import '../bloc/files_state.dart';
import '../widgets/create_field_dialog.dart';
import '../widgets/create_file_dialog.dart';
import '../widgets/field_card.dart';
import '../widgets/fields_files_header.dart';
import '../widgets/files_table.dart';
import '../widgets/section_tabs.dart';

class FieldsPage extends StatelessWidget {
  const FieldsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => getIt<FieldsBloc>()..add(const LoadFields()),
        ),
        BlocProvider(
          create: (_) => getIt<FilesBloc>()..add(const LoadFiles()),
        ),
      ],
      child: const _FieldsView(),
    );
  }
}

class _FieldsView extends StatefulWidget {
  const _FieldsView();

  @override
  State<_FieldsView> createState() => _FieldsViewState();
}

class _FieldsViewState extends State<_FieldsView> {
  int _tab = 0; // 0 = dynamic fields, 1 = file definitions

  void _openFieldDialog({DynamicField? field}) {
    final bloc = context.read<FieldsBloc>();
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (_) => BlocProvider.value(
        value: bloc,
        child: CreateFieldDialog(field: field),
      ),
    );
  }

  void _openFileDialog({FileDefinition? file}) {
    final bloc = context.read<FilesBloc>();
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (_) => BlocProvider.value(
        value: bloc,
        child: CreateFileDialog(file: file),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final horizontal = MediaQuery.sizeOf(context).width < 700 ? 16.0 : 40.0;
    final fieldsCount = context.watch<FieldsBloc>().state.fields.length;
    final filesCount = context.watch<FilesBloc>().state.files.length;

    return Container(
      color: const Color(0xffF0EFE7),
      padding: EdgeInsets.fromLTRB(horizontal, 28, horizontal, 30),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FieldsFilesHeader(
              isFilesTab: _tab == 1,
              onCreate: () =>
                  _tab == 1 ? _openFileDialog() : _openFieldDialog(),
            ),
            const SizedBox(height: 26),
            SectionTabs(
              activeIndex: _tab,
              fieldsCount: fieldsCount,
              filesCount: filesCount,
              onChanged: (i) => setState(() => _tab = i),
            ),
            const SizedBox(height: 24),
            if (_tab == 0)
              _FieldsBody(onEdit: (f) => _openFieldDialog(field: f))
            else
              _FilesBody(onEdit: (f) => _openFileDialog(file: f)),
          ],
        ),
      ),
    );
  }
}

class _FieldsBody extends StatelessWidget {
  final ValueChanged<DynamicField> onEdit;

  const _FieldsBody({required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FieldsBloc, FieldsState>(
      buildWhen: (p, c) => p.status != c.status || p.fields != c.fields,
      builder: (context, state) {
        switch (state.status) {
          case RequestStatus.initial:
          case RequestStatus.loading:
            return const _Loading();
          case RequestStatus.failure:
            return _ErrorState(
              message: state.error ?? 'حدث خطأ غير متوقع',
              onRetry: () => context.read<FieldsBloc>().add(const LoadFields()),
            );
          case RequestStatus.success:
            if (state.fields.isEmpty) {
              return const _Empty('لا توجد حقول لعرضها');
            }
            return LayoutBuilder(
              builder: (context, constraints) {
                const gap = 22.0;
                final w = constraints.maxWidth;
                final columns = w >= 1100 ? 3 : (w >= 700 ? 2 : 1);
                final cardWidth = (w - (columns - 1) * gap) / columns;
                return Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  textDirection: TextDirection.rtl,
                  children: [
                    for (final field in state.fields)
                      SizedBox(
                        width: cardWidth,
                        child: FieldCard(
                          key: ValueKey(field.id),
                          field: field,
                          onEdit: () => onEdit(field),
                        ),
                      ),
                  ],
                );
              },
            );
        }
      },
    );
  }
}

class _FilesBody extends StatelessWidget {
  final ValueChanged<FileDefinition> onEdit;

  const _FilesBody({required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FilesBloc, FilesState>(
      buildWhen: (p, c) => p.status != c.status || p.files != c.files,
      builder: (context, state) {
        switch (state.status) {
          case RequestStatus.initial:
          case RequestStatus.loading:
            return const _Loading();
          case RequestStatus.failure:
            return _ErrorState(
              message: state.error ?? 'حدث خطأ غير متوقع',
              onRetry: () => context.read<FilesBloc>().add(const LoadFiles()),
            );
          case RequestStatus.success:
            if (state.files.isEmpty) {
              return const _Empty('لا توجد تعريفات ملفات لعرضها');
            }
            return FilesTable(files: state.files, onEdit: onEdit);
        }
      },
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 80),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _Empty extends StatelessWidget {
  final String message;

  const _Empty(this.message);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 80),
      child: Center(
        child: Text(
          message,
          style: const TextStyle(color: Colors.black54, fontSize: 15),
        ),
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
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent, size: 44),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
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
