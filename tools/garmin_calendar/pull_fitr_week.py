import requests
import sys
from datetime import date, timedelta
from pathlib import Path

BASE_URL = "https://app.fitr.training/api"
CREDENTIALS_FILE = Path(__file__).with_name("fitr_credentials.txt")


def load_credentials():
    credentials = {}
    with CREDENTIALS_FILE.open("r") as file:
        for raw_line in file:
            line = raw_line.rstrip("\n")
            if not line or line.startswith("#"):
                continue
            key, value = line.split("=", 1)
            credentials[key.strip()] = value.strip()

    if "TOKEN" not in credentials:
        raise RuntimeError(
            "TOKEN is missing from fitr_credentials.txt"
        )
    if "COOKIE" not in credentials:
        raise RuntimeError(
            "COOKIE is missing from fitr_credentials.txt"
        )
    if "ATHLETE_ID" not in credentials:
        raise RuntimeError(
            "ATHLETE_ID is missing from fitr_credentials.txt"
        )

    try:
        athlete_id = int(credentials["ATHLETE_ID"])
    except ValueError as error:
        raise RuntimeError(
            "ATHLETE_ID in fitr_credentials.txt must be an integer"
        ) from error

    return credentials["TOKEN"], credentials["COOKIE"], athlete_id


def next_week():
    today = date.today()
    days_until_monday = (7 - today.weekday()) % 7

    if days_until_monday == 0:
        days_until_monday = 7

    monday = today + timedelta(days=days_until_monday)
    sunday = monday + timedelta(days=6)

    return monday, sunday


def fitr_get(url, token, cookie):
    headers = {
        "accept": "application/json, text/plain, */*",
        "accept-language": "en-US,en;q=0.9",
        "api-version": "3",
        "authorization": f"bearer {token}",
        "client-timezone": "America/Denver",
        "cookie": cookie,
        "referer": "https://app.fitr.training/user/calendar",
        "sec-fetch-dest": "empty",
        "sec-fetch-mode": "cors",
        "sec-fetch-site": "same-origin",
        "user-agent": (
            "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) "
            "AppleWebKit/537.36 (KHTML, like Gecko) "
            "Chrome/152.0.0.0 Safari/537.36"
        ),
    }

    response = requests.get(url, headers=headers, timeout=30)

    if not response.ok:
        print()
        print(f"FITR returned HTTP {response.status_code}")
        print(response.text[:1000])
        response.raise_for_status()

    return response.json()


def main():
    token, cookie, athlete_id = load_credentials()

    if len(sys.argv) > 1:
        monday = date.fromisoformat(sys.argv[1])
        sunday = monday + timedelta(days=6)
    else:
        monday, sunday = next_week()

    print()
    print(f"FITR week: {monday} -> {sunday}")
    print("=" * 70)

    calendar_url = (
        f"{BASE_URL}/schedule"
        f"?from={monday.isoformat()}"
        f"&to={sunday.isoformat()}"
    )

    calendar = fitr_get(calendar_url, token, cookie)

    plans = calendar.get("plans", [])

    if not plans:
        print("No FITR programming is published for this week.")
        return

    for plan in plans:
        print()
        print(f"PLAN: {plan.get('title', 'Unknown')}")

        for day in plan.get("days", []):
            workout_date = day["date"]
            schedule_id = day["schedule_id"]

            detail_url = (
                f"{BASE_URL}/schedule/"
                f"{schedule_id}/athlete/{athlete_id}"
            )

            detail = fitr_get(detail_url, token, cookie)

            print()
            print("-" * 70)
            print(
                f"{workout_date}  "
                f"Week {day.get('week')} Day {day.get('number')}  "
                f"[schedule_id={schedule_id}]"
            )
            print("-" * 70)

            sections = detail.get("day", {}).get("sections", [])

            for section in sections:
                title = (
                    section.get("title")
                    or (section.get("challenge") or {}).get("title")
                    or "(untitled)"
                )

                description = (
                    section.get("description")
                    or (section.get("challenge") or {}).get("description")
                    or ""
                )

                kind = section.get("kind", "unknown")

                print()
                print(f"[{kind.upper()}] {title}")

                if description:
                    print(description.strip())


if __name__ == "__main__":
    main()
