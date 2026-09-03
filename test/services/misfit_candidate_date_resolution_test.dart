import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mft_gear_matrix/services/misfit_candidate_reader.dart';
import 'package:mft_gear_matrix/services/misfit_csv_service.dart';
import 'package:mft_gear_matrix/services/misfit_date_resolver.dart';

void main() {
  const csvService = MisfitCsvService();
  const reader = MisfitCandidateReader();

  test('attaches exact and inferred dates to candidates', () {
    const source = '''
Mon - W1D1 - Nov 3rd,Zone 2 Row
Result,Just rowed for 50 min.
Tues - W1D2,Zone 2 Run
Result,Ran for 45 min.
Wed - Dec 31 - W9D3,Zone 2 Row
Result,Rowed for 50 min.
Thurs - Jan 1 - W9D4,Zone 2 Row
Result,Rowed for 55 min.
''';

    final document = csvService.decodeBytes(
      Uint8List.fromList(utf8.encode(source)),
    );

    final summary = reader.read(document, startYear: 2025);

    expect(summary.candidates, hasLength(4));

    final candidates = {
      for (final candidate in summary.candidates)
        candidate.programDay: candidate,
    };

    expect(candidates['W1D1']?.date, '2025-11-03');
    expect(candidates['W1D1']?.dateStatus, MisfitDateStatus.exact);

    expect(candidates['W1D2']?.date, '2025-11-04');
    expect(candidates['W1D2']?.dateStatus, MisfitDateStatus.inferred);

    expect(candidates['W9D3']?.date, '2025-12-31');
    expect(candidates['W9D4']?.date, '2026-01-01');
  });

  test('leaves candidate dates unresolved without a start year', () {
    const source = '''
Mon - W1D1 - Nov 3rd,Zone 2 Row
Result,Just rowed for 50 min.
''';

    final document = csvService.decodeBytes(
      Uint8List.fromList(utf8.encode(source)),
    );

    final summary = reader.read(document);
    final candidate = summary.candidates.single;

    expect(candidate.date, isEmpty);
    expect(candidate.dateStatus, MisfitDateStatus.unresolved);
  });
}
