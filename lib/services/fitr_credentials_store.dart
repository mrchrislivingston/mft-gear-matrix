import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class FitrCredentialsException implements Exception {
  final String message;

  const FitrCredentialsException(this.message);

  @override
  String toString() => message;
}

class FitrCredentials {
  final String token;
  final String cookie;
  final int athleteId;

  const FitrCredentials({
    required this.token,
    required this.cookie,
    required this.athleteId,
  });

  void validate() {
    if (token.trim().isEmpty) {
      throw const FitrCredentialsException('FITR token is required.');
    }

    if (cookie.trim().isEmpty) {
      throw const FitrCredentialsException('FITR cookie is required.');
    }

    if (athleteId < 1) {
      throw const FitrCredentialsException(
        'FITR athlete ID must be a positive integer.',
      );
    }
  }
}

abstract interface class SecureKeyValueStore {
  Future<String?> read(String key);

  Future<void> write(String key, String value);

  Future<void> delete(String key);
}

class FlutterSecureKeyValueStore implements SecureKeyValueStore {
  final FlutterSecureStorage storage;

  const FlutterSecureKeyValueStore({
    this.storage = const FlutterSecureStorage(),
  });

  @override
  Future<String?> read(String key) {
    return storage.read(key: key);
  }

  @override
  Future<void> write(String key, String value) {
    return storage.write(key: key, value: value);
  }

  @override
  Future<void> delete(String key) {
    return storage.delete(key: key);
  }
}

class FitrCredentialsStore {
  static const _tokenKey = 'fitr_token';
  static const _cookieKey = 'fitr_cookie';
  static const _athleteIdKey = 'fitr_athlete_id';

  final SecureKeyValueStore storage;

  const FitrCredentialsStore({required this.storage});

  factory FitrCredentialsStore.secure() {
    return const FitrCredentialsStore(storage: FlutterSecureKeyValueStore());
  }

  Future<void> save(FitrCredentials credentials) async {
    credentials.validate();

    await storage.write(_tokenKey, credentials.token.trim());
    await storage.write(_cookieKey, credentials.cookie.trim());
    await storage.write(_athleteIdKey, credentials.athleteId.toString());
  }

  Future<FitrCredentials?> load() async {
    final token = await storage.read(_tokenKey);
    final cookie = await storage.read(_cookieKey);
    final athleteIdText = await storage.read(_athleteIdKey);

    if (token == null && cookie == null && athleteIdText == null) {
      return null;
    }

    if (token == null || cookie == null || athleteIdText == null) {
      throw const FitrCredentialsException(
        'Stored FITR credentials are incomplete.',
      );
    }

    final athleteId = int.tryParse(athleteIdText);

    if (athleteId == null || athleteId < 1) {
      throw const FitrCredentialsException(
        'Stored FITR athlete ID is invalid.',
      );
    }

    final credentials = FitrCredentials(
      token: token,
      cookie: cookie,
      athleteId: athleteId,
    );

    credentials.validate();
    return credentials;
  }

  Future<void> clear() async {
    await storage.delete(_tokenKey);
    await storage.delete(_cookieKey);
    await storage.delete(_athleteIdKey);
  }
}
