# World Weather Online — Weather Dashboard (R)
# ==============================================
# Fetches and displays current weather + 5-day forecast.
# Also demonstrates how to load weather data into a data frame for analysis.
#
# Requirements:
#   install.packages(c("httr", "jsonlite"))
#
# Usage (from terminal):
#   Rscript weather.R
#   Rscript weather.R London
#   Rscript weather.R "New York" 5
#
# Or source in R/RStudio:
#   source("weather.R")
#
# Set your API key:
#   Sys.setenv(WWO_API_KEY = "your_key_here")
#   Or set as environment variable before running
#
# Get a free key at:
#   https://www.worldweatheronline.com/weather-api/

library(httr)
library(jsonlite)

# ─── CONFIG ───────────────────────────────────────────────────────────────────

API_KEY  <- Sys.getenv("WWO_API_KEY", unset = "your_api_key_here")
BASE_URL <- "https://api.worldweatheronline.com/premium/v1/weather.ashx"

# Parse command line arguments
args     <- commandArgs(trailingOnly = TRUE)
location <- if (length(args) >= 1) args[1] else "London"
days     <- if (length(args) >= 2) as.integer(args[2]) else 5

# Weather condition → emoji
ICONS <- list(
  "sunny"         = "\u2600\ufe0f",
  "clear"         = "\U0001f319",
  "partly cloudy" = "\u26c5",
  "cloudy"        = "\u2601\ufe0f",
  "overcast"      = "\u2601\ufe0f",
  "mist"          = "\U0001f32b\ufe0f",
  "fog"           = "\U0001f32b\ufe0f",
  "rain"          = "\U0001f327\ufe0f",
  "drizzle"       = "\U0001f326\ufe0f",
  "snow"          = "\u2744\ufe0f",
  "sleet"         = "\U0001f328\ufe0f",
  "thunder"       = "\u26c8\ufe0f",
  "blizzard"      = "\U0001f328\ufe0f"
)

get_icon <- function(description) {
  desc <- tolower(description)
  for (key in names(ICONS)) {
    if (grepl(key, desc, fixed = TRUE)) return(ICONS[[key]])
  }
  return("\U0001f321\ufe0f")
}


# ─── API CALL ─────────────────────────────────────────────────────────────────

fetch_weather <- function(location, days, api_key) {
  if (api_key == "your_api_key_here") {
    cat("Error: Please set your API key!\n")
    cat("  Sys.setenv(WWO_API_KEY = 'your_key_here')\n")
    cat("  Get a free key: https://www.worldweatheronline.com/weather-api/\n")
    quit(status = 1)
  }

  response <- GET(
    BASE_URL,
    query = list(
      key             = api_key,
      q               = location,
      format          = "json",
      num_of_days     = days,
      tp              = 24,
      includelocation = "yes",
      cc              = "yes"
    ),
    timeout(10),
    add_headers(`User-Agent` = "WWO-R-Client/1.0")
  )

  if (http_error(response)) {
    cat(sprintf("HTTP Error: %d\n", status_code(response)))
    quit(status = 1)
  }

  data <- fromJSON(content(response, "text", encoding = "UTF-8"), flatten = TRUE)$data

  if (!is.null(data$error)) {
    cat(sprintf("API Error: %s\n", data$error$msg[1]))
    quit(status = 1)
  }

  return(data)
}


# ─── DISPLAY ──────────────────────────────────────────────────────────────────

display_current <- function(current, location_name) {
  desc <- current$weatherDesc[[1]]$value[1]
  icon <- get_icon(desc)

  cat("\n", strrep("\u2500", 50), "\n", sep = "")
  cat(sprintf("📍 %s — Right Now\n", location_name))
  cat(strrep("\u2500", 50), "\n", sep = "")
  cat(sprintf("%s  %s\n", icon, desc))
  cat(sprintf("🌡️  Temperature : %s°C / %s°F (Feels like %s°C)\n",
              current$temp_C, current$temp_F, current$FeelsLikeC))
  cat(sprintf("💧  Humidity    : %s%%\n", current$humidity))
  cat(sprintf("💨  Wind        : %s mph %s\n", current$windspeedMiles, current$winddir16Point))
  cat(sprintf("👁️  Visibility  : %s km\n", current$visibility))
  cat(sprintf("☀️  UV Index    : %s\n", current$uvIndex))
  cat(strrep("\u2500", 50), "\n", sep = "")
}

display_forecast <- function(weather_days) {
  cat("\n📅 Forecast\n\n")
  cat(sprintf("%-14s %-25s %7s %7s %7s\n", "Date", "Conditions", "High", "Low", "Rain%"))
  cat(strrep("\u2500", 65), "\n", sep = "")

  for (i in seq_len(nrow(weather_days))) {
    day     <- weather_days[i, ]
    date    <- as.Date(day$date)
    fmt     <- format(date, "%a %d %b")
    desc    <- day$hourly[[1]]$weatherDesc[[1]]$value[1]
    icon    <- get_icon(desc)
    rain    <- if (!is.null(day$hourly[[1]]$chanceofrain))
                 day$hourly[[1]]$chanceofrain[1] else "N/A"

    cat(sprintf("%-14s %-24s %7s %7s %7s\n",
      fmt,
      paste0(icon, " ", desc),
      paste0(day$maxtempC, "°C"),
      paste0(day$mintempC, "°C"),
      paste0(rain, "%")
    ))
  }

  cat(strrep("\u2500", 65), "\n", sep = "")
}


# ─── DATA FRAME (bonus for R users / data analysts) ──────────────────────────

weather_to_dataframe <- function(weather_days) {
  # Returns a clean data frame — useful for analysis, plotting, export to CSV
  df <- data.frame(
    date     = as.Date(weather_days$date),
    max_temp = as.numeric(weather_days$maxtempC),
    min_temp = as.numeric(weather_days$mintempC),
    avg_temp = (as.numeric(weather_days$maxtempC) + as.numeric(weather_days$mintempC)) / 2,
    stringsAsFactors = FALSE
  )
  return(df)
}


# ─── MAIN ─────────────────────────────────────────────────────────────────────

cat(sprintf("\n🌍 World Weather Online — fetching weather for %s...\n", location))

data <- fetch_weather(location, days, API_KEY)

# Get readable location name
location_name <- tryCatch({
  area    <- data$nearest_area$areaName[[1]]$value[1]
  country <- data$nearest_area$country[[1]]$value[1]
  paste0(area, ", ", country)
}, error = function(e) location)

display_current(data$current_condition, location_name)
display_forecast(data$weather)

# Bonus: show as data frame
cat("\n📊 As a data frame (for analysis):\n\n")
df <- weather_to_dataframe(data$weather)
print(df)
cat("\n# You can now use ggplot2, write.csv(), or any R analysis tools on this data.\n")

cat("\nData by World Weather Online — https://www.worldweatheronline.com\n\n")
