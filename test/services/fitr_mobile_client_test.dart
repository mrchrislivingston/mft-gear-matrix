import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mft_gear_matrix/services/fitr_credentials_store.dart';
import 'package:mft_gear_matrix/services/fitr_mobile_client.dart';

void main() {
  const credentials = FitrCredentials(
    token: 'test-token',
    cookie: 'test-cookie',
    athleteId: 12345,
  );

  test('fetches a FITR week and each scheduled day', () async {
    final requests = <http.Request>[];

    final client = MockClient((request) async {
      requests.add(request);

      if (request.url.path == '/api/schedule') {
        return http.Response(
          jsonEncode({
            'plans': [
              {
                'title': 'Test Plan',
                'days': [
                  {
                    'date': '2026-09-15',
                    'schedule_id': 67890,
                    'week': 1,
                    'number': 2,
                  },
                ],
              },
            ],
          }),
          200,
        );
      }

      if (request.url.path == '/api/schedule/67890/athlete/12345') {
        return http.Response(
          jsonEncode({
            'day': {
              'sections': [
                {'title': 'Conditioning', 'description': 'Zone 2 C2 Bike'},
              ],
            },
          }),
          200,
        );
      }

      return http.Response('Not found', 404);
    });

    final fitr = FitrMobileClient(credentials: credentials, httpClient: client);

    final week = await fitr.fetchWeek(DateTime(2026, 9, 14));

    expect(week.days, hasLength(1));
    expect(week.days.single.planTitle, 'Test Plan');
    expect(week.days.single.date, '2026-09-15');
    expect(week.days.single.scheduleId, '67890');
    expect(week.days.single.detail['day']['sections'], hasLength(1));

    expect(requests, hasLength(2));
    expect(requests.first.url.queryParameters, {
      'from': '2026-09-14',
      'to': '2026-09-20',
    });

    for (final request in requests) {
      expect(request.headers['authorization'], 'bearer test-token');
      expect(request.headers['cookie'], 'test-cookie');
      expect(request.headers['api-version'], '3');
      expect(request.headers['client-timezone'], 'America/Denver');
    }
  });

  test('does not expose response contents in an HTTP error', () async {
    final client = MockClient((_) async {
      return http.Response('private server response', 401);
    });

    final fitr = FitrMobileClient(credentials: credentials, httpClient: client);

    expect(
      () => fitr.fetchWeek(DateTime(2026, 9, 14)),
      throwsA(
        isA<FitrMobileException>()
            .having((error) => error.message, 'message', contains('HTTP 401'))
            .having(
              (error) => error.message,
              'message',
              isNot(contains('private server response')),
            ),
      ),
    );
  });

  test('requires the requested week to start on Monday', () async {
    final client = MockClient((_) async {
      fail('HTTP must not run for an invalid date.');
    });

    final fitr = FitrMobileClient(credentials: credentials, httpClient: client);

    expect(
      () => fitr.fetchWeek(DateTime(2026, 9, 15)),
      throwsA(isA<FitrMobileException>()),
    );
  });
}
