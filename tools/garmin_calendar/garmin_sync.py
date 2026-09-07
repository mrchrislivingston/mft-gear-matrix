from garminconnect import Garmin


SESSION_PATH = "~/.garminconnect"


def get_garmin_client():
    client = Garmin()
    client.login(SESSION_PATH)
    return client


def get_existing_workout_names(client):
    workouts = client.get_workouts(0, 100)
    return {
        workout.get("workoutName")
        for workout in workouts
        if workout.get("workoutName")
    }


def workout_exists(client, workout_name):
    return workout_name in get_existing_workout_names(client)


def upload_if_missing(client, workout):
    workout_name = workout["workoutName"]
    workouts = client.get_workouts(0, 100)

    for existing in workouts:
        if existing.get("workoutName") == workout_name:
            print(f"Already exists: {workout_name}")
            return existing, False

    result = client.upload_workout(workout)
    print(f"Created: {workout_name}")
    return result, True


def workout_scheduled(client, workout_id, workout_date):
    result = client.get_scheduled_workouts(
        int(workout_date[:4]),
        int(workout_date[5:7]),
    )

    for item in result.get("calendarItems", []):
        if item.get("date") != workout_date:
            continue

        if item.get("workoutId") == workout_id:
            return True

    return False

def ensure_scheduled(client, workout_id, workout_date):
    if workout_scheduled(client, workout_id, workout_date):
        return False

    client.schedule_workout(workout_id, workout_date)
    return True
