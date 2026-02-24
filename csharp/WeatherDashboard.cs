/**
 * World Weather Online — Weather Dashboard (C#)
 * ===============================================
 * Fetches and displays current weather + 5-day forecast.
 *
 * Requirements:
 *   .NET 6+ (uses System.Net.Http and System.Text.Json — no NuGet packages needed)
 *
 * Run:
 *   dotnet run
 *   dotnet run -- London
 *   dotnet run -- "New York" 3
 *
 * Or compile directly:
 *   dotnet build
 *   ./bin/Debug/net6.0/WeatherDashboard
 *
 * Set your API key:
 *   export WWO_API_KEY="your_key_here"   (Linux/macOS)
 *   set WWO_API_KEY=your_key_here        (Windows)
 *
 * Get a free key at:
 *   https://www.worldweatheronline.com/weather-api/
 */

using System;
using System.Collections.Generic;
using System.Net.Http;
using System.Text.Json;
using System.Threading.Tasks;
using System.Web;

class WeatherDashboard
{
    // ─── CONFIG ───────────────────────────────────────────────────────────────

    private const string BaseUrl = "https://api.worldweatheronline.com/premium/v1/weather.ashx";

    private static readonly Dictionary<string, string> Icons = new()
    {
        ["sunny"]         = "☀️",
        ["clear"]         = "🌙",
        ["partly cloudy"] = "⛅",
        ["cloudy"]        = "☁️",
        ["overcast"]      = "☁️",
        ["mist"]          = "🌫️",
        ["fog"]           = "🌫️",
        ["rain"]          = "🌧️",
        ["drizzle"]       = "🌦️",
        ["snow"]          = "❄️",
        ["sleet"]         = "🌨️",
        ["thunder"]       = "⛈️",
        ["blizzard"]      = "🌨️",
    };

    private static string GetIcon(string description)
    {
        string desc = description.ToLower();
        foreach (var (key, icon) in Icons)
            if (desc.Contains(key)) return icon;
        return "🌡️";
    }


    // ─── API CALL ─────────────────────────────────────────────────────────────

    private static async Task<JsonElement> FetchWeather(string location, int days, string apiKey)
    {
        if (apiKey == "your_api_key_here")
        {
            Console.Error.WriteLine("❌  Please set your API key!");
            Console.Error.WriteLine("    export WWO_API_KEY='your_key_here'");
            Console.Error.WriteLine("    Get a free key: https://www.worldweatheronline.com/weather-api/");
            Environment.Exit(1);
        }

        var query = HttpUtility.ParseQueryString(string.Empty);
        query["key"]             = apiKey;
        query["q"]               = location;
        query["format"]          = "json";
        query["num_of_days"]     = days.ToString();
        query["tp"]              = "24";
        query["includelocation"] = "yes";
        query["cc"]              = "yes";

        string url = $"{BaseUrl}?{query}";

        using var client = new HttpClient { Timeout = TimeSpan.FromSeconds(10) };
        client.DefaultRequestHeaders.Add("User-Agent", "WWO-CSharp-Client/1.0");

        HttpResponseMessage response;
        try
        {
            response = await client.GetAsync(url);
        }
        catch (HttpRequestException e)
        {
            Console.Error.WriteLine($"❌  Connection error: {e.Message}");
            Environment.Exit(1);
            throw;
        }

        if (!response.IsSuccessStatusCode)
        {
            Console.Error.WriteLine($"❌  HTTP Error: {(int)response.StatusCode}");
            Environment.Exit(1);
        }

        string json = await response.Content.ReadAsStringAsync();
        var root = JsonDocument.Parse(json).RootElement;

        if (root.TryGetProperty("data", out var data))
        {
            if (data.TryGetProperty("error", out var error))
            {
                Console.Error.WriteLine($"❌  API Error: {error[0].GetProperty("msg").GetString()}");
                Environment.Exit(1);
            }
            return data;
        }

        Console.Error.WriteLine("❌  Unexpected API response.");
        Environment.Exit(1);
        throw new Exception("Unreachable");
    }


    // ─── DISPLAY ──────────────────────────────────────────────────────────────

    private static void DisplayCurrent(JsonElement current, string locationName)
    {
        string desc    = current.GetProperty("weatherDesc")[0].GetProperty("value").GetString()!;
        string icon    = GetIcon(desc);
        string tempC   = current.GetProperty("temp_C").GetString()!;
        string tempF   = current.GetProperty("temp_F").GetString()!;
        string feelsC  = current.GetProperty("FeelsLikeC").GetString()!;
        string humid   = current.GetProperty("humidity").GetString()!;
        string windMph = current.GetProperty("windspeedMiles").GetString()!;
        string windDir = current.GetProperty("winddir16Point").GetString()!;
        string uv      = current.GetProperty("uvIndex").GetString()!;
        string vis     = current.GetProperty("visibility").GetString()!;

        Console.WriteLine("\n" + new string('─', 50));
        Console.WriteLine($"📍 {locationName} — Right Now");
        Console.WriteLine(new string('─', 50));
        Console.WriteLine($"{icon}  {desc}");
        Console.WriteLine($"🌡️  Temperature : {tempC}°C / {tempF}°F (Feels like {feelsC}°C)");
        Console.WriteLine($"💧  Humidity    : {humid}%");
        Console.WriteLine($"💨  Wind        : {windMph} mph {windDir}");
        Console.WriteLine($"👁️  Visibility  : {vis} km");
        Console.WriteLine($"☀️  UV Index    : {uv}");
        Console.WriteLine(new string('─', 50));
    }

    private static void DisplayForecast(JsonElement weatherDays)
    {
        Console.WriteLine("\n📅 Forecast\n");
        Console.WriteLine($"{"Date",-14} {"Conditions",-25} {"High",7} {"Low",7} {"Rain%",7}");
        Console.WriteLine(new string('─', 65));

        foreach (var day in weatherDays.EnumerateArray())
        {
            string dateStr  = day.GetProperty("date").GetString()!;
            string maxTemp  = day.GetProperty("maxtempC").GetString()!;
            string minTemp  = day.GetProperty("mintempC").GetString()!;
            var    hourly   = day.GetProperty("hourly")[0];
            string desc     = hourly.GetProperty("weatherDesc")[0].GetProperty("value").GetString()!;
            string rain     = hourly.TryGetProperty("chanceofrain", out var r) ? r.GetString()! : "N/A";
            string icon     = GetIcon(desc);

            string dateFmt  = DateTime.Parse(dateStr).ToString("ddd dd MMM");

            Console.WriteLine($"{dateFmt,-14} {icon + " " + desc,-25} {maxTemp + "°C",7} {minTemp + "°C",7} {rain + "%",7}");
        }

        Console.WriteLine(new string('─', 65));
    }


    // ─── MAIN ─────────────────────────────────────────────────────────────────

    static async Task Main(string[] args)
    {
        string location = args.Length > 0 ? args[0] : "London";
        int    days     = args.Length > 1 ? int.Parse(args[1]) : 5;
        string apiKey   = Environment.GetEnvironmentVariable("WWO_API_KEY") ?? "your_api_key_here";

        Console.WriteLine($"\n🌍 World Weather Online — fetching weather for {location}...");

        var data = await FetchWeather(location, days, apiKey);

        // Get readable location name
        string locationName = location;
        try
        {
            string area    = data.GetProperty("nearest_area")[0].GetProperty("areaName")[0]
                                 .GetProperty("value").GetString()!;
            string country = data.GetProperty("nearest_area")[0].GetProperty("country")[0]
                                 .GetProperty("value").GetString()!;
            locationName   = $"{area}, {country}";
        }
        catch { }

        DisplayCurrent(data.GetProperty("current_condition")[0], locationName);
        DisplayForecast(data.GetProperty("weather"));

        Console.WriteLine("\nData by World Weather Online — https://www.worldweatheronline.com\n");
    }
}
