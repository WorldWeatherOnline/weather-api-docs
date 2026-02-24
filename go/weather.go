// World Weather Online — Weather Dashboard (Go)
// ===============================================
// Fetches and displays current weather + 5-day forecast.
//
// Requirements:
//   Go 1.18+  (uses only standard library — no external packages)
//
// Run:
//   go run weather.go
//   go run weather.go -location London
//   go run weather.go -location "New York" -days 3
//
// Build a binary:
//   go build -o weather weather.go
//   ./weather -location Tokyo
//
// Set your API key:
//   export WWO_API_KEY="your_key_here"
//
// Get a free key at:
//   https://www.worldweatheronline.com/weather-api/

package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"os"
	"strings"
	"time"
)

// ─── CONFIG ───────────────────────────────────────────────────────────────────

const baseURL = "https://api.worldweatheronline.com/premium/v1/weather.ashx"

var icons = map[string]string{
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
}

func getIcon(description string) string {
	desc := strings.ToLower(description)
	for key, icon := range icons {
		if strings.Contains(desc, key) {
			return icon
		}
	}
	return "🌡️"
}


// ─── API STRUCTS ──────────────────────────────────────────────────────────────

type WeatherResponse struct {
	Data struct {
		CurrentCondition []CurrentCondition `json:"current_condition"`
		Weather          []DayForecast      `json:"weather"`
		NearestArea      []NearestArea      `json:"nearest_area"`
		Error            []struct {
			Msg string `json:"msg"`
		} `json:"error"`
	} `json:"data"`
}

type CurrentCondition struct {
	TempC          string        `json:"temp_C"`
	TempF          string        `json:"temp_F"`
	FeelsLikeC     string        `json:"FeelsLikeC"`
	Humidity       string        `json:"humidity"`
	WindspeedMiles string        `json:"windspeedMiles"`
	Winddir16Point string        `json:"winddir16Point"`
	UvIndex        string        `json:"uvIndex"`
	Visibility     string        `json:"visibility"`
	WeatherDesc    []Description `json:"weatherDesc"`
}

type DayForecast struct {
	Date      string        `json:"date"`
	MaxTempC  string        `json:"maxtempC"`
	MinTempC  string        `json:"mintempC"`
	Hourly    []HourlyData  `json:"hourly"`
}

type HourlyData struct {
	WeatherDesc   []Description `json:"weatherDesc"`
	Chanceofrain  string        `json:"chanceofrain"`
	WindspeedMiles string       `json:"windspeedMiles"`
}

type NearestArea struct {
	AreaName []Description `json:"areaName"`
	Country  []Description `json:"country"`
}

type Description struct {
	Value string `json:"value"`
}


// ─── API CALL ─────────────────────────────────────────────────────────────────

func fetchWeather(location string, days int, apiKey string) (*WeatherResponse, error) {
	if apiKey == "your_api_key_here" {
		fmt.Fprintln(os.Stderr, "❌  Please set your API key!")
		fmt.Fprintln(os.Stderr, "    export WWO_API_KEY='your_key_here'")
		fmt.Fprintln(os.Stderr, "    Get a free key: https://www.worldweatheronline.com/weather-api/")
		os.Exit(1)
	}

	params := url.Values{}
	params.Set("key", apiKey)
	params.Set("q", location)
	params.Set("format", "json")
	params.Set("num_of_days", fmt.Sprintf("%d", days))
	params.Set("tp", "24")
	params.Set("includelocation", "yes")
	params.Set("cc", "yes")

	client := &http.Client{Timeout: 10 * time.Second}
	req, err := http.NewRequest("GET", baseURL+"?"+params.Encode(), nil)
	if err != nil {
		return nil, err
	}
	req.Header.Set("User-Agent", "WWO-Go-Client/1.0")

	resp, err := client.Do(req)
	if err != nil {
		return nil, fmt.Errorf("connection error: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != 200 {
		return nil, fmt.Errorf("HTTP error: %d", resp.StatusCode)
	}

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, err
	}

	var result WeatherResponse
	if err := json.Unmarshal(body, &result); err != nil {
		return nil, fmt.Errorf("JSON parse error: %w", err)
	}

	if len(result.Data.Error) > 0 {
		return nil, fmt.Errorf("API error: %s", result.Data.Error[0].Msg)
	}

	return &result, nil
}


// ─── DISPLAY ──────────────────────────────────────────────────────────────────

func displayCurrent(c CurrentCondition, locationName string) {
	desc := c.WeatherDesc[0].Value
	icon := getIcon(desc)

	fmt.Println("\n" + strings.Repeat("─", 50))
	fmt.Printf("📍 %s — Right Now\n", locationName)
	fmt.Println(strings.Repeat("─", 50))
	fmt.Printf("%s  %s\n", icon, desc)
	fmt.Printf("🌡️  Temperature : %s°C / %s°F (Feels like %s°C)\n", c.TempC, c.TempF, c.FeelsLikeC)
	fmt.Printf("💧  Humidity    : %s%%\n", c.Humidity)
	fmt.Printf("💨  Wind        : %s mph %s\n", c.WindspeedMiles, c.Winddir16Point)
	fmt.Printf("👁️  Visibility  : %s km\n", c.Visibility)
	fmt.Printf("☀️  UV Index    : %s\n", c.UvIndex)
	fmt.Println(strings.Repeat("─", 50))
}

func displayForecast(days []DayForecast) {
	fmt.Println("\n📅 Forecast\n")
	fmt.Printf("%-14s %-25s %7s %7s %7s\n", "Date", "Conditions", "High", "Low", "Rain%")
	fmt.Println(strings.Repeat("─", 65))

	for _, day := range days {
		t, err := time.Parse("2006-01-02", day.Date)
		if err != nil {
			continue
		}
		dateFmt := t.Format("Mon 02 Jan")
		desc    := day.Hourly[0].WeatherDesc[0].Value
		icon    := getIcon(desc)
		rain    := day.Hourly[0].Chanceofrain
		if rain == "" {
			rain = "N/A"
		}

		fmt.Printf("%-14s %-25s %7s %7s %7s\n",
			dateFmt,
			icon+" "+desc,
			day.MaxTempC+"°C",
			day.MinTempC+"°C",
			rain+"%",
		)
	}

	fmt.Println(strings.Repeat("─", 65))
}


// ─── MAIN ─────────────────────────────────────────────────────────────────────

func main() {
	location := flag.String("location", "London", "City name or coordinates")
	days      := flag.Int("days", 5, "Number of forecast days (1-7)")
	flag.Parse()

	apiKey := os.Getenv("WWO_API_KEY")
	if apiKey == "" {
		apiKey = "your_api_key_here"
	}

	fmt.Printf("\n🌍 World Weather Online — fetching weather for %s...\n", *location)

	data, err := fetchWeather(*location, *days, apiKey)
	if err != nil {
		fmt.Fprintf(os.Stderr, "❌  Error: %v\n", err)
		os.Exit(1)
	}

	// Get readable location name
	locationName := *location
	if len(data.Data.NearestArea) > 0 {
		area    := data.Data.NearestArea[0].AreaName[0].Value
		country := data.Data.NearestArea[0].Country[0].Value
		locationName = fmt.Sprintf("%s, %s", area, country)
	}

	displayCurrent(data.Data.CurrentCondition[0], locationName)
	displayForecast(data.Data.Weather)

	fmt.Println("\nData by World Weather Online — https://www.worldweatheronline.com\n")
}
