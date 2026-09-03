import 'dart:convert';
import 'dart:typed_data';

import 'package:csv/csv.dart';

class MisfitCsvDocument {
  final List<List<String>> rows;

  const MisfitCsvDocument({required this.rows});

  int get rowCount => rows.length;

  int get maximumColumnCount {
    if (rows.isEmpty) {
      return 0;
    }

    return rows.map((row) => row.length).reduce((largest, current) {
      return current > largest ? current : largest;
    });
  }
}

class MisfitCsvService {
  const MisfitCsvService();

  MisfitCsvDocument decodeBytes(Uint8List bytes) {
    final text = utf8.decode(bytes);
    final decodedRows = Csv(dynamicTyping: false).decode(text);

    final rows = decodedRows
        .map((row) {
          return row
              .map((value) {
                return value?.toString() ?? '';
              })
              .toList(growable: false);
        })
        .toList(growable: false);

    return MisfitCsvDocument(rows: rows);
  }
}
