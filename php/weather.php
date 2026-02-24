<?php
/**
 * World Weather Online — Weather Dashboard (PHP)
 * ================================================
 * Fetches and displays current weather + 5-day forecast.
 *
 * Requirements:
 *   PHP 7.4+ with cURL enabled (standard on most servers)
 *
 * Usage:
 *   php weather.php
 *   php weather.php --location="Paris"
 *   php weather.php --location="Tokyo" --days=3
 *
 * Set your API key:
 *   export WWO_API_KEY="your_key_here"
 *
 * Get a free key at:
 *   https://www.worldweatheronline.com/weather-api/
 */

// ─── CONFIG ───────────────────────────────────────────────────────────────────

$api_key  = getenv('WWO_API_KEY') ?: 'your_api_key_here';
$base_url = 'https://api.worldweatheronline.com/premium/v1/weather.ashx';

// Parse CLI arguments
$opts     = getopt('', ['location:', 'days:']);
$location = $opts['location'] ?? 'London';
$days     = (int) ($opts['days'] ?? 5);

// Weather condition → emoji
$icons = [
    'sunny'         => '☀️',
    'clear'         => '🌙',
    'partly cloudy' => '⛅',
    'cloudy'        => '☁️',
    'overcast'      => '☁️',
    'mist'          => '🌫️',
    'fog'           => '🌫️',
    'rain'          => '🌧️',
    'drizzle'       => '🌦️',
    'snow'          => '❄️',
    'sleet'         => '🌨️',
    'thunder'       => '⛈️',
    'blizzard'      => '🌨️',
];

function getIcon(string $description, array $icons): string {
    $desc = strtolower($description);
    foreach ($icons as $key => $icon) {
        if (str_contains($desc, $key)) return $icon;
    }
    return '🌡️';
}


// ─── API CALL ─────────────────────────────────────────────────────────────────

function fetchWeather(string $location, int $days, string $apiKey, string $baseUrl): ?array {
    if ($apiKey === 'your_api_key_here') {
        echo "❌  Please set your API key!\n";
        echo "    export WWO_API_KEY='your_key_here'\n";
        echo "    Get a free key: https://www.worldweatheronline.com/weather-api/\n";
        exit(1);
    }

    $params = http_build_query([
        'key'             => $apiKey,
        'q'               => $location,
        'format'          => 'json',
        'num_of_days'     => $days,
        'tp'              => 24,
        'includelocation' => 'yes',
        'cc'              => 'yes',
    ]);

    $ch = curl_init("{$baseUrl}?{$params}");
    curl_setopt_array($ch, [
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_TIMEOUT        => 10,
        CURLOPT_USERAGENT      => 'WWO-PHP-Client/1.0',
    ]);

    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    $error    = curl_error($ch);
    curl_close($ch);

    if ($error) {
        echo "❌  Connection error: {$error}\n";
        exit(1);
    }

    if ($httpCode !== 200) {
        echo "❌  HTTP Error: {$httpCode}\n";
        exit(1);
    }

    $data = json_decode($response, true)['data'] ?? null;

    if (!$data) {
        echo "❌  Invalid response from API.\n";
        exit(1);
    }

    if (isset($data['error'])) {
        echo "❌  API Error: {$data['error'][0]['msg']}\n";
        exit(1);
    }

    return $data;
}


// ─── DISPLAY ──────────────────────────────────────────────────────────────────

function displayCurrent(array $current, string $locationName, array $icons): void {
    $desc = $current['weatherDesc'][0]['value'];
    $icon = getIcon($desc, $icons);

    echo "\n" . str_repeat('─', 50) . "\n";
    echo "📍 {$locationName} — Right Now\n";
    echo str_repeat('─', 50) . "\n";
    echo "{$icon}  {$desc}\n";
    echo "🌡️  Temperature : {$current['temp_C']}°C / {$current['temp_F']}°F";
    echo " (Feels like {$current['FeelsLikeC']}°C)\n";
    echo "💧  Humidity    : {$current['humidity']}%\n";
    echo "💨  Wind        : {$current['windspeedMiles']} mph {$current['winddir16Point']}\n";
    echo "👁️  Visibility  : {$current['visibility']} km\n";
    echo "☀️  UV Index    : {$current['uvIndex']}\n";
    echo str_repeat('─', 50) . "\n";
}

function displayForecast(array $weatherDays, array $icons): void {
    echo "\n📅 Forecast\n\n";
    printf("%-14s %-25s %7s %7s %7s %7s\n", 'Date', 'Conditions', 'High', 'Low', 'Rain%', 'Wind');
    echo str_repeat('─', 70) . "\n";

    foreach ($weatherDays as $day) {
        $date       = new DateTime($day['date']);
        $dateFmt    = $date->format('D d M');
        $desc       = $day['hourly'][0]['weatherDesc'][0]['value'];
        $icon       = getIcon($desc, $icons);
        $rain       = $day['hourly'][0]['chanceofrain'] ?? 'N/A';
        $wind       = $day['hourly'][0]['windspeedMiles'];

        printf(
            "%-14s %-25s %7s %7s %7s %7s\n",
            $dateFmt,
            "{$icon} {$desc}",
            "{$day['maxtempC']}°C",
            "{$day['mintempC']}°C",
            "{$rain}%",
            "{$wind} mph"
        );
    }

    echo str_repeat('─', 70) . "\n";
}


// ─── MAIN ─────────────────────────────────────────────────────────────────────

echo "\n🌍 World Weather Online — fetching weather for {$location}...\n";

$data = fetchWeather($location, $days, $api_key, $base_url);

// Get readable location name
$locationName = $location;
try {
    $area    = $data['nearest_area'][0]['areaName'][0]['value'];
    $country = $data['nearest_area'][0]['country'][0]['value'];
    $locationName = "{$area}, {$country}";
} catch (Exception $e) {}

displayCurrent($data['current_condition'][0], $locationName, $icons);
displayForecast($data['weather'], $icons);

echo "\nData by World Weather Online — https://www.worldweatheronline.com\n\n";
