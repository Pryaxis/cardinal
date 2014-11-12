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
#   hubot forecast me <address, zip code, etc> - Returns the current temperature.

q = require 'q'

module.exports = (robot) ->
  robot.respond /forecast me (.*)/i, (msg) ->
    lookupLongLatFromAddress(robot, msg.match[1])
    .then (geocode) ->
      geometry = geocode['geometry']
      location = geometry['location']
      fetchWeatherFromLongLat(robot, location['lng'], location['lat'])
      .then (forecast) ->
        msg.send("The temperature for #{geocode['formatted_address']} is #{forecast['temperature']} and feels like #{forecast['apparentTemperature']}.")
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
googleApiKey = process.env.GOOGLE_API_KEY ? "AIzaSyDRKokT9dFdSpO6ay7wlid7j9AWfIv5JLs"
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
forecastIoKey = process.env.FORECAST_IO_KEY ? "79f72d503c46fd53de8f1ce0e02ed3fc"
fetchWeatherFromLongLat = (robot, longitude, latitude) ->
  promise = q.defer()
  robot.http("#{forecastIoUrl}/#{forecastIoKey}/#{latitude},#{longitude}").get() (err, res, body) ->
    error = handleWebResponse(err, res)
    if error is ""
      forecast = JSON.parse(body)['currently']
      promise.resolve(forecast)
    else
      q.reject(error)
  return promise.promise
