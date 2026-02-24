"""
World Weather Online — 5-Day Weather Dashboard
================================================
A simple terminal dashboard showing a 5-day weather forecast.

Requirements:
    pip install requests rich

Usage:
    python weather_dashboard.py
    python weather_dashboard.py --location "Paris"
    python weather_dashboard.py --location "New York" --days 3

Get your free API key at:
    https://www.worldweatheronline.com/weather-api/
"""

import requests
import argparse
import os
from datetime import datetime

# ─── Try to import 'rich' for pretty output, fall back to plain text ──────────
try:
    from rich.console import Console
    from rich.table import Table
    from rich.panel import Panel
    from rich import box
    RICH = True
    console = Console()
except ImportError:
    RICH = False
    print("Tip: Install 'rich' for a prettier dashboard: pip install rich\n")


# ─── CONFIG ───────────────────────────────────────────────────────────────────

API_KEY = os.environ.get("WWO_API_KEY", "your_api_key_here")
BASE_URL = "https://api.worldweatheronline.com/premium/v1/weather.ashx"

# Weather condition code → emoji
WEATHER_ICONS = {
    "sunny": "☀️",
    "clear": "🌙",
    "partly cloudy": "⛅",
    "cloudy": "☁️",
    "overcast": "☁️",
    "mist": "🌫️",
    "fog": "🌫️",
    "rain": "🌧️",
    "drizzle": "🌦️",
    "snow": "❄️",
    "sleet": "🌨️",
    "thunder": "⛈️",
    "blizzard": "🌨️",
}

def get_icon(description):
    desc = description.lower()
    for key, icon in WEATHER_ICONS.items():
        if key in desc:
            return icon
    return "🌡️"


# ─── API CALL ─────────────────────────────────────────────────────────────────

def get_weather(location, days=5):
    """Fetch weather data from World Weather Online API."""

    if API_KEY == "your_api_key_here":
        print("❌  Please set your API key!")
        print("    Option 1: Set environment variable: export WWO_API_KEY='your_key'")
        print("    Option 2: Replace 'your_api_key_here' in this script")
        print("    Get a free key at: https://www.worldweatheronline.com/weather-api/")
        return None

    params = {
        "key": API_KEY,
        "q": location,
        "format": "json",
        "num_of_days": days,
        "tp": 24,           # 24-hour intervals (daily summary)
        "includelocation": "yes",
        "cc": "yes",        # include current conditions
    }

    try:
        response = requests.get(BASE_URL, params=params, timeout=10)
        response.raise_for_status()
        data = response.json()

        # Check for API-level errors
        if "error" in data.get("data", {}):
            error_msg = data["data"]["error"][0]["msg"]
            print(f"❌  API Error: {error_msg}")
            return None

        return data["data"]

    except requests.exceptions.ConnectionError:
        print("❌  No internet connection. Please check your network.")
    except requests.exceptions.Timeout:
        print("❌  Request timed out. Please try again.")
    except requests.exceptions.HTTPError as e:
        print(f"❌  HTTP Error: {e}")
    except Exception as e:
        print(f"❌  Unexpected error: {e}")

    return None


# ─── DISPLAY ──────────────────────────────────────────────────────────────────

def display_current(current, location_name):
    """Display current weather conditions."""
    temp_c = current["temp_C"]
    temp_f = current["temp_F"]
    feels_c = current["FeelsLikeC"]
    description = current["weatherDesc"][0]["value"]
    humidity = current["humidity"]
    wind_mph = current["windspeedMiles"]
    wind_dir = current["winddir16Point"]
    uv = current["uvIndex"]
    visibility = current["visibility"]
    icon = get_icon(description)

    if RICH:
        content = (
            f"[bold]{icon}  {description}[/bold]\n\n"
            f"🌡️  Temperature:   [bold cyan]{temp_c}°C[/bold cyan] / {temp_f}°F   "
            f"(Feels like {feels_c}°C)\n"
            f"💧  Humidity:      {humidity}%\n"
            f"💨  Wind:          {wind_mph} mph {wind_dir}\n"
            f"👁️  Visibility:    {visibility} km\n"
            f"☀️  UV Index:      {uv}"
        )
        console.print(Panel(content, title=f"[bold yellow]📍 {location_name} — Right Now[/bold yellow]", border_style="blue"))
    else:
        print(f"\n📍 {location_name} — Current Conditions")
        print(f"{'─' * 40}")
        print(f"{icon}  {description}")
        print(f"Temperature : {temp_c}°C / {temp_f}°F (Feels like {feels_c}°C)")
        print(f"Humidity    : {humidity}%")
        print(f"Wind        : {wind_mph} mph {wind_dir}")
        print(f"Visibility  : {visibility} km")
        print(f"UV Index    : {uv}")


def display_forecast(weather_days):
    """Display multi-day forecast as a table."""

    if RICH:
        table = Table(title="📅 5-Day Forecast", box=box.ROUNDED, border_style="blue", header_style="bold cyan")
        table.add_column("Date", style="bold")
        table.add_column("Conditions", min_width=20)
        table.add_column("High", justify="center")
        table.add_column("Low", justify="center")
        table.add_column("Rain %", justify="center")
        table.add_column("Wind (mph)", justify="center")
        table.add_column("Humidity", justify="center")

        for day in weather_days:
            date_str = day["date"]
            date_obj = datetime.strptime(date_str, "%Y-%m-%d")
            date_fmt = date_obj.strftime("%a %d %b")   # e.g. Mon 24 Feb

            desc = day["hourly"][0]["weatherDesc"][0]["value"]
            icon = get_icon(desc)
            max_c = day["maxtempC"]
            min_c = day["mintempC"]
            rain_chance = day["hourly"][0].get("chanceofrain", "N/A")
            wind = day["hourly"][0]["windspeedMiles"]
            humidity = day["hourly"][0]["humidity"]

            table.add_row(
                date_fmt,
                f"{icon}  {desc}",
                f"[red]{max_c}°C[/red]",
                f"[blue]{min_c}°C[/blue]",
                f"{rain_chance}%",
                wind,
                f"{humidity}%",
            )

        console.print(table)

    else:
        print(f"\n📅 Forecast")
        print(f"{'─' * 80}")
        print(f"{'Date':<14} {'Conditions':<25} {'High':>6} {'Low':>6} {'Rain%':>6} {'Wind':>6} {'Humid':>6}")
        print(f"{'─' * 80}")

        for day in weather_days:
            date_str = day["date"]
            date_obj = datetime.strptime(date_str, "%Y-%m-%d")
            date_fmt = date_obj.strftime("%a %d %b")
            desc = day["hourly"][0]["weatherDesc"][0]["value"]
            icon = get_icon(desc)
            max_c = day["maxtempC"]
            min_c = day["mintempC"]
            rain = day["hourly"][0].get("chanceofrain", "N/A")
            wind = day["hourly"][0]["windspeedMiles"]
            humidity = day["hourly"][0]["humidity"]

            print(f"{date_fmt:<14} {icon} {desc:<23} {max_c+'°C':>6} {min_c+'°C':>6} {rain+'%':>6} {wind:>6} {humidity+'%':>6}")


# ─── MAIN ─────────────────────────────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(description="World Weather Online — Terminal Dashboard")
    parser.add_argument("--location", "-l", default="London", help="City name or coordinates (default: London)")
    parser.add_argument("--days", "-d", type=int, default=5, choices=range(1, 8), help="Number of forecast days (1-7)")
    args = parser.parse_args()

    if RICH:
        console.print(f"\n[bold blue]🌍 World Weather Online[/bold blue] — fetching weather for [bold]{args.location}[/bold]...\n")
    else:
        print(f"\n🌍 Fetching weather for {args.location}...")

    data = get_weather(args.location, args.days)
    if not data:
        return

    # Get location name from API response
    try:
        area = data["nearest_area"][0]["areaName"][0]["value"]
        country = data["nearest_area"][0]["country"][0]["value"]
        location_name = f"{area}, {country}"
    except (KeyError, IndexError):
        location_name = args.location

    # Display results
    display_current(data["current_condition"][0], location_name)
    print()
    display_forecast(data["weather"])

    if RICH:
        console.print(f"\n[dim]Data provided by World Weather Online — https://www.worldweatheronline.com[/dim]\n")
    else:
        print(f"\nData by World Weather Online — https://www.worldweatheronline.com\n")


if __name__ == "__main__":
    main()
