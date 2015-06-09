# Description:
#   Time allows you to get the local time for any location on Earth (tm)
#
# Dependencies:
#   q
#
# Configuration:
#   None
#
# Commands:
#   hubot what time is it in <address, zip code, etc> - Returns the current time.
#

q = require 'q'

module.exports = (robot) ->

  robot.respond /what time is it in (.+)/i, (msg) ->
    address = ""
    if msg.match[1] and msg.match[1] isnt ""
      address = msg.match[1]
    else
      msg.send("You must specify a location.")
      return

    lookupLongLatFromAddress(robot, address)
    .then (geocode) ->
      geometry = geocode['geometry']
      location = geometry['location']
      lookupTimezoneFromLongLat(robot, location['lng'], location['lat'])
      .then (time) ->
        hour = time.getUTCHours()
        minutes = time.getUTCMinutes()
        amPm = "AM"

        if (hour is 12)
          amPm = "PM"
        if (hour > 12)
          hour = hour - 12
          amPm = "PM"

        if (hour is 0)
          hour = 12
          
        if (minutes < 10)
          minutes = "0" + minutes;

        msg.send("The time in #{geocode['formatted_address']} is #{hour}:#{minutes} #{amPm} #{time.getUTCMonth() + 1}/#{time.getUTCDate()}/#{time.getUTCFullYear()}.")
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

googleTimezoneUrl = "https://maps.googleapis.com/maps/api/timezone/json"
googleApiKey = process.env.GOOGLE_API_KEY ? ""
lookupTimezoneFromLongLat = (robot, long, lat) ->
  promise = q.defer()
  secondsSinceEpoch = Math.ceil(Date.now() / 1000)
  robot.http("#{googleTimezoneUrl}?key=#{googleApiKey}&location=#{lat},#{long}&timestamp=#{secondsSinceEpoch}").get() (err, res, body) ->
    error = handleWebResponse(err, res)
    if error is ""
      try
        time = JSON.parse(body)
        current = Date.now()
        current = current + (time['rawOffset'] * 1000)
        current = current + (time['dstOffset'] * 1000)
        promise.resolve(new Date(current))
      catch
        promise.reject("Failed to lookup timezone via Timezone.")
    else
      q.reject(error)
  return promise.promise
