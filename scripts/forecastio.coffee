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
#

q = require 'q'

NAMES = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]

module.exports = (robot) ->
  robot.respond /weather me (.*)/i, (msg) ->
    lookupLongLatFromAddress(robot, msg.match[1])
    .then (geocode) ->
      geometry = geocode['geometry']
      location = geometry['location']
      fetchWeatherFromLongLat(robot, location['lng'], location['lat'])
      .then (forecast) ->
        forecast = forecast['currently']
        msg.send("The temperature for #{geocode['formatted_address']} is #{forecast['temperature']} degrees and feels like #{forecast['apparentTemperature']} degrees.")
      .fail (e) ->
        msg.send(e)
    .fail (e) ->
      msg.send(e)
  robot.respond /forecast me (.*)/i, (msg) ->
    lookupLongLatFromAddress(robot, msg.match[1])
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

forecastIoUrl = "https://api.forecast.io/forecast"
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
