import unittest
from bridge import normalize_target_modality, parse_gear_targets, apply_targets_to_candidate
from classify_fitr_week import classify_gear, classify_power, classify_z2, detect_modality
from garmin_workout_builder import build_gear_workout, build_mixed_gear_workout


class AssaultRunnerTest(unittest.TestCase):
    def test_aliases_and_outdoor_separation(self):
        for name in ('AssaultRunner', 'Assault Runner', 'Ass Runner'):
            self.assertEqual(normalize_target_modality(name), 'assaultRunner')
            self.assertEqual(detect_modality(name + ' for meters @ G2'), 'AssaultRunner')
        self.assertEqual(normalize_target_modality('Run'), 'run')
        self.assertEqual(detect_modality('Run for meters\nEquipment Modification\nAssaultRunner'), 'Run')
        self.assertIsNone(detect_modality('Run and AssaultRunner'))

    def test_gear_target_resolves_separately(self):
        candidate = classify_gear({'title': 'G2', 'description': 'AMRAP 4:30 x 6\nAss Runner for meters @ G2\nRest :40'})
        candidate['workout_date'] = '2026-09-26'
        self.assertEqual(candidate['modality'], 'AssaultRunner')
        targets = parse_gear_targets(['G2:assaultRunner:minPerMile=8:05,8:20'])
        apply_targets_to_candidate(candidate, {'G2': {'metric': 'minPerMile', 'low': '8:45', 'high': '9:00'}}, targets)
        self.assertEqual(candidate['gear_target']['low'], '8:05')
        workout = build_gear_workout(candidate)
        self.assertEqual(workout['sportType']['sportTypeKey'], 'running')
        steps = workout['workoutSegments'][0]['workoutSteps']
        self.assertAlmostEqual(steps[0]['targetValueOne'], 1609.344 / 485)
        self.assertEqual(steps[1]['targetType']['workoutTargetTypeKey'], 'no.target')

    def test_no_outdoor_target_fallback(self):
        candidate = {'type': 'GEAR', 'prescription': 'G2', 'modality': 'AssaultRunner'}
        apply_targets_to_candidate(candidate, {'G2': {'low': '8:45', 'high': '9:00'}}, {})
        self.assertNotIn('gear_target', candidate)
        self.assertNotIn('pace_low', candidate)

    def test_mixed_gears_resolve_each_block(self):
        candidate = classify_gear({'title': 'G7/G8', 'description': """
AMRAP 2:30 x 3
AssaultRunner for Meters @ 7th Gear
Rest 3:15
Rest 3:30 after round 3, Then
AMRAP 2:00 x 2
AssaultRunner for Meters @ 8th Gear
Rest 3:30
"""})
        self.assertEqual(candidate['type'], 'MIXED_GEAR')
        candidate['workout_date'] = '2026-09-20'
        targets = parse_gear_targets(['G7:assaultRunner:minPerMile=6:05,6:20', 'G8:assaultRunner:minPerMile=5:45,6:00'])
        apply_targets_to_candidate(candidate, {}, targets)
        work = [s for s in candidate['steps'] if s['kind'] == 'work']
        self.assertEqual([s['gear_target']['low'] for s in work], ['6:05'] * 3 + ['5:45'] * 2)
        self.assertEqual(build_mixed_gear_workout(candidate)['sportType']['sportTypeKey'], 'running')

    def test_power_and_zone(self):
        power = classify_power({'title': 'P1', 'description': 'Every 3:00 x 5\nAssault Runner for meters in :20 @ P1'})
        self.assertEqual(power['modality'], 'AssaultRunner')
        zone = classify_z2({'title': 'Zone 2 - Ass Runner', 'description': '30:00 Ass Runner @ Zone 2'})
        self.assertEqual(zone['modality'], 'AssaultRunner')
        self.assertEqual(zone['work_seconds'], 1800)


if __name__ == '__main__':
    unittest.main()
