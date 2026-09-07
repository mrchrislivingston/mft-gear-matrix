import unittest
from unittest.mock import patch

import bridge


class CommitCandidatesTest(unittest.TestCase):
    def setUp(self):
        self.preview = {
            "from": "2026-09-07",
            "to": "2026-09-13",
            "candidates": [
                {
                    "id": "one",
                    "date": "2026-09-08",
                    "workoutName": "P1 Row - 2026-09-08",
                    "garminWorkout": {
                        "workoutName": "P1 Row - 2026-09-08",
                    },
                },
                {
                    "id": "two",
                    "date": "2026-09-09",
                    "workoutName": "G3 Run - 2026-09-09",
                    "garminWorkout": {
                        "workoutName": "G3 Run - 2026-09-09",
                    },
                },
            ],
        }

    def test_rejects_empty_selection(self):
        with self.assertRaisesRegex(
            ValueError,
            "at least one explicit",
        ):
            bridge.commit_candidates(self.preview, [])

    def test_rejects_unknown_candidate(self):
        with self.assertRaisesRegex(
            ValueError,
            "Unknown candidate IDs",
        ):
            bridge.commit_candidates(
                self.preview,
                ["missing"],
            )

    @patch.object(
        bridge,
        "ensure_scheduled",
        return_value=True,
    )
    @patch.object(
        bridge,
        "upload_if_missing",
        return_value=({"workoutId": 123}, True),
    )
    @patch.object(
        bridge,
        "get_garmin_client",
        return_value=object(),
    )
    def test_commits_only_explicit_selection(
        self,
        get_client,
        upload,
        schedule,
    ):
        result = bridge.commit_candidates(
            self.preview,
            ["two"],
        )

        self.assertEqual(result["requested"], 1)
        self.assertEqual(len(result["results"]), 1)
        self.assertEqual(result["results"][0]["id"], "two")
        self.assertEqual(result["summary"]["created"], 1)
        self.assertEqual(result["summary"]["scheduled"], 1)

        get_client.assert_called_once()
        upload.assert_called_once_with(
            get_client.return_value,
            self.preview["candidates"][1]["garminWorkout"],
        )
        schedule.assert_called_once_with(
            get_client.return_value,
            123,
            "2026-09-09",
        )


if __name__ == "__main__":
    unittest.main()
