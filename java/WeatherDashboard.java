/**
 * World Weather Online — Weather Dashboard (Java)
 * =================================================
 * Fetches and displays current weather + 5-day forecast.
 *
 * Requirements:
 *   Java 11+  (uses java.net.http — no external dependencies)
 *   Optional: Add org.json to your classpath for cleaner JSON parsing
 *             https://mvnrepository.com/artifact/org.json/json
 *
 * Compile & Run:
 *   javac WeatherDashboard.java
 *   java WeatherDashboard
 *   java WeatherDashboard London 5
 *   java WeatherDashboard "New York" 3
 *
 * Set your API key:
 *   export WWO_API_KEY="your_key_here"
 *
 * Get a free key at:
 *   https://www.worldweatheronline.com/weather-api/
 */

import java.net.URI;
import java.net.URLEncoder;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.HashMap;
import java.util.Map;

public class WeatherDashboard {

    // ─── CONFIG ───────────────────────────────────────────────────────────────

    private static final String BASE_URL =
        "https://api.worldweatheronline.com/premium/v1/weather.ashx";

    private static final Map<String, String> ICONS = new HashMap<>();
    static {
        ICONS.put("sunny",         "☀️");
        ICONS.put("clear",         "🌙");
        ICONS.put("partly cloudy", "⛅");
        ICONS.put("cloudy",        "☁️");
        ICONS.put("overcast",      "☁️");
        ICONS.put("mist",          "🌫️");
        ICONS.put("fog",           "🌫️");
        ICONS.put("rain",          "🌧️");
        ICONS.put("drizzle",       "🌦️");
        ICONS.put("snow",          "❄️");
        ICONS.put("sleet",         "🌨️");
        ICONS.put("thunder",       "⛈️");
        ICONS.put("blizzard",      "🌨️");
    }

    private static String getIcon(String description) {
        String desc = description.toLowerCase();
        for (Map.Entry<String, String> entry : ICONS.entrySet()) {
            if (desc.contains(entry.getKey())) return entry.getValue();
        }
        return "🌡️";
    }


    // ─── SIMPLE JSON HELPER ───────────────────────────────────────────────────
    // Extracts a quoted string value from raw JSON without external libraries.

    private static String extractValue(String json, String key) {
        String search = "\"" + key + "\":";
        int idx = json.indexOf(search);
        if (idx == -1) return "N/A";
        int start = json.indexOf('"', idx + search.length()) + 1;
        int end   = json.indexOf('"', start);
        if (start <= 0 || end <= 0) {
            // Try unquoted number
            int numStart = idx + search.length();
            while (numStart < json.length() && !Character.isDigit(json.charAt(numStart))
                   && json.charAt(numStart) != '-') numStart++;
            int numEnd = numStart;
            while (numEnd < json.length() && (Character.isDigit(json.charAt(numEnd))
                   || json.charAt(numEnd) == '.')) numEnd++;
            return json.substring(numStart, numEnd);
        }
        return json.substring(start, end);
    }


    // ─── API CALL ─────────────────────────────────────────────────────────────

    private static String fetchWeather(String location, int days, String apiKey) throws Exception {
        if (apiKey.equals("your_api_key_here")) {
            System.err.println("❌  Please set your API key!");
            System.err.println("    export WWO_API_KEY='your_key_here'");
            System.err.println("    Get a free key: https://www.worldweatheronline.com/weather-api/");
            System.exit(1);
        }

        String encodedLocation = URLEncoder.encode(location, StandardCharsets.UTF_8);
        String url = String.format(
            "%s?key=%s&q=%s&format=json&num_of_days=%d&tp=24&includelocation=yes&cc=yes",
            BASE_URL, apiKey, encodedLocation, days
        );

        HttpClient client = HttpClient.newBuilder()
            .connectTimeout(Duration.ofSeconds(10))
            .build();

        HttpRequest request = HttpRequest.newBuilder()
            .uri(URI.create(url))
            .header("User-Agent", "WWO-Java-Client/1.0")
            .GET()
            .build();

        HttpResponse<String> response = client.send(request,
            HttpResponse.BodyHandlers.ofString());

        if (response.statusCode() != 200) {
            System.err.println("❌  HTTP Error: " + response.statusCode());
            System.exit(1);
        }

        return response.body();
    }


    // ─── DISPLAY ──────────────────────────────────────────────────────────────

    private static void displayCurrent(String json, String locationName) {
        // Extract the current_condition block
        int start = json.indexOf("\"current_condition\"");
        int end   = json.indexOf("]", start) + 1;
        String current = json.substring(start, end);

        String desc     = extractValue(current, "value");
        String tempC    = extractValue(current, "temp_C");
        String tempF    = extractValue(current, "temp_F");
        String feelsC   = extractValue(current, "FeelsLikeC");
        String humidity = extractValue(current, "humidity");
        String windMph  = extractValue(current, "windspeedMiles");
        String windDir  = extractValue(current, "winddir16Point");
        String uv       = extractValue(current, "uvIndex");
        String vis      = extractValue(current, "visibility");
        String icon     = getIcon(desc);

        System.out.println("\n" + "─".repeat(50));
        System.out.println("📍 " + locationName + " — Right Now");
        System.out.println("─".repeat(50));
        System.out.println(icon + "  " + desc);
        System.out.printf("🌡️  Temperature : %s°C / %s°F (Feels like %s°C)%n", tempC, tempF, feelsC);
        System.out.printf("💧  Humidity    : %s%%%n", humidity);
        System.out.printf("💨  Wind        : %s mph %s%n", windMph, windDir);
        System.out.printf("👁️  Visibility  : %s km%n", vis);
        System.out.printf("☀️  UV Index    : %s%n", uv);
        System.out.println("─".repeat(50));
    }

    private static void displayForecast(String json) {
        System.out.println("\n📅 Forecast\n");
        System.out.printf("%-14s %-25s %7s %7s %7s%n", "Date", "Conditions", "High", "Low", "Rain%");
        System.out.println("─".repeat(65));

        // Split by daily weather blocks
        String[] parts = json.split("\\{\"date\":");
        for (int i = 1; i < parts.length; i++) {
            String block = parts[i];

            String date     = extractValue("{\"date\":" + block, "date");
            String desc     = extractValue(block, "value");
            String maxTemp  = extractValue(block, "maxtempC");
            String minTemp  = extractValue(block, "mintempC");
            String rain     = extractValue(block, "chanceofrain");
            String icon     = getIcon(desc);

            // Format date
            try {
                LocalDate d       = LocalDate.parse(date.substring(0, 10));
                String dateFmt    = d.format(DateTimeFormatter.ofPattern("EEE dd MMM"));
                System.out.printf("%-14s %-25s %7s %7s %7s%n",
                    dateFmt,
                    icon + " " + desc,
                    maxTemp + "°C",
                    minTemp + "°C",
                    rain + "%"
                );
            } catch (Exception e) {
                System.out.println("Could not parse date: " + date);
            }
        }
        System.out.println("─".repeat(65));
    }


    // ─── MAIN ─────────────────────────────────────────────────────────────────

    public static void main(String[] args) throws Exception {
        String location = args.length > 0 ? args[0] : "London";
        int    days     = args.length > 1 ? Integer.parseInt(args[1]) : 5;
        String apiKey   = System.getenv("WWO_API_KEY") != null
                          ? System.getenv("WWO_API_KEY") : "your_api_key_here";

        System.out.println("\n🌍 World Weather Online — fetching weather for " + location + "...");

        String json = fetchWeather(location, days, apiKey);

        // Extract location name
        String locationName = location;
        try {
            String area    = extractValue(json, "areaName");
            String country = extractValue(json.substring(json.indexOf("\"country\"")), "value");
            locationName   = area + ", " + country;
        } catch (Exception ignored) {}

        displayCurrent(json, locationName);
        displayForecast(json);

        System.out.println("\nData by World Weather Online — https://www.worldweatheronline.com\n");
    }
}
