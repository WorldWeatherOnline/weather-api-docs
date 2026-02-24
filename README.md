# 🌤️ World Weather Online — Free Weather API

> Real-time forecasts · Historical data · Marine · Ski · Solar · Astronomy  
> Trusted by **400,000+ developers** worldwide

[![Free Tier](https://img.shields.io/badge/Free_Tier-500_calls%2Fday-blue)](https://www.worldweatheronline.com/weather-api/)
[![API Status](https://img.shields.io/badge/API-Live-brightgreen)](https://www.worldweatheronline.com/weather-api/)
[![Docs](https://img.shields.io/badge/Docs-worldweatheronline.com-informational)](https://www.worldweatheronline.com/weather-api/)

---

## ✨ What You Get

| Feature | Details |
|---|---|
| ⛅ Real-time Weather | Current conditions, feels-like temp, UV index |
| 📅 Forecasts | Hourly, daily, 15-min intervals — up to 365 days ahead |
| 📜 Historical Weather | Data going back to 1st July 2008 |
| 🌊 Marine & Tide Data | 7-day marine forecasts + tide times |
| ⛷️ Ski & Mountain | Snow depth, piste conditions, mountain weather |
| ☀️ Solar Data | GHI, DNI, cloud cover, sunshine hours |
| 💨 Air Quality | PM2.5, PM10, CO, NO2, O3 |
| 🔭 Astronomy | Sunrise/set, moonrise/set, moon phase |
| 🕐 Time Zone | UTC offset + DST for any location in the world |

---

## 🚀 Quick Start

### Step 1 — Get your free API key
Sign up at 👉 [worldweatheronline.com/weather-api](https://www.worldweatheronline.com/weather-api/)  
Free tier includes **100 calls/day** — no credit card required.

---

### Step 2 — Python Example

```python
import requests

API_KEY = "your_api_key_here"

url = "https://api.worldweatheronline.com/premium/v1/weather.ashx"

params = {
    "key": API_KEY,
    "q": "London",
    "format": "json",
    "num_of_days": 5,
    "tp": 1  # hourly intervals
}

response = requests.get(url, params=params)
data = response.json()

# Current temperature
print(data["data"]["current_condition"][0]["temp_C"], "°C")
```

---

### Step 3 — JavaScript / Node.js Example

```javascript
const axios = require("axios");

const getWeather = async (location) => {
  const { data } = await axios.get(
    "https://api.worldweatheronline.com/premium/v1/weather.ashx",
    {
      params: {
        key: process.env.WWO_API_KEY,
        q: location,
        format: "json",
        num_of_days: 3,
      },
    }
  );
  return data.data.current_condition[0];
};

getWeather("New York").then(console.log);
```

---

### Step 4 — PHP Example

```php
<?php
$api_key = "your_api_key_here";
$location = "Sydney";

$url = "https://api.worldweatheronline.com/premium/v1/weather.ashx"
     . "?key={$api_key}&q={$location}&format=json&num_of_days=3";

$response = file_get_contents($url);
$data = json_decode($response, true);

echo $data["data"]["current_condition"][0]["temp_C"] . "°C";
?>
```

---

## 📦 Sample JSON Response

```json
{
  "data": {
    "current_condition": [
      {
        "temp_C": "18",
        "temp_F": "64",
        "windspeedMiles": "12",
        "winddir16Point": "SW",
        "weatherDesc": [{ "value": "Partly Cloudy" }],
        "humidity": "72",
        "visibility": "10",
        "uvIndex": "3",
        "precipMM": "0.2"
      }
    ],
    "weather": [
      {
        "date": "2026-02-24",
        "maxtempC": "21",
        "mintempC": "13",
        "hourly": [ "...hourly forecast objects..." ]
      }
    ],
    "nearest_area": [
      {
        "areaName": [{ "value": "London" }],
        "country": [{ "value": "United Kingdom" }],
        "latitude": "51.517",
        "longitude": "-0.106"
      }
    ]
  }
}
```

---

## 🔌 All API Endpoints

| Endpoint | URL |
|---|---|
| Local Weather | `/premium/v1/weather.ashx?key=X&q=London&format=json` |
| Historical Weather | `/premium/v1/past-weather.ashx?key=X&q=Paris&dt=2024-01-01` |
| Marine & Tide | `/premium/v1/marine.ashx?key=X&q=51.5,-0.1&format=json` |
| Ski & Mountain | `/premium/v1/ski.ashx?key=X&q=Verbier&format=json` |
| Location Search | `/premium/v1/search.ashx?key=X&query=Lon&format=json` |
| Astronomy | `/premium/v1/astronomy.ashx?key=X&q=Tokyo&format=json` |
| Time Zone | `/premium/v1/tz.ashx?key=X&q=Sydney&format=json` |

Base URL for all endpoints: `https://api.worldweatheronline.com`

---

## 💰 Pricing Plans

| Plan | Calls/Day | Price |
|---|---|---|
| Free | 100 | $0 / month |
| Pro | Unlimited | From $1 / month |
| Enterprise | Unlimited | Contact us |

👉 [See full pricing](https://www.worldweatheronline.com/weather-api/api/pricing2.aspx)

---

## 📚 Full Documentation

- [Local Weather API](https://www.worldweatheronline.com/weather-api/api/local-city-town-weather-api.aspx)
- [Historical Weather API](https://www.worldweatheronline.com/weather-api/api/historical-weather-api.aspx)
- [Marine Weather API](https://www.worldweatheronline.com/weather-api/api/marine-weather-api.aspx)
- [Ski Weather API](https://www.worldweatheronline.com/weather-api/api/ski-weather-api.aspx)
- [Astronomy API](https://www.worldweatheronline.com/weather-api/api/astronomy-api.aspx)
- [Time Zone API](https://www.worldweatheronline.com/weather-api/api/time-zone-api.aspx)

---

## 🤝 Contributing

Pull requests are welcome! Feel free to add:
- Code examples in new languages (Ruby, Go, Java, C#, etc.)
- Bug fixes or improvements to existing examples
- New use case demos (marine, ski, solar, etc.)

---

## 📄 License

Code examples in this repo are MIT licensed.  
API usage is governed by the [World Weather Online Terms of Service](https://www.worldweatheronline.com/terms-and-conditions.aspx).

---

*Built with ❤️ by [World Weather Online](https://www.worldweatheronline.com)*
