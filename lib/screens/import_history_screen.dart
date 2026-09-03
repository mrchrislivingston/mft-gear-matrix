import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../services/misfit_candidate_reader.dart';
import 'import_candidate_review_screen.dart';
import '../services/misfit_csv_service.dart';

class ImportHistoryScreen extends StatefulWidget {
  const ImportHistoryScreen({super.key});

  @override
  State<ImportHistoryScreen> createState() {
    return _ImportHistoryScreenState();
  }
}

class _ImportHistoryScreenState extends State<ImportHistoryScreen> {
  static const MisfitCsvService _csvService = MisfitCsvService();
  static const MisfitCandidateReader _candidateReader = MisfitCandidateReader();

  bool _isLoading = false;
  String? _fileName;
  MisfitCsvDocument? _document;
  MisfitCandidateSummary? _candidateSummary;
  String? _errorMessage;

  Future<void> _selectCsv() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: const ['csv'],
      );

      if (file == null) {
        if (!mounted) {
          return;
        }

        setState(() {
          _isLoading = false;
        });
        return;
      }

      final bytes = await file.readAsBytes();
      final document = _csvService.decodeBytes(bytes);
      final candidateSummary = _candidateReader.read(document);

      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _fileName = file.name;
        _document = document;
        _candidateSummary = candidateSummary;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _fileName = null;
        _document = null;
        _candidateSummary = null;
        _errorMessage = 'Unable to read that CSV file: $error';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final document = _document;
    final candidateSummary = _candidateSummary;

    return Scaffold(
      appBar: AppBar(title: const Text('Import Misfit History')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Choose a CSV exported from a Misfit coaching spreadsheet.',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          const Text(
            'In Google Sheets, select the tab and choose File → '
            'Download → Comma-separated values (.csv, current sheet).',
          ),
          const SizedBox(height: 8),
          const Text(
            'The file is read locally. Nothing will be imported '
            'until you review and approve the parsed workouts.',
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _isLoading ? null : _selectCsv,
            icon: const Icon(Icons.upload_file),
            label: const Text('Choose CSV'),
          ),
          if (_isLoading) ...[
            const SizedBox(height: 24),
            const Center(child: CircularProgressIndicator()),
          ],
          if (_errorMessage case final errorMessage?) ...[
            const SizedBox(height: 24),
            Card(
              color: Theme.of(context).colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(errorMessage),
              ),
            ),
          ],
          if (document != null && candidateSummary != null) ...[
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _fileName ?? 'Selected CSV',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    Text('Rows: ${document.rowCount}'),
                    Text(
                      'Widest row: '
                      '${document.maximumColumnCount} columns',
                    ),
                    const Divider(height: 32),
                    Text(
                      'Matrix workout candidates',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    Text('Found: ${candidateSummary.total}'),
                    Text('Ready: ${candidateSummary.ready}'),
                    Text('Needs review: ${candidateSummary.review}'),
                    Text('Deferred: ${candidateSummary.deferred}'),
                    Text('Skipped: ${candidateSummary.skipped}'),
                    const SizedBox(height: 12),
                    const Text(
                      'Preview only — no workout data has been imported.',
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: candidateSummary.total == 0
                            ? null
                            : () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ImportCandidateReviewScreen(
                                      summary: candidateSummary,
                                    ),
                                  ),
                                );
                              },
                        icon: const Icon(Icons.fact_check_outlined),
                        label: const Text('Review parsed workouts'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
