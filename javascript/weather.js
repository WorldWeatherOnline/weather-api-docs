/**
 * World Weather Online — Weather Fetcher (Node.js)
 * =================================================
 * Fetches and displays current weather + 5-day forecast in the terminal.
 *
 * Requirements:
 *   npm install axios chalk
 *
 * Usage:
 *   node weather.js
 *   node weather.js London
 *   node weather.js "New York" 3
 *
 * Set your API key:
 *   export WWO_API_KEY="your_key_here"
 *
 * Get a free key at:
 *   https://www.worldweatheronline.com/weather-api/
 */

const axios = require("axios");

// ─── CONFIG ────────────────────────────────────────────────────────────────────

const API_KEY = process.env.WWO_API_KEY || "your_api_key_here";
const BASE_URL = "https://api.worldweatheronline.com/premium/v1/weather.ashx";

// Try to load chalk for coloured output (optional)
let chalk;
try {
  chalk = require("chalk");
} catch {
  // If chalk isn't installed, use plain text
  chalk = {
    blue: (s) => s, bold: { blue: (s) => s, yellow: (s) => s, cyan: (s) => s },
    cyan: (s) => s, red: (s) => s, green: (s) => s, yellow: (s) => s, dim: (s) => s,
  };
}

// Weather condition → emoji
const ICONS = {
  sunny: "☀️", clear: "🌙", "partly cloudy": "⛅", cloudy: "☁️",
  overcast: "☁️", mist: "🌫️", fog: "🌫️", rain: "🌧️", drizzle: "🌦️",
  snow: "❄️", sleet: "🌨️", thunder: "⛈️", blizzard: "🌨️",
};

function getIcon(description) {
  const desc = description.toLowerCase();
  for (const [key, icon] of Object.entries(ICONS)) {
    if (desc.includes(key)) return icon;
  }
  return "🌡️";
}


// ─── API CALL ──────────────────────────────────────────────────────────────────

async function getWeather(location, days = 5) {
  if (API_KEY === "your_api_key_here") {
    console.error("❌  Please set your API key!");
    console.error("    export WWO_API_KEY='your_key_here'");
    console.error("    Get a free key: https://www.worldweatheronline.com/weather-api/");
    process.exit(1);
  }

  try {
    const response = await axios.get(BASE_URL, {
      params: {
        key: API_KEY,
        q: location,
        format: "json",
        num_of_days: days,
        tp: 24,
        includelocation: "yes",
        cc: "yes",
      },
      timeout: 10000,
    });

    const data = response.data.data;

    // Check for API-level errors
    if (data.error) {
      console.error(`❌  API Error: ${data.error[0].msg}`);
      process.exit(1);
    }

    return data;

  } catch (err) {
    if (err.code === "ENOTFOUND") {
      console.error("❌  No internet connection.");
    } else if (err.code === "ECONNABORTED") {
      console.error("❌  Request timed out.");
    } else if (err.response) {
      console.error(`❌  HTTP ${err.response.status}: ${err.response.statusText}`);
    } else {
      console.error(`❌  Error: ${err.message}`);
    }
    process.exit(1);
  }
}


// ─── DISPLAY ───────────────────────────────────────────────────────────────────

function displayCurrent(current, locationName) {
  const desc = current.weatherDesc[0].value;
  const icon = getIcon(desc);

  console.log("\n" + "─".repeat(50));
  console.log(chalk.bold.yellow(`📍 ${locationName} — Right Now`));
  console.log("─".repeat(50));
  console.log(`${icon}  ${desc}`);
  console.log(`🌡️  Temperature : ${chalk.cyan(current.temp_C + "°C")} / ${current.temp_F}°F  (Feels like ${current.FeelsLikeC}°C)`);
  console.log(`💧  Humidity    : ${current.humidity}%`);
  console.log(`💨  Wind        : ${current.windspeedMiles} mph ${current.winddir16Point}`);
  console.log(`👁️  Visibility  : ${current.visibility} km`);
  console.log(`☀️  UV Index    : ${current.uvIndex}`);
  console.log("─".repeat(50));
}

function displayForecast(weatherDays) {
  console.log(chalk.bold.blue("\n📅 Forecast\n"));

  const header = [
    "Date".padEnd(14),
    "Conditions".padEnd(25),
    "High".padStart(7),
    "Low".padStart(7),
    "Rain%".padStart(7),
    "Wind".padStart(7),
  ].join("  ");

  console.log(chalk.cyan(header));
  console.log("─".repeat(75));

  for (const day of weatherDays) {
    const dateObj = new Date(day.date);
    const dateFmt = dateObj.toLocaleDateString("en-GB", {
      weekday: "short", day: "2-digit", month: "short",
    });

    const desc = day.hourly[0].weatherDesc[0].value;
    const icon = getIcon(desc);
    const rainChance = day.hourly[0].chanceofrain || "N/A";
    const wind = day.hourly[0].windspeedMiles;

    const row = [
      dateFmt.padEnd(14),
      `${icon} ${desc}`.padEnd(25),
      chalk.red((day.maxtempC + "°C").padStart(7)),
      chalk.blue((day.mintempC + "°C").padStart(7)),
      (rainChance + "%").padStart(7),
      (wind + " mph").padStart(7),
    ].join("  ");

    console.log(row);
  }

  console.log("─".repeat(75));
}


// ─── MAIN ──────────────────────────────────────────────────────────────────────

async function main() {
  const location = process.argv[2] || "London";
  const days = parseInt(process.argv[3]) || 5;

  console.log(chalk.bold.blue(`\n🌍 World Weather Online`) + ` — fetching weather for ${chalk.bold(location)}...`);

  const data = await getWeather(location, days);

  // Get location name
  let locationName = location;
  try {
    const area = data.nearest_area[0].areaName[0].value;
    const country = data.nearest_area[0].country[0].value;
    locationName = `${area}, ${country}`;
  } catch {}

  displayCurrent(data.current_condition[0], locationName);
  displayForecast(data.weather);

  console.log(chalk.dim("\nData by World Weather Online — https://www.worldweatheronline.com\n"));
}

main();
