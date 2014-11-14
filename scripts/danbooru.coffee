q = require 'q'

if process.env.DANBOORU_API_USERNAME
  danbooru_api_username = process.env.DANBOORU_API_USERNAME
else
  danbooru_api_username = ""

if process.env.DANBOORU_API_TOKEN
  danbooru_api_token = process.env.DANBOORU_API_TOKEN
else
  danbooru_api_token = ""

if process.env.DANBOORU_ALLOWED_ROOMS
  danbooru_allowed_rooms = process.env.DANBOORU_ALLOWED_ROOMS.split(',')
else
  danbooru_allowed_rooms = []

danbooru_api_basic_auth = 'Basic ' + new Buffer(danbooru_api_username + ':' + danbooru_api_token).toString('base64');

module.exports = (robot) ->
  robot.respond /danbooru image me (.*)/i, (msg) ->
    console.log(msg.message.room)
    console.log(msg.envelope.room)
    if msg.message.room in danbooru_allowed_rooms
      response = ""
      tagname = msg.match[1].trim()
      tagname = tagname.replace(" ", "_")
      response = response + "Searching danbooru for an image of #{tagname}\n"
      determineRootTag(robot, tagname)
      .then (origin_tag) ->
        response = response + "Resolved #{tagname} to #{origin_tag}\n"
        tagname = origin_tag
        getPostCount(robot, origin_tag)
        .then (postCount) ->
          response = response + "Found #{postCount} posts for #{tagname}\n"
          lookupImage(robot, tagname, postCount)
          .then (imageUrl) ->
            msg.send(response)
            msg.send(imageUrl)
          .fail (e) ->
            msg.send("Failed: #{e}")
        .fail (e) ->
          msg.send("Failed: #{e}")
      .fail (e) ->
        msg.send("Failed: #{e}")
  robot.respond /danbooru pool me (.*)/i, (msg) ->
    if msg.message.room in danbooru_allowed_rooms
      response = ""
      poolname = msg.match[1].trim()
      poolname = poolname.replace(" ", "_")
      response = response + "Searching danbooru for a pool called #{poolname}\n"
      getPoolDetails(robot, poolname)
      .then (posts) ->
        posts = posts.split(' ')
        postsCount = posts.length
        response = response + "Found #{postsCount} posts for #{poolname}\n"
        post = Math.floor(Math.random() * (postsCount - 1) + 1)
        lookupPoolImage(robot, posts[post])
        .then (imageUrl) ->
          msg.send(response)
          msg.send(imageUrl)
        .fail (e) ->
          msg.send("Failed: #{e}")
      .fail (e) ->
        msg.send("Failed: #{e}")

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

getPostCount = (robot, tagname) ->
  promise = q.defer()
  robot.http("http://danbooru.donmai.us/tags.json?search[name_matches]=#{tagname}")
  .headers(Authorization: danbooru_api_basic_auth)
  .get() (err, res, body) ->
    error = handleWebResponse(err, res)
    if error is ""
      tag = JSON.parse(body)
      if tag.length > 0
        promise.resolve(tag[0]["post_count"])
      else
        promise.reject("This tag does not exist.")
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

getPoolDetails = (robot, poolname) ->
  promise = q.defer()
  robot.http("http://danbooru.donmai.us/pools.json?search[name_matches]=#{poolname}")
  .headers(Authorization: danbooru_api_basic_auth)
  .get() (err, res, body) ->
    error = handleWebResponse(err, res)
    if error is ""
      pool = JSON.parse(body)
      if pool.length > 0
        promise.resolve(pool[0]["post_ids"])
      else
        promise.reject("This pool does not exist.")
    else
      promise.reject(error)
  return promise.promise

lookupPoolImage = (robot, postId) ->
  promise = q.defer()
  robot.http("http://danbooru.donmai.us/posts/#{postId}.json")
  .headers(Authorization: danbooru_api_basic_auth)
  .get() (err, res, body) ->
    error = handleWebResponse(err, res)
    if error is ""
      post = JSON.parse(body)
      if post
        promise.resolve("http://danbooru.donmai.us#{post["file_url"]}")
      else
        promise.reject("This post does not exist.")
    else
      promise.reject(error)
  return promise.promise
