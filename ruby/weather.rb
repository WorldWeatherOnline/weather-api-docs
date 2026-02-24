# World Weather Online — Weather Dashboard (Ruby)
# =================================================
# Fetches and displays current weather + 5-day forecast.
#
# Requirements:
#   Ruby 2.7+  (uses only standard library — no gems needed)
#
# Usage:
#   ruby weather.rb
#   ruby weather.rb London
#   ruby weather.rb "New York" 3
#
# Set your API key:
#   export WWO_API_KEY="your_key_here"
#
# Get a free key at:
#   https://www.worldweatheronline.com/weather-api/

require 'net/http'
require 'uri'
require 'json'
require 'date'

# ─── CONFIG ───────────────────────────────────────────────────────────────────

API_KEY  = ENV['WWO_API_KEY'] || 'your_api_key_here'
BASE_URL = 'https://api.worldweatheronline.com/premium/v1/weather.ashx'

ICONS = {
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
  'blizzard'      => '🌨️'
}.freeze

def get_icon(description)
  desc = description.downcase
  ICONS.each { |key, icon| return icon if desc.include?(key) }
  '🌡️'
end


# ─── API CALL ─────────────────────────────────────────────────────────────────

def fetch_weather(location, days)
  if API_KEY == 'your_api_key_here'
    warn "❌  Please set your API key!"
    warn "    export WWO_API_KEY='your_key_here'"
    warn "    Get a free key: https://www.worldweatheronline.com/weather-api/"
    exit 1
  end

  uri = URI(BASE_URL)
  uri.query = URI.encode_www_form(
    key:             API_KEY,
    q:               location,
    format:          'json',
    num_of_days:     days,
    tp:              24,
    includelocation: 'yes',
    cc:              'yes'
  )

  http          = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl  = true
  http.open_timeout = 10
  http.read_timeout = 10

  request = Net::HTTP::Get.new(uri)
  request['User-Agent'] = 'WWO-Ruby-Client/1.0'

  response = http.request(request)

  unless response.is_a?(Net::HTTPSuccess)
    warn "❌  HTTP Error: #{response.code}"
    exit 1
  end

  data = JSON.parse(response.body)['data']

  if data['error']
    warn "❌  API Error: #{data['error'][0]['msg']}"
    exit 1
  end

  data
rescue Errno::ECONNREFUSED, SocketError => e
  warn "❌  Connection error: #{e.message}"
  exit 1
end


# ─── DISPLAY ──────────────────────────────────────────────────────────────────

def display_current(current, location_name)
  desc   = current['weatherDesc'][0]['value']
  icon   = get_icon(desc)

  puts "\n#{'─' * 50}"
  puts "📍 #{location_name} — Right Now"
  puts '─' * 50
  puts "#{icon}  #{desc}"
  puts "🌡️  Temperature : #{current['temp_C']}°C / #{current['temp_F']}°F (Feels like #{current['FeelsLikeC']}°C)"
  puts "💧  Humidity    : #{current['humidity']}%"
  puts "💨  Wind        : #{current['windspeedMiles']} mph #{current['winddir16Point']}"
  puts "👁️  Visibility  : #{current['visibility']} km"
  puts "☀️  UV Index    : #{current['uvIndex']}"
  puts '─' * 50
end

def display_forecast(weather_days)
  puts "\n📅 Forecast\n\n"
  printf("%-14s %-25s %7s %7s %7s\n", 'Date', 'Conditions', 'High', 'Low', 'Rain%')
  puts '─' * 65

  weather_days.each do |day|
    date     = Date.parse(day['date'])
    date_fmt = date.strftime('%a %d %b')
    desc     = day['hourly'][0]['weatherDesc'][0]['value']
    icon     = get_icon(desc)
    rain     = day['hourly'][0]['chanceofrain'] || 'N/A'

    printf(
      "%-14s %-25s %7s %7s %7s\n",
      date_fmt,
      "#{icon} #{desc}",
      "#{day['maxtempC']}°C",
      "#{day['mintempC']}°C",
      "#{rain}%"
    )
  end

  puts '─' * 65
end


# ─── MAIN ─────────────────────────────────────────────────────────────────────

location = ARGV[0] || 'London'
days     = (ARGV[1] || 5).to_i

puts "\n🌍 World Weather Online — fetching weather for #{location}..."

data = fetch_weather(location, days)

# Get readable location name
location_name = begin
  area    = data['nearest_area'][0]['areaName'][0]['value']
  country = data['nearest_area'][0]['country'][0]['value']
  "#{area}, #{country}"
rescue StandardError
  location
end

display_current(data['current_condition'][0], location_name)
display_forecast(data['weather'])

puts "\nData by World Weather Online — https://www.worldweatheronline.com\n\n"
