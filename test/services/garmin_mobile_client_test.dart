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
}
