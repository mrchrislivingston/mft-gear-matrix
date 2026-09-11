import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mft_gear_matrix/services/garmin_mobile_client.dart';
import 'package:mft_gear_matrix/services/garmin_session_store.dart';

const originalSession = GarminSession(
  accessToken: 'old-access-token',
  refreshToken: 'old-refresh-token',
  clientId: 'garmin-client-id',
);

void main() {
  test('validates session with read-only profile request', () async {
    final client = GarminMobileClient(
      session: originalSession,
      httpClient: MockClient((request) async {
        expect(
          request.url.toString(),
          'https://connectapi.garmin.com/'
          'userprofile-service/socialProfile',
        );
        expect(request.headers['authorization'], 'Bearer old-access-token');

        return http.Response(
          jsonEncode({
            'displayName': 'athlete-display',
            'fullName': 'Test Athlete',
          }),
          200,
        );
      }),
    );

    final profile = await client.testConnection();

    expect(profile.bestName, 'Test Athlete');
  });

  test('refreshes rejected token and saves new session', () async {
    var profileRequests = 0;
    GarminSession? savedSession;

    final client = GarminMobileClient(
      session: originalSession,
      sessionSaver: (session) async {
        savedSession = session;
      },
      httpClient: MockClient((request) async {
        if (request.url.host == 'diauth.garmin.com') {
          expect(request.method, 'POST');
          expect(
            request.headers['authorization'],
            'Basic ${base64Encode(utf8.encode('garmin-client-id:'))}',
          );

          final body = (request as http.Request).bodyFields;

          expect(body['grant_type'], 'refresh_token');
          expect(body['client_id'], 'garmin-client-id');
          expect(body['refresh_token'], 'old-refresh-token');

          return http.Response(
            jsonEncode({
              'access_token': 'new-access-token',
              'refresh_token': 'new-refresh-token',
            }),
            200,
          );
        }

        profileRequests++;

        if (profileRequests == 1) {
          expect(request.headers['authorization'], 'Bearer old-access-token');
          return http.Response('', 401);
        }

        expect(request.headers['authorization'], 'Bearer new-access-token');

        return http.Response(
          jsonEncode({
            'displayName': 'athlete-display',
            'fullName': 'Test Athlete',
          }),
          200,
        );
      }),
    );

    final profile = await client.testConnection();

    expect(profile.bestName, 'Test Athlete');
    expect(profileRequests, 2);
    expect(savedSession, isNotNull);
    expect(savedSession!.accessToken, 'new-access-token');
    expect(savedSession!.refreshToken, 'new-refresh-token');
  });

  test('does not expose Garmin response content in errors', () async {
    final client = GarminMobileClient(
      session: originalSession,
      httpClient: MockClient((request) async {
        return http.Response('private server response content', 500);
      }),
    );

    expect(
      () => client.testConnection(),
      throwsA(
        isA<GarminMobileException>()
            .having((error) => error.message, 'message', contains('HTTP 500'))
            .having(
              (error) => error.message,
              'message',
              isNot(contains('private server response')),
            ),
      ),
    );
  });

  test('reads and filters scheduled Garmin workouts for a month', () async {
    final client = GarminMobileClient(
      session: originalSession,
      httpClient: MockClient((request) async {
        expect(request.method, 'GET');
        expect(
          request.url.toString(),
          'https://connectapi.garmin.com/'
          'calendar-service/year/2026/month/8',
        );
        expect(request.headers['authorization'], 'Bearer old-access-token');

        return http.Response(
          jsonEncode({
            'year': 2026,
            'month': 8,
            'calendarItems': [
              {
                'id': 10,
                'itemType': 'activity',
                'title': 'Morning Run',
                'date': '2026-09-07',
                'workoutId': null,
              },
              {
                'id': 1770727338,
                'itemType': 'workout',
                'title': 'Z2 Row - 2026-09-07',
                'date': '2026-09-07',
                'workoutId': 1691105102,
                'sportTypeKey': 'cardio_training',
              },
              {
                'id': 11,
                'itemType': 'weight',
                'title': null,
                'date': '2026-09-07',
                'workoutId': null,
              },
            ],
          }),
          200,
        );
      }),
    );

    final workouts = await client.getScheduledWorkoutsForMonth(
      year: 2026,
      month: 9,
    );

    expect(workouts, hasLength(1));
    expect(workouts.single.scheduleId, 1770727338);
    expect(workouts.single.workoutId, 1691105102);
    expect(workouts.single.title, 'Z2 Row - 2026-09-07');
    expect(workouts.single.date, '2026-09-07');
    expect(workouts.single.sportTypeKey, 'cardio_training');
  });

  test('calendar inspection refreshes once after a rejected token', () async {
    var calendarRequests = 0;

    final client = GarminMobileClient(
      session: originalSession,
      httpClient: MockClient((request) async {
        if (request.url.host == 'diauth.garmin.com') {
          return http.Response(
            jsonEncode({
              'access_token': 'new-access-token',
              'refresh_token': 'new-refresh-token',
            }),
            200,
          );
        }

        calendarRequests++;

        if (calendarRequests == 1) {
          return http.Response('', 401);
        }

        expect(request.headers['authorization'], 'Bearer new-access-token');

        return http.Response(jsonEncode({'calendarItems': []}), 200);
      }),
    );

    final workouts = await client.getScheduledWorkoutsForMonth(
      year: 2026,
      month: 9,
    );

    expect(workouts, isEmpty);
    expect(calendarRequests, 2);
  });

  test('uploads a Garmin workout and validates its returned ID', () async {
    final payload = <String, dynamic>{
      'workoutName': 'G3 Run - 2026-09-16',
      'workoutSegments': [
        {
          'segmentOrder': 1,
          'workoutSteps': [
            {'stepOrder': 1},
          ],
        },
      ],
    };

    final client = GarminMobileClient(
      session: originalSession,
      httpClient: MockClient((request) async {
        expect(request.method, 'POST');
        expect(
          request.url.toString(),
          'https://connectapi.garmin.com/workout-service/workout',
        );
        expect(request.headers['authorization'], 'Bearer old-access-token');
        expect(request.headers['content-type'], contains('application/json'));
        expect(jsonDecode(request.body), payload);

        return http.Response(
          jsonEncode({
            'workoutId': 1692000001,
            'workoutName': 'G3 Run - 2026-09-16',
          }),
          200,
        );
      }),
    );

    final uploaded = await client.uploadWorkout(payload);

    expect(uploaded.workoutId, 1692000001);
    expect(uploaded.workoutName, 'G3 Run - 2026-09-16');
  });

  test('rejects a successful upload response without a workout ID', () async {
    final client = GarminMobileClient(
      session: originalSession,
      httpClient: MockClient((request) async {
        return http.Response(jsonEncode({'workoutName': 'Missing ID'}), 200);
      }),
    );

    expect(
      () => client.uploadWorkout({
        'workoutName': 'Missing ID',
        'workoutSegments': [
          {
            'workoutSteps': [
              {'stepOrder': 1},
            ],
          },
        ],
      }),
      throwsA(
        isA<GarminMobileException>().having(
          (error) => error.message,
          'message',
          contains('did not return a workout ID'),
        ),
      ),
    );
  });

  test('schedules an uploaded workout on an exact date', () async {
    final client = GarminMobileClient(
      session: originalSession,
      httpClient: MockClient((request) async {
        expect(request.method, 'POST');
        expect(
          request.url.toString(),
          'https://connectapi.garmin.com/'
          'workout-service/schedule/1692000001',
        );
        expect(request.headers['authorization'], 'Bearer old-access-token');
        expect(jsonDecode(request.body), {'date': '2026-09-16'});

        return http.Response(
          jsonEncode({
            'id': 1772000001,
            'workoutId': 1692000001,
            'date': '2026-09-16',
          }),
          200,
        );
      }),
    );

    final response = await client.scheduleWorkout(
      workoutId: 1692000001,
      date: '2026-09-16',
    );

    expect(response['id'], 1772000001);
    expect(response['workoutId'], 1692000001);
    expect(response['date'], '2026-09-16');
  });

  test('rejects an impossible schedule date before making a request', () async {
    var requests = 0;

    final client = GarminMobileClient(
      session: originalSession,
      httpClient: MockClient((request) async {
        requests++;
        return http.Response('{}', 200);
      }),
    );

    expect(
      () => client.scheduleWorkout(workoutId: 1692000001, date: '2026-02-30'),
      throwsA(isA<GarminMobileException>()),
    );
    expect(requests, 0);
  });

  test('write errors never expose Garmin response content', () async {
    final client = GarminMobileClient(
      session: originalSession,
      httpClient: MockClient((request) async {
        return http.Response('private Garmin response', 500);
      }),
    );

    expect(
      () => client.uploadWorkout({
        'workoutName': 'Safe Error Test',
        'workoutSegments': [
          {
            'workoutSteps': [
              {'stepOrder': 1},
            ],
          },
        ],
      }),
      throwsA(
        isA<GarminMobileException>()
            .having((error) => error.message, 'message', contains('HTTP 500'))
            .having(
              (error) => error.message,
              'message',
              isNot(contains('private Garmin response')),
            ),
      ),
    );
  });

  test('deletes only a specifically identified uploaded workout', () async {
    final client = GarminMobileClient(
      session: originalSession,
      httpClient: MockClient((request) async {
        expect(request.method, 'DELETE');
        expect(
          request.url.toString(),
          'https://connectapi.garmin.com/'
          'workout-service/workout/1692000001',
        );
        expect(request.headers['authorization'], 'Bearer old-access-token');

        return http.Response('', 204);
      }),
    );

    await client.deleteWorkout(1692000001);
  });
}
