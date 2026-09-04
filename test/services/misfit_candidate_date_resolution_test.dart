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

  test('attaches corrected dates from the program calendar', () {
    const source = """
Mon - Jan 5 - W1D1,Zone 2 Row
Result,Rowed for 50 min.
Mon - Jan 11 - W2D1,Zone 2 Row
Result,Rowed for 50 min.
""";

    final document = csvService.decodeBytes(
      Uint8List.fromList(utf8.encode(source)),
    );

    final summary = reader.read(document, startYear: 2026);
    final weekTwo = summary.candidates.singleWhere(
      (candidate) => candidate.programDay == 'W2D1',
    );

    expect(weekTwo.date, '2026-01-12');
    expect(weekTwo.dateStatus, MisfitDateStatus.corrected);
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

  test('supports dates and program days in adjacent columns', () {
    const source = '''
Mon - 2/16,W1D1,Zone 2 Row
Notes / Results,,50:00 in Z2
Mon - 4/6/2026,W8D1,Zone 2 C2 Bike
Notes / Results,,45:00 in Z2
''';

    final document = csvService.decodeBytes(
      Uint8List.fromList(utf8.encode(source)),
    );

    final summary = reader.read(document, startYear: 2026);

    expect(summary.candidates, hasLength(2));

    final weekOne = summary.candidates.singleWhere(
      (candidate) => candidate.programDay == 'W1D1',
    );
    final weekEight = summary.candidates.singleWhere(
      (candidate) => candidate.programDay == 'W8D1',
    );

    expect(weekOne.date, '2026-02-16');
    expect(weekOne.dateStatus, MisfitDateStatus.exact);
    expect(weekOne.sourceColumn, 3);

    expect(weekEight.date, '2026-04-06');
    expect(weekEight.dateStatus, MisfitDateStatus.exact);
    expect(weekEight.sourceColumn, 3);
  });
}
