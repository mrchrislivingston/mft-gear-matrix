import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../models/metric.dart';
import '../models/modality.dart';
import '../services/app_state.dart';
import '../services/garmin_workout_builder.dart';
import 'garmin_payload_preview_screen.dart';

import '../services/fitr_credentials_store.dart';
import '../services/fitr_mobile_client.dart';
import '../services/fitr_workout_classifier.dart';
import '../services/garmin_mobile_client.dart';
import '../services/garmin_session_store.dart';

typedef FitrWeekLoader =
    Future<FitrWeekSnapshot> Function(
      FitrCredentials credentials,
      DateTime monday,
    );

typedef GarminConnectionTester =
    Future<GarminProfile> Function(GarminSession session);

class FitrMobilePreviewScreen extends StatefulWidget {
  final FitrCredentialsStore? credentialsStore;
  final FitrWeekLoader? weekLoader;
  final GarminSessionStore? garminSessionStore;
  final GarminConnectionTester? garminConnectionTester;

  const FitrMobilePreviewScreen({
    super.key,
    this.credentialsStore,
    this.weekLoader,
    this.garminSessionStore,
    this.garminConnectionTester,
  });

  @override
  State<FitrMobilePreviewScreen> createState() {
    return _FitrMobilePreviewScreenState();
  }
}

class _FitrMobilePreviewScreenState extends State<FitrMobilePreviewScreen> {
  final _tokenController = TextEditingController();
  final _cookieController = TextEditingController();
  final _athleteIdController = TextEditingController();
  final _garminSessionController = TextEditingController();

  late final FitrCredentialsStore _credentialsStore;
  late final FitrWeekLoader _weekLoader;
  late final GarminSessionStore _garminSessionStore;
  late final GarminConnectionTester _garminConnectionTester;
  late DateTime _monday;

  FitrWeekSnapshot? _snapshot;
  FitrClassifiedWeek? _classifiedWeek;
  final Set<String> _selectedCandidateIds = {};
  String? _errorMessage;
  bool _isLoading = false;
  bool _showCredentials = false;
  bool _storedCredentialsLoaded = false;
  bool _garminSessionLoaded = false;
  bool _isTestingGarmin = false;
  String? _garminConnectionName;
  String? _garminErrorMessage;

  @override
  void initState() {
    super.initState();
    _credentialsStore =
        widget.credentialsStore ?? FitrCredentialsStore.secure();
    _weekLoader = widget.weekLoader ?? _fetchWeek;
    _garminSessionStore =
        widget.garminSessionStore ?? GarminSessionStore.secure();
    _garminConnectionTester =
        widget.garminConnectionTester ?? _testGarminConnection;
    _monday = _nextMonday(DateTime.now());
    _loadStoredCredentials();
    _loadStoredGarminSession();
  }

  @override
  void dispose() {
    _tokenController.dispose();
    _cookieController.dispose();
    _athleteIdController.dispose();
    _garminSessionController.dispose();
    super.dispose();
  }

  Future<FitrWeekSnapshot> _fetchWeek(
    FitrCredentials credentials,
    DateTime monday,
  ) async {
    final client = http.Client();

    try {
      return await FitrMobileClient(
        credentials: credentials,
        httpClient: client,
      ).fetchWeek(monday);
    } finally {
      client.close();
    }
  }

  Future<void> _loadStoredCredentials() async {
    try {
      final credentials = await _credentialsStore.load();

      if (!mounted) {
        return;
      }

      if (credentials != null) {
        _tokenController.text = credentials.token;
        _cookieController.text = credentials.cookie;
        _athleteIdController.text = credentials.athleteId.toString();
      }

      setState(() {
        _storedCredentialsLoaded = credentials != null;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = error.toString();
      });
    }
  }

  Future<GarminProfile> _testGarminConnection(GarminSession session) async {
    final client = http.Client();

    try {
      return await GarminMobileClient(
        session: session,
        httpClient: client,
        sessionSaver: _garminSessionStore.save,
      ).testConnection();
    } finally {
      client.close();
    }
  }

  Future<void> _loadStoredGarminSession() async {
    try {
      final session = await _garminSessionStore.load();

      if (!mounted) {
        return;
      }

      setState(() {
        _garminSessionLoaded = session != null;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _garminErrorMessage = error.toString();
      });
    }
  }

  Future<void> _importAndTestGarminSession() async {
    setState(() {
      _isTestingGarmin = true;
      _garminErrorMessage = null;
      _garminConnectionName = null;
    });

    try {
      final session = GarminSession.fromJsonString(
        _garminSessionController.text.trim(),
      );

      await _garminSessionStore.save(session);

      GarminProfile profile;
      try {
        profile = await _garminConnectionTester(session);
      } catch (_) {
        await _garminSessionStore.clear();
        rethrow;
      }

      if (!mounted) {
        return;
      }

      _garminSessionController.clear();

      setState(() {
        _garminSessionLoaded = true;
        _garminConnectionName = profile.bestName;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _garminSessionLoaded = false;
        _garminErrorMessage = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isTestingGarmin = false;
        });
      }
    }
  }

  Future<void> _testStoredGarminSession() async {
    setState(() {
      _isTestingGarmin = true;
      _garminErrorMessage = null;
      _garminConnectionName = null;
    });

    try {
      final session = await _garminSessionStore.load();

      if (session == null) {
        throw const GarminSessionException('No Garmin session is stored.');
      }

      final profile = await _garminConnectionTester(session);

      if (!mounted) {
        return;
      }

      setState(() {
        _garminSessionLoaded = true;
        _garminConnectionName = profile.bestName;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _garminErrorMessage = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isTestingGarmin = false;
        });
      }
    }
  }

  Future<void> _disconnectGarmin() async {
    await _garminSessionStore.clear();

    if (!mounted) {
      return;
    }

    _garminSessionController.clear();

    setState(() {
      _garminSessionLoaded = false;
      _garminConnectionName = null;
      _garminErrorMessage = null;
    });
  }

  DateTime _nextMonday(DateTime value) {
    final date = DateTime(value.year, value.month, value.day);
    var daysUntilMonday = (8 - date.weekday) % 7;

    if (daysUntilMonday == 0) {
      daysUntilMonday = 7;
    }

    return date.add(Duration(days: daysUntilMonday));
  }

  Future<void> _chooseWeek() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _monday,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      helpText: 'Choose any day in the FITR week',
    );

    if (selected == null || !mounted) {
      return;
    }

    final monday = selected.subtract(Duration(days: selected.weekday - 1));

    setState(() {
      _monday = DateTime(monday.year, monday.month, monday.day);
      _snapshot = null;
      _classifiedWeek = null;
      _selectedCandidateIds.clear();
      _errorMessage = null;
    });
  }

  void _changeWeek(int days) {
    setState(() {
      _monday = _monday.add(Duration(days: days));
      _snapshot = null;
      _classifiedWeek = null;
      _selectedCandidateIds.clear();
      _errorMessage = null;
    });
  }

  FitrCredentials _credentialsFromFields() {
    final athleteId = int.tryParse(_athleteIdController.text.trim());

    if (athleteId == null || athleteId < 1) {
      throw const FitrCredentialsException('Enter a valid FITR athlete ID.');
    }

    final credentials = FitrCredentials(
      token: _tokenController.text,
      cookie: _cookieController.text,
      athleteId: athleteId,
    );

    credentials.validate();
    return credentials;
  }

  Future<void> _saveAndPreview() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _snapshot = null;
      _classifiedWeek = null;
      _selectedCandidateIds.clear();
    });

    try {
      final credentials = _credentialsFromFields();
      await _credentialsStore.save(credentials);

      final snapshot = await _weekLoader(credentials, _monday);
      final classifiedWeek = classifyFitrWeekSnapshot(snapshot);

      if (!mounted) {
        return;
      }

      setState(() {
        _snapshot = snapshot;
        _classifiedWeek = classifiedWeek;
        _selectedCandidateIds
          ..clear()
          ..addAll(classifiedWeek.candidates.map((candidate) => candidate.id));
        _storedCredentialsLoaded = true;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _clearCredentials() async {
    await _credentialsStore.clear();

    if (!mounted) {
      return;
    }

    _tokenController.clear();
    _cookieController.clear();
    _athleteIdController.clear();

    setState(() {
      _snapshot = null;
      _classifiedWeek = null;
      _selectedCandidateIds.clear();
      _errorMessage = null;
      _storedCredentialsLoaded = false;
    });
  }

  Future<List<GarminScheduledWorkout>> _inspectGarminDates(
    Iterable<DateTime> dates,
  ) async {
    final session = await _garminSessionStore.load();

    if (session == null) {
      throw const GarminMobileException(
        'Connect Garmin before checking its calendar.',
      );
    }

    final months = <String, (int, int)>{};

    for (final date in dates) {
      final key = '${date.year}-${date.month}';
      months[key] = (date.year, date.month);
    }

    final client = http.Client();

    try {
      final garmin = GarminMobileClient(
        session: session,
        httpClient: client,
        sessionSaver: _garminSessionStore.save,
      );

      final workouts = <GarminScheduledWorkout>[];

      for (final month in months.values) {
        workouts.addAll(
          await garmin.getScheduledWorkoutsForMonth(
            year: month.$1,
            month: month.$2,
          ),
        );
      }

      return List.unmodifiable(workouts);
    } finally {
      client.close();
    }
  }

  GarminGearTarget? _currentGearTarget(
    String prescription,
    String modalityName,
  ) {
    final definition = switch (modalityName.toLowerCase()) {
      'run' => (Modality.run, Metric.minPerMile),
      'row' => (Modality.row, Metric.minPer500m),
      'ski' => (Modality.ski, Metric.minPer500m),
      'c2 bike' => (Modality.bikeErg, Metric.minPer1000m),
      'echo bike' => (Modality.echo, Metric.rpm),
      _ => null,
    };

    if (definition == null) {
      return null;
    }

    for (final gear in AppState.instance.gears) {
      if (gear.id != prescription) {
        continue;
      }

      final current = gear.currentTarget(
        modality: definition.$1,
        metric: definition.$2,
      );

      if (current == null) {
        return null;
      }

      return GarminGearTarget(
        metric: definition.$2.name,
        low: current.lowTarget,
        high: current.highTarget,
      );
    }

    return null;
  }

  void _openPayloadPreview(FitrClassifiedWeek classifiedWeek) {
    final selectedCandidates = classifiedWeek.candidates
        .where((candidate) => _selectedCandidateIds.contains(candidate.id))
        .toList(growable: false);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GarminPayloadPreviewScreen(
          candidates: selectedCandidates,
          gearTargetResolver: _currentGearTarget,
          calendarLoader: _inspectGarminDates,
        ),
      ),
    );
  }

  String _formatDate(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');

    return '${value.year}-$month-$day';
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = _snapshot;
    final classifiedWeek = _classifiedWeek;
    final sunday = _monday.add(const Duration(days: 6));

    return Scaffold(
      appBar: AppBar(title: const Text('FITR → Garmin Calendar')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: Theme.of(context).colorScheme.secondaryContainer,
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Private mobile spike: this reads FITR directly from '
                'the phone. Nothing will be created or scheduled on '
                'Garmin yet.',
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    key: const Key('fitrTokenField'),
                    controller: _tokenController,
                    enabled: !_isLoading,
                    obscureText: !_showCredentials,
                    autocorrect: false,
                    enableSuggestions: false,
                    decoration: const InputDecoration(
                      labelText: 'FITR bearer token',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    key: const Key('fitrCookieField'),
                    controller: _cookieController,
                    enabled: !_isLoading,
                    obscureText: !_showCredentials,
                    autocorrect: false,
                    enableSuggestions: false,
                    decoration: const InputDecoration(
                      labelText: 'FITR cookie',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    key: const Key('fitrAthleteIdField'),
                    controller: _athleteIdController,
                    enabled: !_isLoading,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'FITR athlete ID',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Show credentials'),
                    value: _showCredentials,
                    onChanged: _isLoading
                        ? null
                        : (value) {
                            setState(() {
                              _showCredentials = value;
                            });
                          },
                  ),
                  if (_storedCredentialsLoaded)
                    Row(
                      children: [
                        const Expanded(
                          child: Text('Credentials loaded from iOS Keychain.'),
                        ),
                        TextButton(
                          onPressed: _isLoading ? null : _clearCredentials,
                          child: const Text('Clear'),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Garmin connection',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'The Garmin OAuth session is stored in the iOS '
                    'Keychain. Your Garmin password is never stored.',
                  ),
                  const SizedBox(height: 12),
                  if (!_garminSessionLoaded) ...[
                    TextField(
                      key: const Key('garminSessionField'),
                      controller: _garminSessionController,
                      enabled: !_isTestingGarmin,
                      obscureText: true,
                      autocorrect: false,
                      enableSuggestions: false,
                      decoration: const InputDecoration(
                        labelText: 'Garmin session JSON',
                        hintText: 'Paste session from Mac',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      key: const Key('garminImportSessionButton'),
                      onPressed: _isTestingGarmin
                          ? null
                          : _importAndTestGarminSession,
                      icon: _isTestingGarmin
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.key),
                      label: Text(
                        _isTestingGarmin
                            ? 'Testing Garmin…'
                            : 'Import and test session',
                      ),
                    ),
                  ] else ...[
                    Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _garminConnectionName == null
                                ? 'Garmin session loaded'
                                : 'Connected as '
                                      '$_garminConnectionName',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        OutlinedButton.icon(
                          key: const Key('garminTestSessionButton'),
                          onPressed: _isTestingGarmin
                              ? null
                              : _testStoredGarminSession,
                          icon: _isTestingGarmin
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.verified_user_outlined),
                          label: const Text('Test connection'),
                        ),
                        TextButton(
                          key: const Key('garminDisconnectButton'),
                          onPressed: _isTestingGarmin
                              ? null
                              : _disconnectGarmin,
                          child: const Text('Disconnect'),
                        ),
                      ],
                    ),
                  ],
                  if (_garminErrorMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _garminErrorMessage!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Previous week',
                    onPressed: _isLoading ? null : () => _changeWeek(-7),
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: _isLoading ? null : _chooseWeek,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          children: [
                            const Text('FITR week'),
                            Text(
                              '${_formatDate(_monday)} – '
                              '${_formatDate(sunday)}',
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Next week',
                    onPressed: _isLoading ? null : () => _changeWeek(7),
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            key: const Key('fitrPreviewButton'),
            onPressed: _isLoading ? null : _saveAndPreview,
            icon: _isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.download_outlined),
            label: Text(
              _isLoading ? 'Loading FITR…' : 'Save credentials and preview',
            ),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            Card(
              color: Theme.of(context).colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(_errorMessage!),
              ),
            ),
          ],
          if (snapshot != null && classifiedWeek != null) ...[
            const SizedBox(height: 20),
            Text(
              '${classifiedWeek.candidates.length} importable '
              'workout${classifiedWeek.candidates.length == 1 ? '' : 's'}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text(
              '${snapshot.days.length} programmed '
              'day${snapshot.days.length == 1 ? '' : 's'} inspected'
              ' • ${classifiedWeek.skipped.length} skipped',
            ),
            const SizedBox(height: 8),
            if (classifiedWeek.candidates.isNotEmpty)
              Row(
                children: [
                  TextButton(
                    key: const Key('fitrSelectAllButton'),
                    onPressed: () {
                      setState(() {
                        _selectedCandidateIds
                          ..clear()
                          ..addAll(
                            classifiedWeek.candidates.map(
                              (candidate) => candidate.id,
                            ),
                          );
                      });
                    },
                    child: const Text('Select all'),
                  ),
                  TextButton(
                    key: const Key('fitrClearSelectionButton'),
                    onPressed: () {
                      setState(_selectedCandidateIds.clear);
                    },
                    child: const Text('Clear'),
                  ),
                  const Spacer(),
                  Text('${_selectedCandidateIds.length} selected'),
                ],
              ),
            for (final candidate in classifiedWeek.candidates)
              Card(
                child: CheckboxListTile(
                  key: Key('fitrCandidate-${candidate.id}'),
                  value: _selectedCandidateIds.contains(candidate.id),
                  controlAffinity: ListTileControlAffinity.leading,
                  title: Text('${candidate.date} • ${candidate.displayName}'),
                  subtitle: Text(
                    '${candidate.type} • ${candidate.planTitle}\n'
                    '${candidate.sourceTitle}',
                  ),
                  isThreeLine: true,
                  onChanged: (selected) {
                    setState(() {
                      if (selected ?? false) {
                        _selectedCandidateIds.add(candidate.id);
                      } else {
                        _selectedCandidateIds.remove(candidate.id);
                      }
                    });
                  },
                ),
              ),
            if (classifiedWeek.skipped.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text('Skipped', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              for (final skipped in classifiedWeek.skipped)
                Card(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: Text('${skipped.date} • ${skipped.sourceTitle}'),
                    subtitle: Text('${skipped.reason}\n${skipped.planTitle}'),
                    isThreeLine: true,
                  ),
                ),
            ],
            const SizedBox(height: 12),
            FilledButton.icon(
              key: const Key('fitrPreviewGarminPayloadsButton'),
              onPressed: _selectedCandidateIds.isEmpty
                  ? null
                  : () => _openPayloadPreview(classifiedWeek),
              icon: const Icon(Icons.preview_outlined),
              label: const Text('Preview Garmin payloads'),
            ),
            const SizedBox(height: 12),
            Card(
              color: Theme.of(context).colorScheme.secondaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  '${_selectedCandidateIds.length} workout'
                  '${_selectedCandidateIds.length == 1 ? '' : 's'} '
                  'selected. Garmin creation and scheduling will be '
                  'added in the next step.',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
