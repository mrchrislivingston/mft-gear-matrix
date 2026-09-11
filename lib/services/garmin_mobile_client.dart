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

class GarminScheduledWorkout {
  final int scheduleId;
  final int workoutId;
  final String title;
  final String date;
  final String? sportTypeKey;

  const GarminScheduledWorkout({
    required this.scheduleId,
    required this.workoutId,
    required this.title,
    required this.date,
    required this.sportTypeKey,
  });

  factory GarminScheduledWorkout.fromCalendarItem(Map<String, dynamic> item) {
    final scheduleId = _positiveInt(item['id']);
    final workoutId = _positiveInt(item['workoutId']);
    final title = item['title']?.toString().trim() ?? '';
    final date = item['date']?.toString().trim() ?? '';

    if (scheduleId == null ||
        workoutId == null ||
        title.isEmpty ||
        !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(date)) {
      throw const GarminMobileException(
        'Garmin returned an invalid scheduled workout.',
      );
    }

    return GarminScheduledWorkout(
      scheduleId: scheduleId,
      workoutId: workoutId,
      title: title,
      date: date,
      sportTypeKey: item['sportTypeKey']?.toString(),
    );
  }

  static int? _positiveInt(dynamic value) {
    final parsed = value is int ? value : int.tryParse(value?.toString() ?? '');

    if (parsed == null || parsed < 1) {
      return null;
    }

    return parsed;
  }
}

class GarminUploadedWorkout {
  final int workoutId;
  final String workoutName;

  const GarminUploadedWorkout({
    required this.workoutId,
    required this.workoutName,
  });
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

  Future<GarminUploadedWorkout> uploadWorkout(
    Map<String, dynamic> payload,
  ) async {
    final workoutName = payload['workoutName']?.toString().trim() ?? '';
    final segments = payload['workoutSegments'];

    if (workoutName.isEmpty || segments is! List || segments.isEmpty) {
      throw const GarminMobileException(
        'Garmin workout payload is incomplete.',
      );
    }

    var response = await _post('/workout-service/workout', payload);

    if (response.statusCode == 401) {
      await _refreshSession();
      response = await _post('/workout-service/workout', payload);
    }

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw const GarminMobileException(
        'Garmin session was rejected. Import a fresh session.',
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw GarminMobileException(
        'Garmin workout upload returned HTTP ${response.statusCode}.',
      );
    }

    final decoded = _decodeResponseObject(
      response,
      invalidMessage: 'Garmin workout upload returned invalid JSON.',
    );

    final workoutId = _positiveInt(decoded['workoutId']);

    if (workoutId == null) {
      throw const GarminMobileException(
        'Garmin workout upload did not return a workout ID.',
      );
    }

    final returnedName = decoded['workoutName']?.toString().trim() ?? '';

    return GarminUploadedWorkout(
      workoutId: workoutId,
      workoutName: returnedName.isEmpty ? workoutName : returnedName,
    );
  }

  Future<Map<String, dynamic>> scheduleWorkout({
    required int workoutId,
    required String date,
  }) async {
    if (workoutId < 1) {
      throw const GarminMobileException('Garmin workout ID must be positive.');
    }

    if (!_isValidDate(date)) {
      throw const GarminMobileException(
        'Garmin workout date must use YYYY-MM-DD.',
      );
    }

    final payload = {'date': date};
    final path = '/workout-service/schedule/$workoutId';

    var response = await _post(path, payload);

    if (response.statusCode == 401) {
      await _refreshSession();
      response = await _post(path, payload);
    }

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw const GarminMobileException(
        'Garmin session was rejected. Import a fresh session.',
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw GarminMobileException(
        'Garmin workout scheduling returned HTTP ${response.statusCode}.',
      );
    }

    return _decodeResponseObject(
      response,
      invalidMessage: 'Garmin workout scheduling returned invalid JSON.',
    );
  }

  Future<void> deleteWorkout(int workoutId) async {
    if (workoutId < 1) {
      throw const GarminMobileException('Garmin workout ID must be positive.');
    }

    final path = '/workout-service/workout/$workoutId';
    var response = await _delete(path);

    if (response.statusCode == 401) {
      await _refreshSession();
      response = await _delete(path);
    }

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw const GarminMobileException(
        'Garmin session was rejected. Import a fresh session.',
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw GarminMobileException(
        'Garmin workout cleanup returned HTTP ${response.statusCode}.',
      );
    }
  }

  Future<List<GarminScheduledWorkout>> getScheduledWorkoutsForMonth({
    required int year,
    required int month,
  }) async {
    if (year < 2000) {
      throw const GarminMobileException(
        'Garmin calendar year must be 2000 or later.',
      );
    }

    if (month < 1 || month > 12) {
      throw const GarminMobileException(
        'Garmin calendar month must be from 1 through 12.',
      );
    }

    final zeroIndexedMonth = month - 1;
    final path = '/calendar-service/year/$year/month/$zeroIndexedMonth';

    var response = await _get(path);

    if (response.statusCode == 401) {
      await _refreshSession();
      response = await _get(path);
    }

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw const GarminMobileException(
        'Garmin session was rejected. Import a fresh session.',
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw GarminMobileException(
        'Garmin calendar returned HTTP ${response.statusCode}.',
      );
    }

    dynamic decoded;

    try {
      decoded = jsonDecode(response.body);
    } on FormatException {
      throw const GarminMobileException(
        'Garmin calendar returned invalid JSON.',
      );
    }

    if (decoded is! Map) {
      throw const GarminMobileException(
        'Garmin calendar returned an invalid response.',
      );
    }

    final calendar = Map<String, dynamic>.from(decoded);
    final rawItems = calendar['calendarItems'];

    if (rawItems is! List) {
      throw const GarminMobileException(
        'Garmin calendar response is missing calendar items.',
      );
    }

    final workouts = <GarminScheduledWorkout>[];

    for (final rawItem in rawItems) {
      if (rawItem is! Map) {
        throw const GarminMobileException(
          'Garmin calendar contains an invalid item.',
        );
      }

      final item = Map<String, dynamic>.from(rawItem);

      if (item['itemType']?.toString() != 'workout') {
        continue;
      }

      workouts.add(GarminScheduledWorkout.fromCalendarItem(item));
    }

    return List.unmodifiable(workouts);
  }

  Future<http.Response> _post(String path, Map<String, dynamic> payload) {
    return httpClient.post(
      Uri.parse('$apiBaseUrl$path'),
      headers: {
        ..._apiHeaders(_session.accessToken),
        'Content-Type': 'application/json',
      },
      body: jsonEncode(payload),
    );
  }

  Map<String, dynamic> _decodeResponseObject(
    http.Response response, {
    required String invalidMessage,
  }) {
    dynamic decoded;

    try {
      decoded = jsonDecode(response.body);
    } on FormatException {
      throw GarminMobileException(invalidMessage);
    }

    if (decoded is! Map) {
      throw GarminMobileException(invalidMessage);
    }

    return Map<String, dynamic>.from(decoded);
  }

  int? _positiveInt(dynamic value) {
    final parsed = value is int ? value : int.tryParse(value?.toString() ?? '');

    if (parsed == null || parsed < 1) {
      return null;
    }

    return parsed;
  }

  bool _isValidDate(String value) {
    final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(value);

    if (match == null) {
      return false;
    }

    final year = int.parse(match.group(1)!);
    final month = int.parse(match.group(2)!);
    final day = int.parse(match.group(3)!);
    final parsed = DateTime.tryParse(value);

    return parsed != null &&
        parsed.year == year &&
        parsed.month == month &&
        parsed.day == day;
  }

  Future<http.Response> _delete(String path) {
    return httpClient.delete(
      Uri.parse('$apiBaseUrl$path'),
      headers: _apiHeaders(_session.accessToken),
    );
  }

  Future<http.Response> _get(String path) {
    return httpClient.get(
      Uri.parse('$apiBaseUrl$path'),
      headers: _apiHeaders(_session.accessToken),
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
