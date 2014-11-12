# Description:
#   Gist makes hubot print the content of a gist link
#
# Dependencies:
#   q
#
# Configuration:
#   None
#

q = require 'q'

module.exports = (robot) ->
  robot.hear /.*gist.github.com\/.*\/(.*)/i, (msg) ->
    lookupGistInfo(robot, msg.match[1])
    .then (content) ->
      for k, v of content
        msg.send(v['content'])
    .fail (e) ->
      msg.send(e)

handleWebResponse = (err, res) ->
  failure = ""
  if err
    failure = "Failed to complete web request: #{err}"
  if res.statusCode isnt 200
    failure = "Invalid request: #{res.statusCode}"
  return failure

githubUrl = "https://api.github.com/gists"
lookupGistInfo = (robot, gistid) ->
  promise = q.defer()
  robot.http("#{githubUrl}/#{gistid}").get() (err, res, body) ->
    error = handleWebResponse(err, res)
    if error is ""
      try
        gistinfo = JSON.parse(body)["files"]
        promise.resolve(gistinfo)
      catch
        promise.reject("Failed to lookup gist info via Github.")
    else
      q.reject(error)
  return promise.promise
