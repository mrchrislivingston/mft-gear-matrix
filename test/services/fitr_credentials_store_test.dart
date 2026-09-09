import 'package:flutter_test/flutter_test.dart';
import 'package:mft_gear_matrix/services/fitr_credentials_store.dart';

class FakeSecureKeyValueStore implements SecureKeyValueStore {
  final values = <String, String>{};

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
  test('securely saves and reloads FITR credentials', () async {
    final secureStorage = FakeSecureKeyValueStore();
    final store = FitrCredentialsStore(storage: secureStorage);

    await store.save(
      const FitrCredentials(
        token: 'test-token',
        cookie: 'test-cookie',
        athleteId: 12345,
      ),
    );

    final credentials = await store.load();

    expect(credentials, isNotNull);
    expect(credentials!.token, 'test-token');
    expect(credentials.cookie, 'test-cookie');
    expect(credentials.athleteId, 12345);
  });

  test('returns null when no FITR credentials are stored', () async {
    final store = FitrCredentialsStore(storage: FakeSecureKeyValueStore());

    expect(await store.load(), isNull);
  });

  test('rejects incomplete stored credentials', () async {
    final secureStorage = FakeSecureKeyValueStore();
    secureStorage.values['fitr_token'] = 'test-token';

    final store = FitrCredentialsStore(storage: secureStorage);

    expect(store.load, throwsA(isA<FitrCredentialsException>()));
  });

  test('clears every stored FITR credential', () async {
    final secureStorage = FakeSecureKeyValueStore();
    final store = FitrCredentialsStore(storage: secureStorage);

    await store.save(
      const FitrCredentials(
        token: 'test-token',
        cookie: 'test-cookie',
        athleteId: 12345,
      ),
    );

    await store.clear();

    expect(await store.load(), isNull);
    expect(secureStorage.values, isEmpty);
  });
}
