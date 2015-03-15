q = require 'q'
crypto = require 'crypto'

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

host = process.env.IMAGE_PROXY_HOST or "https://ancient-meadow-2257.herokuapp.com"

create_hmac = (url) ->
  hmac = crypto.createHmac("sha1", process.env.IMAGE_PROXY_KEY or "test")
  hmac.setEncoding("hex")
  hmac.write(url)
  hmac.end()
  digest = hmac.read('hex')
  imgurl = encodeURIComponent(url)
  return "#{host}/#{digest}?url=#{imgurl}"

module.exports = (robot) ->
  robot.hear /:jappa:/i, (msg) ->
    msg.send("http://www.everio-fan.com/wp-content/uploads/2011/09/kappa_image.png")

  robot.respond /proxy me (.*)/i, (msg) ->
    proxy_url = create_hmac(msg.match[1])
    msg.send(proxy_url)

  robot.respond /danbooru image me (.*)/i, (msg) ->
    if msg.message.room in danbooru_allowed_rooms
      response = ""
      tagname = msg.match[1].trim()
      multipleTags = tagname.split(',')
      getRandomImageFromTags(robot, multipleTags).then (payload) ->
        proxy_url = create_hmac(payload.url)
        msg.send("Image id: #{payload.id} - #{proxy_url}")
      .fail (e) ->
        msg.send("Failed to get random image: #{e}")

  robot.respond /danbooru pool me (.*)/i, (msg) ->
    if msg.message.room in danbooru_allowed_rooms
      response = ""
      poolname = msg.match[1].trim()
      poolname = poolname.replace(/\ /g, "_")
      response = response + "Searching danbooru for a pool called #{poolname}\n"
      getPoolDetails(robot, poolname)
      .then (posts) ->
        posts = posts.split(' ')
        postsCount = posts.length
        response = response + "Found #{postsCount} posts for #{poolname}\n"
        post = Math.floor(Math.random() * (postsCount - 1) + 1)
        lookupPoolImage(robot, posts[post])
        .then (post) ->
          url = "http://danbooru.donmai.us#{post["file_url"]}"
          proxy_url = create_hmac(url)
          msg.send("Image ID: #{post["id"]} - #{proxy_url}")
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
        promise.resolve(post)
      else
        promise.reject("This post does not exist.")
    else
      promise.reject(error)
  return promise.promise

getRandomPost = (robot, tags) ->
  promise = q.defer()
  robot.http("http://danbooru.donmai.us/posts/random?tags=#{tags.join('+')}")
  .headers(Authorization: danbooru_api_basic_auth)
  .get() (err, res, body) ->
    if res.statusCode is 302
      promise.resolve(res['headers']['location'])
    else
      promise.reject("Did not get redirected to new image.")
  return promise.promise

getRandomImageFromTags = (robot, multipleTags) ->
  promise = q.defer()
  promises = []
  for k,v of multipleTags
    tag = v.trim()
    tag = tag.replace(/\ /g, "_")
    p = determineRootTag(robot, tag)
    promises.push(p)

  q.allSettled(promises).then (results) ->
    tags = []
    for index, res of results
      if res['state'] and res['state'] is "fulfilled"
        tags.push(res['value'])
    getRandomPost(robot, tags).then (url) ->
      postIdRegex = /http:\/\/danbooru\.donmai\.us\/posts\/([0-9]+).*/
      match = postIdRegex.exec(url)
      if match
        lookupPoolImage(robot, match[1]).then (post) ->
          promise.resolve({"id":"#{post["id"]}", "url":"http://danbooru.donmai.us#{post["file_url"]}"})
        .fail (e) ->
          promise.reject(e)
      else
        promise.reject("Could not match regex for post id.")
    .fail (e) ->
      promise.reject(e)
  return promise.promise
