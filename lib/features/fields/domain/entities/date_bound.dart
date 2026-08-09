import 'package:equatable/equatable.dart';

/// One end of a `date_picker` range (`min_date` / `max_date`).
///
/// The backend ([core/utils/dateBound.js]) accepts three shapes, and a stored
/// bound comes back in whichever shape it was saved in:
///   * `"YYYY-MM-DD"`                              → [AbsoluteDateBound]
///   * `"today"` or `{ type: "today" }`            → [TodayDateBound]
///   * `{ type: "relative", years, months, days }` → [RelativeDateBound]
///
/// The point of the last two is that the limit is re-evaluated every time the
/// form opens: a "must be at least 18 years old" rule written as
/// `{ type: "relative", years: -18 }` stays correct forever, whereas the
/// absolute date it resolves to today would silently rot within a year.
sealed class DateBound extends Equatable {
  const DateBound();

  /// Parses whatever the API returned. Unknown shapes fall back to an absolute
  /// bound holding the raw text rather than throwing — a malformed row must not
  /// take down the whole field list.
  factory DateBound.fromJson(dynamic raw) {
    if (raw is Map) {
      final type = raw['type'];
      if (type == 'today') return const TodayDateBound();
      if (type == 'relative') {
        return RelativeDateBound(
          years: _int(raw['years']),
          months: _int(raw['months']),
          days: _int(raw['days']),
        );
      }
      return const AbsoluteDateBound('');
    }

    final text = (raw ?? '').toString().trim();
    if (text == 'today') return const TodayDateBound();

    // A relative bound stored as a JSON string in VARCHAR — the backend's
    // parseDateBound normally decodes it, but tolerate it arriving raw.
    if (text.startsWith('{')) return const AbsoluteDateBound('');

    return AbsoluteDateBound(text);
  }

  static int _int(dynamic v) =>
      v is num ? v.toInt() : int.tryParse('${v ?? ''}') ?? 0;

  /// The value to send back — matches what the backend's Joi schema accepts.
  dynamic toJson();

  /// The concrete date this bound means today, used for previewing the limit
  /// and for checking that min never exceeds max.
  DateTime resolve({DateTime? now});

  /// A short Arabic description for read-only displays.
  String describe();

  /// `YYYY-MM-DD` for [resolve].
  static String format(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  static DateTime _startOfToday(DateTime? now) {
    final n = now ?? DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }
}

/// A fixed calendar date, e.g. `1940-01-01`.
class AbsoluteDateBound extends DateBound {
  /// `YYYY-MM-DD`. May be empty while the user is still typing.
  final String date;

  const AbsoluteDateBound(this.date);

  bool get isValid => tryParse() != null;

  DateTime? tryParse() {
    final t = date.trim();
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(t)) return null;
    return DateTime.tryParse(t);
  }

  @override
  dynamic toJson() => date.trim();

  @override
  DateTime resolve({DateTime? now}) =>
      tryParse() ?? DateBound._startOfToday(now);

  @override
  String describe() => date.trim().isEmpty ? '—' : date.trim();

  @override
  List<Object?> get props => [date];
}

/// The day the form is opened.
class TodayDateBound extends DateBound {
  const TodayDateBound();

  @override
  dynamic toJson() => 'today';

  @override
  DateTime resolve({DateTime? now}) => DateBound._startOfToday(now);

  @override
  String describe() => 'اليوم';

  @override
  List<Object?> get props => const [];
}

/// An offset from today. Negative values point into the past, so
/// `years: -18` means "eighteen years before today".
class RelativeDateBound extends DateBound {
  final int years;
  final int months;
  final int days;

  const RelativeDateBound({
    this.years = 0,
    this.months = 0,
    this.days = 0,
  });

  bool get isZero => years == 0 && months == 0 && days == 0;

  @override
  dynamic toJson() => {
        'type': 'relative',
        'years': years,
        'months': months,
        'days': days,
      };

  @override
  DateTime resolve({DateTime? now}) {
    final today = DateBound._startOfToday(now);
    // DateTime normalises overflow (month 13 → next January, day 32 → next
    // month), which matches the backend's successive setFullYear/setMonth/
    // setDate calls closely enough for a preview.
    return DateTime(
      today.year + years,
      today.month + months,
      today.day + days,
    );
  }

  @override
  String describe() {
    if (isZero) return 'اليوم';

    final parts = <String>[];
    void add(int value, String singular, String dual, String plural) {
      final n = value.abs();
      if (n == 0) return;
      parts.add(n == 1
          ? singular
          : n == 2
              ? dual
              : n <= 10
                  ? '$n $plural'
                  : '$n $singular');
    }

    add(years, 'سنة', 'سنتين', 'سنوات');
    add(months, 'شهر', 'شهرين', 'أشهر');
    add(days, 'يوم', 'يومين', 'أيام');

    // The sign of the first non-zero part sets the direction; mixing
    // directions is possible but not something the editor produces.
    final negative = (years != 0 ? years : (months != 0 ? months : days)) < 0;
    final amount = parts.join(' و');
    return negative ? '$amount قبل اليوم' : '$amount بعد اليوم';
  }

  @override
  List<Object?> get props => [years, months, days];
}
