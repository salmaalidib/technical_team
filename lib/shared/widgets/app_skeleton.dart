import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../theme/app_colors.dart';

/// ─────────────────────────────────────────────────────────────────────────
/// App skeleton loaders — built on the `skeletonizer` package.
///
/// These replace the bare [CircularProgressIndicator] on initial page / list /
/// grid / table loads. Each loader renders a handful of dummy widgets whose
/// layout mirrors the real content, wrapped in a [Skeletonizer] that paints
/// them as shimmering "bones". Feels faster and far more polished than a
/// spinning circle.
///
/// Drop-in replacement for a loading spinner:
///
///   case RequestStatus.loading:
///     return const AppSkeleton.cards();      // grid of cards
///     return const AppSkeleton.list();       // vertical rows
///     return const AppSkeleton.table();      // header + data rows
///
/// Every loader is `const` and self-contained (already wrapped in a
/// [Skeletonizer]), so it can sit directly where the spinner used to be.
/// ─────────────────────────────────────────────────────────────────────────

/// The shared shimmer effect, tinted with the app palette so the bones blend
/// with the surrounding surfaces instead of reading as a foreign grey.
const ShimmerEffect _appShimmer = ShimmerEffect(
  baseColor: Color(0xffE7E9EC),
  highlightColor: Color(0xffF6F7F9),
  duration: Duration(milliseconds: 1300),
);

enum _SkeletonKind { cards, list, table }

/// Namespace for the app's skeleton loaders. Use the `const` named
/// constructors — each renders its shape wrapped in a shared [Skeletonizer].
class AppSkeleton extends StatelessWidget {
  final _SkeletonKind _kind;
  final int? _columns;
  final int _itemCount;
  final bool _withFooter;
  final double _gap;
  final double _rowHeight;
  final EdgeInsetsGeometry _padding;

  /// A responsive grid of card skeletons — mirrors the template / role /
  /// type-process card grids (avatar bubble + title + subtitle + two chips,
  /// with an optional footer bar).
  const AppSkeleton.cards({
    super.key,
    int? columns,
    int itemCount = 6,
    bool withFooter = false,
    double gap = 22,
    EdgeInsetsGeometry padding = EdgeInsets.zero,
  })  : _kind = _SkeletonKind.cards,
        _columns = columns,
        _itemCount = itemCount,
        _withFooter = withFooter,
        _gap = gap,
        _rowHeight = 0,
        _padding = padding;

  /// A vertical list of row skeletons — icon bubble + title + subtitle.
  const AppSkeleton.list({
    super.key,
    int itemCount = 7,
    double rowHeight = 64,
    EdgeInsetsGeometry padding = EdgeInsets.zero,
  })  : _kind = _SkeletonKind.list,
        _columns = null,
        _itemCount = itemCount,
        _withFooter = false,
        _gap = 0,
        _rowHeight = rowHeight,
        _padding = padding;

  /// A table skeleton — a header strip plus data rows. Mirrors the Syncfusion
  /// DataGrid pages (departments / employees / institutions).
  const AppSkeleton.table({
    super.key,
    int rows = 8,
    int columns = 5,
    EdgeInsetsGeometry padding = EdgeInsets.zero,
  })  : _kind = _SkeletonKind.table,
        _columns = columns,
        _itemCount = rows,
        _withFooter = false,
        _gap = 0,
        _rowHeight = 0,
        _padding = padding;

  @override
  Widget build(BuildContext context) {
    final Widget child;
    switch (_kind) {
      case _SkeletonKind.cards:
        child = _SkeletonCardGrid(
          columns: _columns,
          itemCount: _itemCount,
          withFooter: _withFooter,
          gap: _gap,
          padding: _padding,
        );
        break;
      case _SkeletonKind.list:
        child = _SkeletonList(
          itemCount: _itemCount,
          rowHeight: _rowHeight,
          padding: _padding,
        );
        break;
      case _SkeletonKind.table:
        child = _SkeletonTable(
          rows: _itemCount,
          columns: _columns ?? 5,
          padding: _padding,
        );
        break;
    }

    return Skeletonizer(
      enabled: true,
      effect: _appShimmer,
      child: child,
    );
  }
}

// ════════════════════════ card grid ════════════════════════

class _SkeletonCardGrid extends StatelessWidget {
  final int? columns;
  final int itemCount;
  final bool withFooter;
  final double gap;
  final EdgeInsetsGeometry padding;

  const _SkeletonCardGrid({
    required this.columns,
    required this.itemCount,
    required this.withFooter,
    required this.gap,
    required this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final cols = columns ?? (width >= 1000 ? 3 : (width >= 640 ? 2 : 1));
          final cardWidth = (width - (cols - 1) * gap) / cols;
          return Wrap(
            spacing: gap,
            runSpacing: gap,
            children: List.generate(
              itemCount,
              (_) => SizedBox(
                width: cardWidth,
                child: _SkeletonCard(withFooter: withFooter),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  final bool withFooter;
  const _SkeletonCard({required this.withFooter});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            textDirection: TextDirection.rtl,
            children: [
              _Bone.circle(44),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Bone(width: 140, height: 15),
                    SizedBox(height: 8),
                    _Bone(width: 90, height: 12),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Row(
            textDirection: TextDirection.rtl,
            children: [
              _Bone(width: 74, height: 26, radius: 8),
              SizedBox(width: 8),
              _Bone(width: 74, height: 26, radius: 8),
            ],
          ),
          if (withFooter) ...[
            const SizedBox(height: 18),
            const _Bone(height: 44, radius: 10),
          ],
        ],
      ),
    );
  }
}

// ════════════════════════ list ════════════════════════

class _SkeletonList extends StatelessWidget {
  final int itemCount;
  final double rowHeight;
  final EdgeInsetsGeometry padding;

  const _SkeletonList({
    required this.itemCount,
    required this.rowHeight,
    required this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: List.generate(
          itemCount,
          (_) => Container(
            height: rowHeight,
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: const Row(
              textDirection: TextDirection.rtl,
              children: [
                _Bone.circle(38),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _Bone(width: 160, height: 13),
                      SizedBox(height: 8),
                      _Bone(width: 100, height: 11),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ════════════════════════ table ════════════════════════

class _SkeletonTable extends StatelessWidget {
  final int rows;
  final int columns;
  final EdgeInsetsGeometry padding;

  const _SkeletonTable({
    required this.rows,
    required this.columns,
    required this.padding,
  });

  Widget _cells({required bool header}) => Row(
        textDirection: TextDirection.rtl,
        children: List.generate(columns, (i) {
          // Vary widths a touch so rows don't look like a perfect grid.
          final flex = (i % 3) + 2;
          return Expanded(
            flex: flex,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: _Bone(height: header ? 14 : 12),
            ),
          );
        }),
      );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        clipBehavior: Clip.antiAlias,
        // A SingleChildScrollView sizes to the column's natural height under
        // unbounded constraints (e.g. inside another scroll view) and scrolls
        // instead of overflowing when the parent's height is smaller than the
        // content — so the fixed [rows] never throw a RenderFlex overflow.
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 52,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.lightPrimary,
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: _cells(header: true),
              ),
              for (var r = 0; r < rows; r++)
                Container(
                  height: 56,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                          color: AppColors.border.withValues(alpha: .6)),
                    ),
                  ),
                  child: _cells(header: false),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ════════════════════════ bone primitive ════════════════════════

/// A single grey placeholder shape. Skeletonizer turns it into a shimmering
/// bone because it is a plain [Container] with a solid colour.
class _Bone extends StatelessWidget {
  final double? width;
  final double height;
  final double radius;
  final bool circle;

  const _Bone({
    this.width,
    this.height = 14,
    this.radius = 8,
  }) : circle = false;

  const _Bone.circle(double size)
      : width = size,
        height = size,
        radius = 0,
        circle = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xffE7E9EC),
        shape: circle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: circle ? null : BorderRadius.circular(radius),
      ),
    );
  }
}
