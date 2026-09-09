import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../services/fitr_credentials_store.dart';
import '../services/fitr_mobile_client.dart';

typedef FitrWeekLoader =
    Future<FitrWeekSnapshot> Function(
      FitrCredentials credentials,
      DateTime monday,
    );

class FitrMobilePreviewScreen extends StatefulWidget {
  final FitrCredentialsStore? credentialsStore;
  final FitrWeekLoader? weekLoader;

  const FitrMobilePreviewScreen({
    super.key,
    this.credentialsStore,
    this.weekLoader,
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

  late final FitrCredentialsStore _credentialsStore;
  late final FitrWeekLoader _weekLoader;
  late DateTime _monday;

  FitrWeekSnapshot? _snapshot;
  String? _errorMessage;
  bool _isLoading = false;
  bool _showCredentials = false;
  bool _storedCredentialsLoaded = false;

  @override
  void initState() {
    super.initState();
    _credentialsStore =
        widget.credentialsStore ?? FitrCredentialsStore.secure();
    _weekLoader = widget.weekLoader ?? _fetchWeek;
    _monday = _nextMonday(DateTime.now());
    _loadStoredCredentials();
  }

  @override
  void dispose() {
    _tokenController.dispose();
    _cookieController.dispose();
    _athleteIdController.dispose();
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
      _errorMessage = null;
    });
  }

  void _changeWeek(int days) {
    setState(() {
      _monday = _monday.add(Duration(days: days));
      _snapshot = null;
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
    });

    try {
      final credentials = _credentialsFromFields();
      await _credentialsStore.save(credentials);
      final snapshot = await _weekLoader(credentials, _monday);

      if (!mounted) {
        return;
      }

      setState(() {
        _snapshot = snapshot;
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
      _errorMessage = null;
      _storedCredentialsLoaded = false;
    });
  }

  List<String> _sectionLabels(FitrWeekDay day) {
    final rawDay = day.detail['day'];

    if (rawDay is! Map) {
      return const [];
    }

    final rawSections = rawDay['sections'];

    if (rawSections is! List) {
      return const [];
    }

    final labels = <String>[];

    for (final rawSection in rawSections) {
      if (rawSection is! Map) {
        continue;
      }

      final challenge = rawSection['challenge'];
      final challengeTitle = challenge is Map
          ? challenge['title']?.toString()
          : null;

      final title =
          rawSection['title']?.toString() ??
          challengeTitle ??
          '(untitled section)';

      labels.add(title);
    }

    return labels;
  }

  String _formatDate(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');

    return '${value.year}-$month-$day';
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = _snapshot;
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
          if (snapshot != null) ...[
            const SizedBox(height: 20),
            Text(
              '${snapshot.days.length} programmed '
              'day${snapshot.days.length == 1 ? '' : 's'} found',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            for (final day in snapshot.days)
              Card(
                child: ListTile(
                  title: Text('${day.date} • ${day.planTitle}'),
                  subtitle: Text(
                    _sectionLabels(day).isEmpty
                        ? 'No sections'
                        : _sectionLabels(day).join('\n'),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
