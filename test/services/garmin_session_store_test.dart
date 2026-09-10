import 'package:flutter_test/flutter_test.dart';
import 'package:mft_gear_matrix/services/fitr_credentials_store.dart';
import 'package:mft_gear_matrix/services/garmin_session_store.dart';

class FakeSecureStore implements SecureKeyValueStore {
  final Map<String, String> values = {};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async {
    values[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    values.remove(key);
  }
}

void main() {
  test('parses garminconnect serialized session', () {
    final session = GarminSession.fromJsonString('''
{
  "di_token": "access-value",
  "di_refresh_token": "refresh-value",
  "di_client_id": "client-value"
}
''');

    expect(session.accessToken, 'access-value');
    expect(session.refreshToken, 'refresh-value');
    expect(session.clientId, 'client-value');
  });

  test('rejects incomplete Garmin session', () {
    expect(
      () => GarminSession.fromJsonString('{"di_token":"access-value"}'),
      throwsA(isA<GarminSessionException>()),
    );
  });

  test('stores and clears Garmin session securely', () async {
    final storage = FakeSecureStore();
    final store = GarminSessionStore(storage: storage);
    const session = GarminSession(
      accessToken: 'access-value',
      refreshToken: 'refresh-value',
      clientId: 'client-value',
    );

    await store.save(session);

    final loaded = await store.load();

    expect(loaded, isNotNull);
    expect(loaded!.accessToken, session.accessToken);
    expect(loaded.refreshToken, session.refreshToken);
    expect(loaded.clientId, session.clientId);

    await store.clear();

    expect(await store.load(), isNull);
  });
}
