/**
 * World Weather Online — Weather Dashboard (Swift)
 * ==================================================
 * Fetches and displays current weather + 5-day forecast.
 *
 * Requirements:
 *   Swift 5.5+  (uses async/await and URLSession — no packages needed)
 *   Works on macOS, Linux (Swift for Linux), and as a Swift Package
 *
 * Run (macOS/Linux):
 *   swift weather.swift
 *   swift weather.swift London
 *   swift weather.swift "New York" 3
 *
 * Set your API key:
 *   export WWO_API_KEY="your_key_here"
 *
 * Get a free key at:
 *   https://www.worldweatheronline.com/weather-api/
 */

import Foundation

// ─── CONFIG ───────────────────────────────────────────────────────────────────

let apiKey  = ProcessInfo.processInfo.environment["WWO_API_KEY"] ?? "your_api_key_here"
let baseURL = "https://api.worldweatheronline.com/premium/v1/weather.ashx"

let icons: [String: String] = [
    "sunny":         "☀️",
    "clear":         "🌙",
    "partly cloudy": "⛅",
    "cloudy":        "☁️",
    "overcast":      "☁️",
    "mist":          "🌫️",
    "fog":           "🌫️",
    "rain":          "🌧️",
    "drizzle":       "🌦️",
    "snow":          "❄️",
    "sleet":         "🌨️",
    "thunder":       "⛈️",
    "blizzard":      "🌨️",
]

func getIcon(_ description: String) -> String {
    let desc = description.lowercased()
    for (key, icon) in icons {
        if desc.contains(key) { return icon }
    }
    return "🌡️"
}


// ─── API STRUCTS ──────────────────────────────────────────────────────────────

struct WeatherResponse: Codable {
    let data: WeatherData
}

struct WeatherData: Codable {
    let current_condition: [CurrentCondition]
    let weather: [DayForecast]
    let nearest_area: [NearestArea]?
    let error: [APIError]?
}

struct CurrentCondition: Codable {
    let temp_C: String
    let temp_F: String
    let FeelsLikeC: String
    let humidity: String
    let windspeedMiles: String
    let winddir16Point: String
    let uvIndex: String
    let visibility: String
    let weatherDesc: [Description]
}

struct DayForecast: Codable {
    let date: String
    let maxtempC: String
    let mintempC: String
    let hourly: [HourlyData]
}

struct HourlyData: Codable {
    let weatherDesc: [Description]
    let chanceofrain: String?
    let windspeedMiles: String
}

struct NearestArea: Codable {
    let areaName: [Description]
    let country: [Description]
}

struct Description: Codable {
    let value: String
}

struct APIError: Codable {
    let msg: String
}


// ─── API CALL ─────────────────────────────────────────────────────────────────

func fetchWeather(location: String, days: Int) async throws -> WeatherData {
    if apiKey == "your_api_key_here" {
        fputs("❌  Please set your API key!\n", stderr)
        fputs("    export WWO_API_KEY='your_key_here'\n", stderr)
        fputs("    Get a free key: https://www.worldweatheronline.com/weather-api/\n", stderr)
        exit(1)
    }

    var components = URLComponents(string: baseURL)!
    components.queryItems = [
        URLQueryItem(name: "key",             value: apiKey),
        URLQueryItem(name: "q",               value: location),
        URLQueryItem(name: "format",          value: "json"),
        URLQueryItem(name: "num_of_days",     value: "\(days)"),
        URLQueryItem(name: "tp",              value: "24"),
        URLQueryItem(name: "includelocation", value: "yes"),
        URLQueryItem(name: "cc",              value: "yes"),
    ]

    var request = URLRequest(url: components.url!, timeoutInterval: 10)
    request.setValue("WWO-Swift-Client/1.0", forHTTPHeaderField: "User-Agent")

    let (data, response) = try await URLSession.shared.data(for: request)

    guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
        throw URLError(.badServerResponse)
    }

    let result = try JSONDecoder().decode(WeatherResponse.self, from: data)

    if let errors = result.data.error, !errors.isEmpty {
        fputs("❌  API Error: \(errors[0].msg)\n", stderr)
        exit(1)
    }

    return result.data
}


// ─── DISPLAY ──────────────────────────────────────────────────────────────────

func displayCurrent(_ current: CurrentCondition, locationName: String) {
    let desc = current.weatherDesc[0].value
    let icon = getIcon(desc)

    print("\n" + String(repeating: "─", count: 50))
    print("📍 \(locationName) — Right Now")
    print(String(repeating: "─", count: 50))
    print("\(icon)  \(desc)")
    print("🌡️  Temperature : \(current.temp_C)°C / \(current.temp_F)°F (Feels like \(current.FeelsLikeC)°C)")
    print("💧  Humidity    : \(current.humidity)%")
    print("💨  Wind        : \(current.windspeedMiles) mph \(current.winddir16Point)")
    print("👁️  Visibility  : \(current.visibility) km")
    print("☀️  UV Index    : \(current.uvIndex)")
    print(String(repeating: "─", count: 50))
}

func displayForecast(_ weatherDays: [DayForecast]) {
    print("\n📅 Forecast\n")
    print(String(format: "%-14s %-25s %7s %7s %7s", "Date", "Conditions", "High", "Low", "Rain%"))
    print(String(repeating: "─", count: 65))

    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    let displayFormatter = DateFormatter()
    displayFormatter.dateFormat = "EEE dd MMM"

    for day in weatherDays {
        let date    = formatter.date(from: day.date) ?? Date()
        let dateFmt = displayFormatter.string(from: date)
        let desc    = day.hourly[0].weatherDesc[0].value
        let icon    = getIcon(desc)
        let rain    = day.hourly[0].chanceofrain ?? "N/A"

        print(String(format: "%-14s %-25s %7s %7s %7s",
            dateFmt,
            "\(icon) \(desc)",
            "\(day.maxtempC)°C",
            "\(day.mintempC)°C",
            "\(rain)%"
        ))
    }

    print(String(repeating: "─", count: 65))
}


// ─── MAIN ─────────────────────────────────────────────────────────────────────

let location = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "London"
let days     = CommandLine.arguments.count > 2 ? Int(CommandLine.arguments[2]) ?? 5 : 5

print("\n🌍 World Weather Online — fetching weather for \(location)...")

// Run async code from synchronous context
let semaphore = DispatchSemaphore(value: 0)

Task {
    do {
        let data = try await fetchWeather(location: location, days: days)

        var locationName = location
        if let area    = data.nearest_area?.first?.areaName.first?.value,
           let country = data.nearest_area?.first?.country.first?.value {
            locationName = "\(area), \(country)"
        }

        displayCurrent(data.current_condition[0], locationName: locationName)
        displayForecast(data.weather)

        print("\nData by World Weather Online — https://www.worldweatheronline.com\n")
    } catch {
        fputs("❌  Error: \(error.localizedDescription)\n", stderr)
        exit(1)
    }
    semaphore.signal()
}

semaphore.wait()
