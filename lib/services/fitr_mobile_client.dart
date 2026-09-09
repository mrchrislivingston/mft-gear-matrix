import 'dart:convert';

import 'package:http/http.dart' as http;

import 'fitr_credentials_store.dart';

class FitrMobileException implements Exception {
  final String message;

  const FitrMobileException(this.message);

  @override
  String toString() => message;
}

class FitrWeekDay {
  final String date;
  final String scheduleId;
  final String planTitle;
  final Map<String, dynamic> calendarDay;
  final Map<String, dynamic> detail;

  const FitrWeekDay({
    required this.date,
    required this.scheduleId,
    required this.planTitle,
    required this.calendarDay,
    required this.detail,
  });
}

class FitrWeekSnapshot {
  final DateTime monday;
  final DateTime sunday;
  final List<FitrWeekDay> days;

  const FitrWeekSnapshot({
    required this.monday,
    required this.sunday,
    required this.days,
  });
}

class FitrMobileClient {
  static const defaultBaseUrl = 'https://app.fitr.training/api';

  final FitrCredentials credentials;
  final http.Client httpClient;
  final String baseUrl;
  final String clientTimezone;

  const FitrMobileClient({
    required this.credentials,
    required this.httpClient,
    this.baseUrl = defaultBaseUrl,
    this.clientTimezone = 'America/Denver',
  });

  Future<FitrWeekSnapshot> fetchWeek(DateTime monday) async {
    credentials.validate();

    final normalizedMonday = DateTime(monday.year, monday.month, monday.day);

    if (normalizedMonday.weekday != DateTime.monday) {
      throw const FitrMobileException(
        'The requested FITR week must begin on Monday.',
      );
    }

    final sunday = normalizedMonday.add(const Duration(days: 6));
    final calendarUri = Uri.parse('$baseUrl/schedule').replace(
      queryParameters: {
        'from': _dateOnly(normalizedMonday),
        'to': _dateOnly(sunday),
      },
    );

    final calendar = await _getJson(calendarUri);
    final days = <FitrWeekDay>[];
    final rawPlans = calendar['plans'];

    if (rawPlans is! List) {
      throw const FitrMobileException(
        'FITR returned an invalid calendar response.',
      );
    }

    for (final rawPlan in rawPlans) {
      if (rawPlan is! Map) {
        continue;
      }

      final plan = Map<String, dynamic>.from(rawPlan);
      final planTitle = plan['title']?.toString() ?? 'Unknown';
      final rawDays = plan['days'];

      if (rawDays is! List) {
        continue;
      }

      for (final rawDay in rawDays) {
        if (rawDay is! Map) {
          continue;
        }

        final calendarDay = Map<String, dynamic>.from(rawDay);
        final date = calendarDay['date']?.toString();
        final scheduleId = calendarDay['schedule_id']?.toString();

        if (date == null ||
            date.isEmpty ||
            scheduleId == null ||
            scheduleId.isEmpty) {
          throw const FitrMobileException(
            'FITR returned a day without a date or schedule ID.',
          );
        }

        final detailUri = Uri.parse(
          '$baseUrl/schedule/$scheduleId/'
          'athlete/${credentials.athleteId}',
        );

        days.add(
          FitrWeekDay(
            date: date,
            scheduleId: scheduleId,
            planTitle: planTitle,
            calendarDay: calendarDay,
            detail: await _getJson(detailUri),
          ),
        );
      }
    }

    return FitrWeekSnapshot(
      monday: normalizedMonday,
      sunday: sunday,
      days: List.unmodifiable(days),
    );
  }

  Future<Map<String, dynamic>> _getJson(Uri uri) async {
    final response = await httpClient.get(
      uri,
      headers: {
        'accept': 'application/json, text/plain, */*',
        'api-version': '3',
        'authorization': 'bearer ${credentials.token}',
        'client-timezone': clientTimezone,
        'cookie': credentials.cookie,
        'referer': 'https://app.fitr.training/user/calendar',
      },
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw FitrMobileException('FITR returned HTTP ${response.statusCode}.');
    }

    try {
      final decoded = jsonDecode(response.body);

      if (decoded is! Map) {
        throw const FormatException('Expected a JSON object.');
      }

      return Map<String, dynamic>.from(decoded);
    } on FormatException catch (error) {
      throw FitrMobileException('FITR returned invalid JSON: $error');
    }
  }

  String _dateOnly(DateTime value) {
    final year = value.year.toString().padLeft(4, '0');
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }
}
