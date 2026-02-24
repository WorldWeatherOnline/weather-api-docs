// World Weather Online — Weather Dashboard (Rust)
// =================================================
// Fetches and displays current weather + 5-day forecast.
//
// Requirements:
//   Rust 1.60+  Add these to your Cargo.toml:
//
//   [dependencies]
//   reqwest = { version = "0.11", features = ["blocking", "json"] }
//   serde = { version = "1", features = ["derive"] }
//   serde_json = "1"
//
// Run:
//   cargo run
//   cargo run -- --location London
//   cargo run -- --location "New York" --days 3
//
// Set your API key:
//   export WWO_API_KEY="your_key_here"
//
// Get a free key at:
//   https://www.worldweatheronline.com/weather-api/

use std::collections::HashMap;
use std::env;
use std::process;

use reqwest::blocking::Client;
use serde::Deserialize;

// ─── CONFIG ───────────────────────────────────────────────────────────────────

const BASE_URL: &str = "https://api.worldweatheronline.com/premium/v1/weather.ashx";

fn get_icon(description: &str) -> &'static str {
    let desc = description.to_lowercase();
    if desc.contains("sunny")         { return "☀️"; }
    if desc.contains("clear")         { return "🌙"; }
    if desc.contains("partly cloudy") { return "⛅"; }
    if desc.contains("cloudy")        { return "☁️"; }
    if desc.contains("overcast")      { return "☁️"; }
    if desc.contains("mist")          { return "🌫️"; }
    if desc.contains("fog")           { return "🌫️"; }
    if desc.contains("rain")          { return "🌧️"; }
    if desc.contains("drizzle")       { return "🌦️"; }
    if desc.contains("snow")          { return "❄️"; }
    if desc.contains("sleet")         { return "🌨️"; }
    if desc.contains("thunder")       { return "⛈️"; }
    if desc.contains("blizzard")      { return "🌨️"; }
    "🌡️"
}


// ─── API STRUCTS ──────────────────────────────────────────────────────────────

#[derive(Deserialize, Debug)]
struct WeatherResponse {
    data: WeatherData,
}

#[derive(Deserialize, Debug)]
struct WeatherData {
    current_condition: Vec<CurrentCondition>,
    weather: Vec<DayForecast>,
    nearest_area: Option<Vec<NearestArea>>,
}

#[derive(Deserialize, Debug)]
struct CurrentCondition {
    #[serde(rename = "temp_C")]   temp_c: String,
    #[serde(rename = "temp_F")]   temp_f: String,
    #[serde(rename = "FeelsLikeC")] feels_like_c: String,
    humidity: String,
    #[serde(rename = "windspeedMiles")] windspeed_miles: String,
    #[serde(rename = "winddir16Point")] winddir: String,
    #[serde(rename = "uvIndex")]  uv_index: String,
    visibility: String,
    #[serde(rename = "weatherDesc")] weather_desc: Vec<Description>,
}

#[derive(Deserialize, Debug)]
struct DayForecast {
    date: String,
    #[serde(rename = "maxtempC")] max_temp_c: String,
    #[serde(rename = "mintempC")] min_temp_c: String,
    hourly: Vec<HourlyData>,
}

#[derive(Deserialize, Debug)]
struct HourlyData {
    #[serde(rename = "weatherDesc")] weather_desc: Vec<Description>,
    chanceofrain: Option<String>,
}

#[derive(Deserialize, Debug)]
struct NearestArea {
    #[serde(rename = "areaName")] area_name: Vec<Description>,
    country: Vec<Description>,
}

#[derive(Deserialize, Debug)]
struct Description {
    value: String,
}


// ─── API CALL ─────────────────────────────────────────────────────────────────

fn fetch_weather(location: &str, days: u8, api_key: &str) -> Result<WeatherData, Box<dyn std::error::Error>> {
    if api_key == "your_api_key_here" {
        eprintln!("❌  Please set your API key!");
        eprintln!("    export WWO_API_KEY='your_key_here'");
        eprintln!("    Get a free key: https://www.worldweatheronline.com/weather-api/");
        process::exit(1);
    }

    let client = Client::builder()
        .timeout(std::time::Duration::from_secs(10))
        .user_agent("WWO-Rust-Client/1.0")
        .build()?;

    let response = client.get(BASE_URL)
        .query(&[
            ("key",             api_key),
            ("q",               location),
            ("format",          "json"),
            ("num_of_days",     &days.to_string()),
            ("tp",              "24"),
            ("includelocation", "yes"),
            ("cc",              "yes"),
        ])
        .send()?;

    if !response.status().is_success() {
        eprintln!("❌  HTTP Error: {}", response.status());
        process::exit(1);
    }

    let result: WeatherResponse = response.json()?;
    Ok(result.data)
}


// ─── DISPLAY ──────────────────────────────────────────────────────────────────

fn display_current(current: &CurrentCondition, location_name: &str) {
    let desc = &current.weather_desc[0].value;
    let icon = get_icon(desc);

    println!("\n{}", "─".repeat(50));
    println!("📍 {} — Right Now", location_name);
    println!("{}", "─".repeat(50));
    println!("{}  {}", icon, desc);
    println!("🌡️  Temperature : {}°C / {}°F (Feels like {}°C)", current.temp_c, current.temp_f, current.feels_like_c);
    println!("💧  Humidity    : {}%", current.humidity);
    println!("💨  Wind        : {} mph {}", current.windspeed_miles, current.winddir);
    println!("👁️  Visibility  : {} km", current.visibility);
    println!("☀️  UV Index    : {}", current.uv_index);
    println!("{}", "─".repeat(50));
}

fn display_forecast(weather_days: &[DayForecast]) {
    println!("\n📅 Forecast\n");
    println!("{:<14} {:<25} {:>7} {:>7} {:>7}", "Date", "Conditions", "High", "Low", "Rain%");
    println!("{}", "─".repeat(65));

    for day in weather_days {
        let desc = &day.hourly[0].weather_desc[0].value;
        let icon = get_icon(desc);
        let rain = day.hourly[0].chanceofrain.as_deref().unwrap_or("N/A");
        let cond = format!("{} {}", icon, desc);

        println!(
            "{:<14} {:<25} {:>7} {:>7} {:>7}",
            &day.date,
            cond,
            format!("{}°C", day.max_temp_c),
            format!("{}°C", day.min_temp_c),
            format!("{}%", rain),
        );
    }

    println!("{}", "─".repeat(65));
}


// ─── MAIN ─────────────────────────────────────────────────────────────────────

fn main() {
    let args: Vec<String> = env::args().collect();
    let location = args.get(1).map(String::as_str).unwrap_or("London");
    let days: u8 = args.get(2).and_then(|d| d.parse().ok()).unwrap_or(5);

    let api_key = env::var("WWO_API_KEY").unwrap_or_else(|_| "your_api_key_here".to_string());

    println!("\n🌍 World Weather Online — fetching weather for {}...", location);

    match fetch_weather(location, days, &api_key) {
        Ok(data) => {
            let location_name = data.nearest_area
                .as_ref()
                .and_then(|a| a.first())
                .map(|area| format!("{}, {}", area.area_name[0].value, area.country[0].value))
                .unwrap_or_else(|| location.to_string());

            display_current(&data.current_condition[0], &location_name);
            display_forecast(&data.weather);

            println!("\nData by World Weather Online — https://www.worldweatheronline.com\n");
        }
        Err(e) => {
            eprintln!("❌  Error: {}", e);
            process::exit(1);
        }
    }
}
