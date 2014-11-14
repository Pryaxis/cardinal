q = require 'q'

if process.env.FURRY_ROOMS_ALLOWED
  furry_allowed_rooms = process.env.FURRY_ROOMS_ALLOWED.split(',') 
  console.log(furry_allowed_rooms)
else
  furry_allowed_rooms = []

module.exports = (robot) ->
  robot.respond /furry me (.*)\b/i, (msg) ->
    if not msg.envelope.room in furry_allowed_rooms
      msg.send("Furry is not allowed in this room.")
      return
    tags = msg.match[1]
    rating = "s"
    last = tags.substring(tags.length-1)
    if last in ["e", "q", "s"]
      tags = tags.substring(0,tags.indexOf(last+",", tags.length-2))
      rating = last
    tags = tags.replace(" ", ",")
    if tags is ""
      msg.send("Format: hubot furry me <tags> [rating]")
      return
    msg.send("Searching e621 for an image including #{tags} with rating #{rating}")
    getPost(robot, tags, rating)
    .then (image_url) ->
      msg.send(image_url)
    .fail (err) ->
      msg.send("#{err}")

handleWebResponse = (err, res) ->
  failure = ""
  if err
    failure = "Failed to complete web request: #{err}"
  if res.statusCode isnt 200
    failure = "Invalid request: #{res.statusCode}"
  return failure

getPost = (robot, tags, rating) ->
  promise = q.defer()
  robot.http("https://e621.net/post/index.json?tags=#{tags},rating:#{rating}")
  .get() (err, res, body) ->
    error = handleWebResponse(err, res)
    if error is ""
      tag = JSON.parse(body)
      if tag.length > 0
        promise.resolve(tag[0]["sample_url"])
      else
        promise.reject("No posts found.")
    else
      promise.reject(error)
  return promise.promise
