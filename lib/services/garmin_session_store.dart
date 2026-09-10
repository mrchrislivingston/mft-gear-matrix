import 'dart:convert';

import 'fitr_credentials_store.dart';

class GarminSessionException implements Exception {
  final String message;

  const GarminSessionException(this.message);

  @override
  String toString() => message;
}

class GarminSession {
  final String accessToken;
  final String refreshToken;
  final String clientId;

  const GarminSession({
    required this.accessToken,
    required this.refreshToken,
    required this.clientId,
  });

  factory GarminSession.fromJsonString(String source) {
    dynamic decoded;

    try {
      decoded = jsonDecode(source);
    } on FormatException {
      throw const GarminSessionException('Garmin session must be valid JSON.');
    }

    if (decoded is! Map) {
      throw const GarminSessionException(
        'Garmin session must be a JSON object.',
      );
    }

    final values = Map<String, dynamic>.from(decoded);

    final session = GarminSession(
      accessToken: values['di_token']?.toString() ?? '',
      refreshToken: values['di_refresh_token']?.toString() ?? '',
      clientId: values['di_client_id']?.toString() ?? '',
    );

    session.validate();
    return session;
  }

  void validate() {
    if (accessToken.trim().isEmpty) {
      throw const GarminSessionException('Garmin access token is missing.');
    }

    if (refreshToken.trim().isEmpty) {
      throw const GarminSessionException('Garmin refresh token is missing.');
    }

    if (clientId.trim().isEmpty) {
      throw const GarminSessionException('Garmin client ID is missing.');
    }
  }

  String toJsonString() {
    validate();

    return jsonEncode({
      'di_token': accessToken.trim(),
      'di_refresh_token': refreshToken.trim(),
      'di_client_id': clientId.trim(),
    });
  }

  GarminSession copyWith({
    String? accessToken,
    String? refreshToken,
    String? clientId,
  }) {
    return GarminSession(
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      clientId: clientId ?? this.clientId,
    );
  }
}

class GarminSessionStore {
  static const _sessionKey = 'garmin_oauth_session';

  final SecureKeyValueStore storage;

  const GarminSessionStore({required this.storage});

  factory GarminSessionStore.secure() {
    return const GarminSessionStore(storage: FlutterSecureKeyValueStore());
  }

  Future<void> save(GarminSession session) {
    return storage.write(_sessionKey, session.toJsonString());
  }

  Future<GarminSession?> load() async {
    final stored = await storage.read(_sessionKey);

    if (stored == null) {
      return null;
    }

    return GarminSession.fromJsonString(stored);
  }

  Future<void> clear() {
    return storage.delete(_sessionKey);
  }
}
