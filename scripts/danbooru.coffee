q = require 'q'

danbooru_api_username = process.env.DANBOORU_API_USERNAME ? ""
danbooru_api_token = process.env.DANBOORU_API_TOKEN ? ""

danbooru_api_basic_auth = 'Basic ' + new Buffer(danbooru_api_username + ':' + danbooru_api_token).toString('base64');

module.exports = (robot) ->
  robot.respond /danbooru me (.*)/i, (msg) ->
    tagname = msg.match[1]
    tagname = tagname.replace(" ", "_")
    msg.send("Searching danbooru for an image of #{tagname}")
    determineRootTag(robot, tagname)
    .then (origin_tag) ->
      msg.send("Resolved #{tagname} to #{origin_tag}")
      tagname = origin_tag
      getPostCount(robot, origin_tag)
      .then (postCount) ->
        msg.send("Found #{postCount} posts for #{tagname}")
        lookupImage(robot, tagname, postCount)
        .then (imageUrl) ->
          msg.send(imageUrl)
        .fail (e) ->
          msg.send(e)
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

determineRootTag = (robot, tagname) ->
  promise = q.defer()
  robot.http("http://danbooru.donmai.us/tag_aliases.json?search[name_matches]=#{tagname}")
  .headers(Authorization: danbooru_api_basic_auth)
  .get() (err, res, body) ->
    error = handleWebResponse(err, res)
    if error is ""
      tag_alias = JSON.parse(body)
      if tag_alias.length > 0
        promise.resolve(tag_alias[0]["consequent_name"])
      else
        promise.resolve(tagname)
    else
      promise.reject(error)
  return promise.promise

getPostCount = (robot, tagname, callback) ->
  promise = q.defer()
  robot.http("http://danbooru.donmai.us/tags.json?search[name_matches]=#{tagname}")
  .headers(Authorization: danbooru_api_basic_auth)
  .get() (err, res, body) ->
    error = handleWebResponse(err, res)
    if error is ""
      tag = JSON.parse(body)
      if tag.length > 0
        promise.resolve(tag[0]["post_count"])
      else promise.reject("This tag does not exist.")
    else
      promise.reject(error)
  return promise.promise

lookupImage = (robot, tagname, postCount) ->
  promise = q.defer()
  post = Math.floor(Math.random() * (Math.min(100000, postCount) - 1) + 1)
  page = 1
  if post > 100
    page = Math.floor(post / 100) + 1
  index = post % 100
  robot.http("http://danbooru.donmai.us/posts.json?limit=100&page=#{page}&tags=#{tagname}")
  .headers(Authorization: danbooru_api_basic_auth)
  .get() (err, res, body) ->
    error = handleWebResponse(err, res)
    if error is ""
      image = JSON.parse(body)
      if image.length > 0
        promise.resolve("http://danbooru.donmai.us#{image[index]['file_url']}")
      else
        promise.reject("Failed to load post #{post} which is the #{index} of page #{page}")
    else
      promise.reject(error)
  return promise.promise