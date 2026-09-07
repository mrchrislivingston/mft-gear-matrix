import 'package:flutter_test/flutter_test.dart';
import 'package:mft_gear_matrix/data/default_matrix.dart';

void main() {
  test('default prescriptions do not fabricate target history', () {
    final prescriptions = buildDefaultPrescriptions();

    for (final prescription in prescriptions) {
      for (final target in prescription.targets) {
        expect(
          target.history,
          isEmpty,
          reason:
              '${prescription.id} ${target.modality.name} '
              'must not contain fabricated history',
        );
      }
    }
  });
}
