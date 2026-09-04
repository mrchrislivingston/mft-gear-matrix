import 'package:flutter_test/flutter_test.dart';
import 'package:mft_gear_matrix/services/misfit_date_resolver.dart';

void main() {
  const resolver = MisfitDateResolver();

  test('suggests the first year found in the filename', () {
    expect(
      resolver.suggestedStartYear('Remote Coaching - Phase II 2025_2026.csv'),
      2025,
    );
    expect(resolver.suggestedStartYear('OffSZN 2026.csv'), 2026);
    expect(resolver.suggestedStartYear('Phase Two.csv'), isNull);
  });

  test('supports ordinal written-date anchors', () {
    final resolution = resolver.resolve(
      headers: const ['Mon - W1D1 - Nov 3rd', 'Tues - W1D2'],
      startYear: 2025,
    );

    expect(resolution.programStartDate, '2025-11-03');
    expect(resolution.dateFor('W1D1')?.date, '2025-11-03');
    expect(resolution.dateFor('W1D1')?.status, MisfitDateStatus.exact);
    expect(resolution.dateFor('W1D2')?.date, '2025-11-04');
    expect(resolution.dateFor('W1D2')?.status, MisfitDateStatus.inferred);
  });

  test('can infer the start from a later numeric anchor', () {
    final resolution = resolver.resolve(
      headers: const ['Mon - W1D1', 'Mon - W3D1 - 11/17', 'Tues - W3D2'],
      startYear: 2025,
    );

    expect(resolution.programStartDate, '2025-11-03');
    expect(resolution.dateFor('W1D1')?.date, '2025-11-03');
    expect(resolution.dateFor('W3D1')?.date, '2025-11-17');
  });

  test('rolls from December into the next year', () {
    final resolution = resolver.resolve(
      headers: const [
        'Mon - Dec 29 - W9D1',
        'Wed - Dec 31 - W9D3',
        'Thurs - Jan 1 - W9D4',
        'Sat - Jan 3 - W9D6',
      ],
      startYear: 2025,
    );

    expect(resolution.programStartDate, '2025-11-03');
    expect(resolution.dateFor('W9D3')?.date, '2025-12-31');
    expect(resolution.dateFor('W9D4')?.date, '2026-01-01');
    expect(resolution.dateFor('W9D6')?.date, '2026-01-03');
  });

  test('returns unresolved dates when no anchor exists', () {
    final resolution = resolver.resolve(
      headers: const ['Mon - W1D1', 'Tues - W1D2'],
      startYear: 2025,
    );

    expect(resolution.programStartDate, isEmpty);
    expect(resolution.dateFor('W1D1')?.status, MisfitDateStatus.unresolved);
  });

  test('uses program calendar for a one-day spreadsheet typo', () {
    final resolution = resolver.resolve(
      headers: const [
        'Mon - Jan 5 - W1D1',
        'Mon - Jan 11 - W2D1',
        'Tues - Jan 12 - W2D2',
        'Sat - Jan 17 - W2D6',
      ],
      startYear: 2026,
    );

    expect(resolution.programStartDate, '2026-01-05');
    expect(resolution.dateFor('W2D1')?.date, '2026-01-12');
    expect(resolution.dateFor('W2D1')?.status, MisfitDateStatus.corrected);
    expect(resolution.dateFor('W2D2')?.date, '2026-01-13');
    expect(resolution.dateFor('W2D2')?.status, MisfitDateStatus.corrected);
    expect(resolution.dateFor('W2D6')?.date, '2026-01-17');
    expect(resolution.dateFor('W2D6')?.status, MisfitDateStatus.exact);
  });

  test('rejects a conflicting explicit date', () {
    expect(
      () => resolver.resolve(
        headers: const ['Mon - Nov 3 - W1D1', 'Tues - Nov 9 - W1D2'],
        startYear: 2025,
      ),
      throwsFormatException,
    );
  });

  test('uses calendar days across daylight-saving changes', () {
    final resolution = resolver.resolve(
      headers: const [
        'Mon - 4/6/2026 W8D1',
        'Mon - 3/2/2026 W3D1',
        'Mon - 2/16 W1D1',
      ],
      startYear: 2026,
    );

    expect(resolution.programStartDate, '2026-02-16');
    expect(resolution.dateFor('W1D1')?.date, '2026-02-16');
    expect(resolution.dateFor('W3D1')?.date, '2026-03-02');
    expect(resolution.dateFor('W8D1')?.date, '2026-04-06');
  });
}
