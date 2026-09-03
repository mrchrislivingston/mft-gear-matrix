class MisfitResolvedDate {
  final String date;
  final MisfitDateStatus status;

  const MisfitResolvedDate({required this.date, required this.status});
}

enum MisfitDateStatus { exact, inferred, unresolved }

class MisfitDateResolution {
  final String programStartDate;
  final Map<String, MisfitResolvedDate> datesByProgramDay;

  const MisfitDateResolution({
    required this.programStartDate,
    required this.datesByProgramDay,
  });

  MisfitResolvedDate? dateFor(String programDay) {
    return datesByProgramDay[programDay];
  }
}

class MisfitDateResolver {
  const MisfitDateResolver();

  static final RegExp _yearPattern = RegExp(r'(20\d{2})');

  static final RegExp _weekDayPattern = RegExp(
    r'\bW(\d+)D(\d+)\b',
    caseSensitive: false,
  );

  static final RegExp _writtenDatePattern = RegExp(
    r'\b(Jan(?:uary)?|Feb(?:ruary)?|Mar(?:ch)?|Apr(?:il)?|'
    r'May|Jun(?:e)?|Jul(?:y)?|Aug(?:ust)?|Sep(?:tember)?|'
    r'Oct(?:ober)?|Nov(?:ember)?|Dec(?:ember)?)'
    r'\s+(\d{1,2})(?:st|nd|rd|th)?\b',
    caseSensitive: false,
  );

  static final RegExp _numericDatePattern = RegExp(r'\b(\d{1,2})/(\d{1,2})\b');

  int? suggestedStartYear(String fileName) {
    final match = _yearPattern.firstMatch(fileName);
    if (match == null) {
      return null;
    }
    return int.parse(match.group(1)!);
  }

  MisfitDateResolution resolve({
    required Iterable<String> headers,
    required int startYear,
  }) {
    final records = <_DateHeaderRecord>[];

    for (final header in headers) {
      final weekDayMatch = _weekDayPattern.firstMatch(header);
      if (weekDayMatch == null) {
        continue;
      }

      final week = int.parse(weekDayMatch.group(1)!);
      final day = int.parse(weekDayMatch.group(2)!);

      records.add(
        _DateHeaderRecord(
          programDay: 'W${week}D$day',
          offsetDays: ((week - 1) * 7) + (day - 1),
          explicitDate: _extractMonthDay(header),
        ),
      );
    }

    DateTime? programStart;

    for (final record in records) {
      final explicitDate = record.explicitDate;
      if (explicitDate == null) {
        continue;
      }

      for (var year = startYear; year <= startYear + 2; year++) {
        final anchor = _validatedDate(
          year,
          explicitDate.month,
          explicitDate.day,
        );
        if (anchor == null) {
          continue;
        }

        final possibleStart = anchor.subtract(
          Duration(days: record.offsetDays),
        );

        if (possibleStart.year == startYear) {
          programStart = possibleStart;
          break;
        }
      }

      if (programStart != null) {
        break;
      }
    }

    if (programStart == null) {
      return MisfitDateResolution(
        programStartDate: '',
        datesByProgramDay: Map.unmodifiable({
          for (final record in records)
            record.programDay: const MisfitResolvedDate(
              date: '',
              status: MisfitDateStatus.unresolved,
            ),
        }),
      );
    }

    final resolvedDates = <String, MisfitResolvedDate>{};

    for (final record in records) {
      final date = programStart.add(Duration(days: record.offsetDays));
      final explicitDate = record.explicitDate;

      if (explicitDate != null &&
          (date.month != explicitDate.month || date.day != explicitDate.day)) {
        throw FormatException(
          '${record.programDay} date conflicts with the program calendar',
        );
      }

      resolvedDates[record.programDay] = MisfitResolvedDate(
        date: _isoDate(date),
        status: explicitDate == null
            ? MisfitDateStatus.inferred
            : MisfitDateStatus.exact,
      );
    }

    return MisfitDateResolution(
      programStartDate: _isoDate(programStart),
      datesByProgramDay: Map.unmodifiable(resolvedDates),
    );
  }

  _MonthDay? _extractMonthDay(String header) {
    final writtenMatch = _writtenDatePattern.firstMatch(header);
    if (writtenMatch != null) {
      return _MonthDay(
        month: _monthNumber(writtenMatch.group(1)!),
        day: int.parse(writtenMatch.group(2)!),
      );
    }

    final numericMatch = _numericDatePattern.firstMatch(header);
    if (numericMatch != null) {
      return _MonthDay(
        month: int.parse(numericMatch.group(1)!),
        day: int.parse(numericMatch.group(2)!),
      );
    }

    return null;
  }

  int _monthNumber(String month) {
    return switch (month.substring(0, 3).toLowerCase()) {
      'jan' => 1,
      'feb' => 2,
      'mar' => 3,
      'apr' => 4,
      'may' => 5,
      'jun' => 6,
      'jul' => 7,
      'aug' => 8,
      'sep' => 9,
      'oct' => 10,
      'nov' => 11,
      'dec' => 12,
      _ => throw FormatException('Unsupported month: $month'),
    };
  }

  DateTime? _validatedDate(int year, int month, int day) {
    final date = DateTime(year, month, day);
    if (date.year != year || date.month != month || date.day != day) {
      return null;
    }
    return date;
  }

  String _isoDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}

class _DateHeaderRecord {
  final String programDay;
  final int offsetDays;
  final _MonthDay? explicitDate;

  const _DateHeaderRecord({
    required this.programDay,
    required this.offsetDays,
    required this.explicitDate,
  });
}

class _MonthDay {
  final int month;
  final int day;

  const _MonthDay({required this.month, required this.day});
}
