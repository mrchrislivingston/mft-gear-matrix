import 'dart:convert';

import 'package:http/http.dart' as http;

import 'garmin_session_store.dart';

class GarminMobileException implements Exception {
  final String message;

  const GarminMobileException(this.message);

  @override
  String toString() => message;
}

class GarminProfile {
  final String? displayName;
  final String? fullName;

  const GarminProfile({required this.displayName, required this.fullName});

  String get bestName {
    final full = fullName?.trim();
    if (full != null && full.isNotEmpty) {
      return full;
    }

    final display = displayName?.trim();
    if (display != null && display.isNotEmpty) {
      return display;
    }

    return 'Garmin athlete';
  }
}

typedef GarminSessionSaver = Future<void> Function(GarminSession session);

class GarminMobileClient {
  static const defaultApiBaseUrl = 'https://connectapi.garmin.com';

  static const defaultTokenUrl =
      'https://diauth.garmin.com/'
      'di-oauth2-service/oauth/token';

  final http.Client httpClient;
  final GarminSessionSaver? sessionSaver;
  final String apiBaseUrl;
  final String tokenUrl;

  GarminSession _session;

  factory GarminMobileClient({
    required GarminSession session,
    required http.Client httpClient,
    GarminSessionSaver? sessionSaver,
    String apiBaseUrl = defaultApiBaseUrl,
    String tokenUrl = defaultTokenUrl,
  }) {
    session.validate();

    return GarminMobileClient._(
      session: session,
      httpClient: httpClient,
      sessionSaver: sessionSaver,
      apiBaseUrl: apiBaseUrl,
      tokenUrl: tokenUrl,
    );
  }

  GarminMobileClient._({
    required this._session,
    required this.httpClient,
    required this.sessionSaver,
    required this.apiBaseUrl,
    required this.tokenUrl,
  });

  GarminSession get session => _session;

  Future<GarminProfile> testConnection() async {
    var response = await _getSocialProfile();

    if (response.statusCode == 401) {
      await _refreshSession();
      response = await _getSocialProfile();
    }

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw const GarminMobileException(
        'Garmin session was rejected. Import a fresh session.',
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw GarminMobileException(
        'Garmin returned HTTP ${response.statusCode}.',
      );
    }

    dynamic decoded;

    try {
      decoded = jsonDecode(response.body);
    } on FormatException {
      throw const GarminMobileException('Garmin returned invalid JSON.');
    }

    if (decoded is! Map) {
      throw const GarminMobileException(
        'Garmin returned an invalid profile response.',
      );
    }

    final profile = Map<String, dynamic>.from(decoded);

    return GarminProfile(
      displayName: profile['displayName']?.toString(),
      fullName: profile['fullName']?.toString(),
    );
  }

  Future<http.Response> _getSocialProfile() {
    return httpClient.get(
      Uri.parse('$apiBaseUrl/userprofile-service/socialProfile'),
      headers: _apiHeaders(_session.accessToken),
    );
  }

  Future<void> _refreshSession() async {
    final basicCredentials = base64Encode(utf8.encode('${_session.clientId}:'));

    final response = await httpClient.post(
      Uri.parse(tokenUrl),
      headers: {
        ..._nativeHeaders(),
        'Authorization': 'Basic $basicCredentials',
        'Accept': 'application/json',
        'Content-Type': 'application/x-www-form-urlencoded',
        'Cache-Control': 'no-cache',
      },
      body: {
        'grant_type': 'refresh_token',
        'client_id': _session.clientId,
        'refresh_token': _session.refreshToken,
      },
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw GarminMobileException(
        'Garmin session refresh failed with '
        'HTTP ${response.statusCode}.',
      );
    }

    dynamic decoded;

    try {
      decoded = jsonDecode(response.body);
    } on FormatException {
      throw const GarminMobileException(
        'Garmin session refresh returned invalid JSON.',
      );
    }

    if (decoded is! Map) {
      throw const GarminMobileException(
        'Garmin session refresh returned an invalid response.',
      );
    }

    final values = Map<String, dynamic>.from(decoded);
    final accessToken = values['access_token']?.toString();

    if (accessToken == null || accessToken.trim().isEmpty) {
      throw const GarminMobileException(
        'Garmin session refresh did not return an access token.',
      );
    }

    final refreshed = _session.copyWith(
      accessToken: accessToken,
      refreshToken:
          values['refresh_token']?.toString() ?? _session.refreshToken,
      clientId: _clientIdFromJwt(accessToken) ?? _session.clientId,
    );

    refreshed.validate();
    _session = refreshed;

    if (sessionSaver != null) {
      await sessionSaver!(refreshed);
    }
  }

  Map<String, String> _apiHeaders(String accessToken) {
    return {
      ..._nativeHeaders(),
      'Authorization': 'Bearer $accessToken',
      'Accept': 'application/json',
    };
  }

  Map<String, String> _nativeHeaders() {
    return const {
      'User-Agent': 'GCM-Android-5.23',
      'X-Garmin-User-Agent':
          'com.garmin.android.apps.connectmobile/5.23; ; '
          'Google/sdk_gphone64_arm64/google; Android/33; '
          'Dalvik/2.1.0',
      'X-Garmin-Paired-App-Version': '10861',
      'X-Garmin-Client-Platform': 'Android',
      'X-App-Ver': '10861',
      'X-Lang': 'en',
      'X-GCExperience': 'GC5',
      'Accept-Language': 'en-US,en;q=0.9',
    };
  }

  String? _clientIdFromJwt(String token) {
    final parts = token.split('.');
    if (parts.length < 2) {
      return null;
    }

    try {
      final normalized = base64Url.normalize(parts[1]);
      final decoded = jsonDecode(utf8.decode(base64Url.decode(normalized)));

      if (decoded is! Map) {
        return null;
      }

      final clientId = decoded['client_id']?.toString();
      if (clientId == null || clientId.trim().isEmpty) {
        return null;
      }

      return clientId;
    } on Object {
      return null;
    }
  }
}
