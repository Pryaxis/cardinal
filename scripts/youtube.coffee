# Description:
#   Allows you to search youtube videos
#
# Dependencies:
#   q
#
# Configuration:
#   None
#
# Commands:
#   hubot youtube me <search> - Finds the first video result matching the search criteria
#

q = require 'q'

module.exports = (robot) ->
  robot.respond /youtube me (.*)/i, (msg) ->
    search = msg.match[1]
    #Pipe characters in the search query must be sent url-escaped
    #(https://developers.google.com/youtube/v3/docs/search/list#q)
    search = search.replace "|", "%7C"
    getPost(robot, search)
    .then (item) ->
      title = item["snippet"].title
      id = item["id"].videoId
      msg.send("#{title} - https://youtube.com/watch?v=#{id}")
    .fail (err) ->
      msg.send("#{err}")

handleWebResponse = (err, res) ->
  failure = ""
  if err
    failure = "Failed to complete web request: #{err}"
  if res.statusCode isnt 200
    failure = "Invalid request: #{res.statusCode}"
  return failure

getPost = (robot, search) ->
  promise = q.defer()
  token = process.env.YOUTUBE_API_KEY
  if (!token)
    promise.reject("No Youtube API key configured.")
  else
    robot.http("https://www.googleapis.com/youtube/v3/search?part=snippet&q=#{search}&key=#{token}")
    .get() (err, res, body) ->
      error = handleWebResponse(err, res)
      if error is ""
        search = search.replace /\"\"([^\"]+)\"/g, "\"'$1'"
        search = JSON.parse(body)
        if search.length > 0
          promise.resolve(search["items"][0])
        else
          promise.reject("No videos found.")
      else
        promise.reject(error)
  return promise.promise
