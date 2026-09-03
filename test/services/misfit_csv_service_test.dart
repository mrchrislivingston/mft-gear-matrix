import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mft_gear_matrix/services/misfit_csv_service.dart';

void main() {
  const service = MisfitCsvService();

  test('decodes a Misfit-style CSV with multiline cells', () {
    const source = '''
Date,Workout,Result
W1D1,"M.A.T.T. Row Test
AMRAP 40 Minutes","Avg Watts - 183
Avg Pace - 2:04"
''';

    final document = service.decodeBytes(
      Uint8List.fromList(utf8.encode(source)),
    );

    expect(document.rowCount, 2);
    expect(document.maximumColumnCount, 3);
    expect(document.rows[1][1], 'M.A.T.T. Row Test\nAMRAP 40 Minutes');
    expect(document.rows[1][2], 'Avg Watts - 183\nAvg Pace - 2:04');
  });

  test('handles a UTF-8 BOM and CRLF line endings', () {
    const source =
        '\uFEFFDate,Workout\r\n'
        'W1D1,Zone 2 Row\r\n';

    final document = service.decodeBytes(
      Uint8List.fromList(utf8.encode(source)),
    );

    expect(document.rowCount, 2);
    expect(document.rows.first.first, 'Date');
    expect(document.rows[1], ['W1D1', 'Zone 2 Row']);
  });

  test('preserves empty cells and uneven rows', () {
    const source = 'A,B,C\n1,,3\n4,5';

    final document = service.decodeBytes(
      Uint8List.fromList(utf8.encode(source)),
    );

    expect(document.rowCount, 3);
    expect(document.maximumColumnCount, 3);
    expect(document.rows[1], ['1', '', '3']);
    expect(document.rows[2], ['4', '5']);
  });

  test('returns an empty document for an empty file', () {
    final document = service.decodeBytes(Uint8List(0));

    expect(document.rows, isEmpty);
    expect(document.rowCount, 0);
    expect(document.maximumColumnCount, 0);
  });
}
