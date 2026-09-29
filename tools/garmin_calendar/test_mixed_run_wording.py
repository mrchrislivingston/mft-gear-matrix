import unittest
from classify_fitr_week import classify_gear
from garmin_workout_builder import build_mixed_gear_workout

WORKOUT = '''Build Run - 5th / 6th Gear
AMRAP 3:30 x 3
Run for Meters @ 5th Gear
Rest 2:30
Rest 3:00 after the third round, Then
AMRAP 3:00 x 2
Run for Meters @ 6th Gear
Rest 3:00
Stay walking as much as you can during rest periods.
'''

class MixedRunWordingTest(unittest.TestCase):
    def classify(self, text):
        return classify_gear({'title': 'Conditioning 3', 'description': text})

    def test_october_3_and_wording_variants(self):
        for phrase in ['the third round', 'round 3', 'the 3rd round']:
            with self.subTest(phrase=phrase):
                candidate = self.classify(WORKOUT.replace('the third round', phrase))
                self.assertEqual(candidate['type'], 'MIXED_GEAR')
                self.assertEqual(candidate['rounds'], 5)
                self.assertEqual([s['prescription'] for s in candidate['steps'] if s['kind'] == 'work'],
                                 ['G5', 'G5', 'G5', 'G6', 'G6'])
                self.assertEqual([s['seconds'] for s in candidate['steps']],
                                 [210,150,210,150,210,180,180,180,180])
                candidate['workout_date'] = '2026-10-03'
                workout = build_mixed_gear_workout(candidate)
                self.assertEqual(len(workout['workoutSegments'][0]['workoutSteps']), 9)

    def test_does_not_import_only_first_block(self):
        for text in [WORKOUT.replace('third', 'fourth'),
                     WORKOUT.replace('after the third round, Then', 'between blocks'),
                     WORKOUT + '\nAMRAP 1:00 x 1\nRun for Meters @ 7th Gear\nRest 1:00']:
            with self.subTest(text=text):
                self.assertEqual(self.classify(text)['status'], 'SKIP')

if __name__ == '__main__':
    unittest.main()
