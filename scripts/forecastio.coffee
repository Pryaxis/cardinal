# Description:
#   ForecastIO allows the users to look up the current weather via Forecast.io
#
# Dependencies:
#   q
#
# Configuration:
#   None
#
# Commands:
#   hubot weather me <address, zip code, etc> - Returns the current temperature.
#   hubot forecast me <address, zip code, etc> - Returns the 5 day forecast for the location.
#   hubot weather location <location> - saves this location as your location, allowing you to use the other commands without any info
#

q = require 'q'

NAMES = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
weather_address = {}
brainLoaded = false

module.exports = (robot) ->
  robot.brain.on 'loaded', ->
    if(brainLoaded)
      return
    brainLoaded = true
    weather_address = robot.brain.get("weather_addresses")
    if not weather_address
      weather_address = {}
      robot.brain.set("weather_addresses", weather_address)
      robot.brain.save()

  robot.respond /weather location (.+)/i, (msg) ->
    if brainLoaded
      weather_address[msg.message.user.id] = msg.match[1]
      robot.brain.set("weather_addresses", weather_address)
      robot.brain.save()
      msg.send("Cool, we've got your location stored.")

  robot.respond /weather me\s?(.*)/i, (msg) ->
    address = ""
    if msg.match[1] and msg.match[1] isnt ""
      address = msg.match[1]
    else if msg.message.user.id of weather_address
      address = weather_address[msg.message.user.id]
    else
      msg.send("You must store a location first by using weather location <location>.")
      return

    lookupLongLatFromAddress(robot, address)
    .then (geocode) ->
      geometry = geocode['geometry']
      location = geometry['location']
      fetchWeatherFromLongLat(robot, location['lng'], location['lat'])
      .then (forecast) ->
        forecast_now = forecast['currently']
        forecast_imminent = forecast['minutely']
        forecast_future = forecast['hourly']
        
        end_result = "The temperature for #{geocode['formatted_address']} is #{forecast_now['temperature']}. Feels like #{forecast_now['apparentTemperature']} degrees."
        
        if typeof forecast_imminent == 'undefined'
          if typeof forecast_future == 'undefined'
            end_result += " No conditions found."
          else
            end_result += " Future: #{forecast_future['summary']}"
        else
          end_result += " Imminently: #{forecast_imminent['summary']}"

        if typeof forecast['alerts'] isnt 'undefined'
          end_result += " Active warnings and watches:"
          end_result += " #{alert['title']}." for alert in forecast['alerts']

        msg.send(end_result)
      
      .fail (e) ->
        msg.send(e)
    .fail (e) ->
      msg.send(e)

  robot.respond /forecast me\s?(.*)/i, (msg) ->
    address = ""
    if msg.match[1] and msg.match[1] isnt ""
      address = msg.match[1]
    else if msg.message.user.id of weather_address
      address = weather_address[msg.message.user.id]
    else
      msg.send("You must store a location first by using weather location <location>.")
      return

    lookupLongLatFromAddress(robot, address)
    .then (geocode) ->
      geometry = geocode['geometry']
      location = geometry['location']
      fetchWeatherFromLongLat(robot, location['lng'], location['lat'])
      .then (forecast) ->
        forecast = forecast['daily']
        resp = "The forecast for #{geocode['formatted_address']} is:\n"
        for index, day of forecast['data']
          date = new Date(day['time'] * 1000)
          dayIndex = date.getDay()
          dayName = NAMES[dayIndex]
          resp = resp + "#{dayName}: #{day['temperatureMin']}/#{day['temperatureMax']} degrees, #{day['summary']}\n"
        msg.send(resp)
      .fail (e) ->
        msg.send(e)
    .fail (e) ->
      msg.send(e)

handleWebResponse = (err, res) ->
  failure = ""
  if err
    failure = "Failed to complete web request: #{err}"
  if res.statusCode isnt 200
    failure = "Invalid request: #{res.statusCode}"
  return failure

googleGeocodeUrl = "https://maps.googleapis.com/maps/api/geocode/json"
googleApiKey = process.env.GOOGLE_API_KEY ? ""
lookupLongLatFromAddress = (robot, address) ->
  promise = q.defer()
  robot.http("#{googleGeocodeUrl}?key=#{googleApiKey}&address=#{address}").get() (err, res, body) ->
    error = handleWebResponse(err, res)
    if error is ""
      try
        geocode = JSON.parse(body)["results"][0]
        promise.resolve(geocode)
      catch
        promise.reject("Failed to lookup location via Geocode.")
    else
      q.reject(error)
  return promise.promise

forecastIoUrl = "https://api.darksky.net/forecast"
forecastIoKey = process.env.FORECAST_IO_KEY ? ""
fetchWeatherFromLongLat = (robot, longitude, latitude) ->
  promise = q.defer()
  robot.http("#{forecastIoUrl}/#{forecastIoKey}/#{latitude},#{longitude}").get() (err, res, body) ->
    error = handleWebResponse(err, res)
    if error is ""
      forecast = JSON.parse(body)
      promise.resolve(forecast)
    else
      q.reject(error)
  return promise.promise
