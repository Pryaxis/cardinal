## Description:
##   Animetake allows the users to watch for updates to chinese cartoons
##
## Dependencies:
##   q
##
## Configuration:
##   None
##
## Commands:
##   hubot anime me watch Cartoon - Watches for updates for the Cartoon
##   hubot anime me unwatch Cartoon - Hubot will forget about this show and not watch for updates
##   hubot anime me status Cartoon - Inform the user what the latest release of the Cartoon is
#
#q = require 'q'
#
#watchedSeries = {}
#animeBrainKey = "watchedAnime"
#brainLoaded = false
#
#animeUpdateChannel = process.env.ANIME_UPDATE_CHANNEL ? ""
#
#module.exports = (robot) ->
#  robot.brain.on 'loaded', ->
#    if(brainLoaded)
#      return
#    brainLoaded = true
#    watchedSeries = robot.brain.get(animeBrainKey)
#    if not watchedSeries
#      watchedSeries = {}
#      robot.brain.set(animeBrainKey, watchedSeries)
#    setTimeout (->
#      scrapeAnimetakeTask(robot)), 0
#
#  #handle fetching the status of a watched series
#  robot.respond /anime me status (.*)/i, (msg) ->
#    if brainLoaded
#      animename = msg.match[1].toLowerCase()
#      if animename of watchedSeries
#        msg.send("Latest release for #{animename} is #{watchedSeries[animename]}")
#      else
#        msg.send("I am not currently watching that series (kappa)")
#
#  #handle adding a series to the watch list
#  robot.respond /anime me watch (.*)/i, (msg) ->
#    if brainLoaded
#      animename = msg.match[1].toLowerCase()
#      if animename not of watchedSeries
#        watchedSeries[animename] = ""
#        robot.brain.set(animeBrainKey, watchedSeries)
#        robot.brain.save()
#        msg.send("Now watching #{animename}")
#      else
#        msg.send("I am already watching that (kappa)")
#
#  #handle removing a series to the watch list
#  robot.respond /anime me unwatch (.*)/i, (msg) ->
#    if brainLoaded
#      animename = msg.match[1].toLowerCase()
#      if animename of watchedSeries
#        delete watchedSeries[animename]
#        robot.brain.set(animeBrainKey, watchedSeries)
#        robot.brain.save()
#        msg.send("I no longer know about #{animename}")
#      else
#        msg.send("I am not watching that (kappa)")
#
#scrapeAnimetakeTask = (robot) ->
#  scrapeAnimetake(robot)
#  .then (body) ->
#    shouldUpdateBrain = false
#    startOfBlockRegex = "<div class=\"updateinfo\">"
#    startOfRelease = body.indexOf(startOfBlockRegex)
#    while(startOfRelease > -1)
#      releaseInfoBlock = body[startOfRelease..body.length]
#      updateBlockRegex = /<div class="updateinfo">\s+<h4><a href=".+" title=".+">(.+)<\/a><\/h4>\s+<span><em>Posted by<\/em>.+<em>on<\/em>.+<\/span>\s+More Episodes here: <a href=".+">(.+) Downloads<\/a>/
#      match = updateBlockRegex.exec(releaseInfoBlock)
#      if match
#        animeName = match[2].toLowerCase()
#        episodeName = match[1].toLowerCase()
#        if animeName of watchedSeries
#          if episodeName isnt watchedSeries[animeName]
#            shouldUpdateBrain = true
#            watchedSeries[animeName] = episodeName
#            robot.messageRoom(animeUpdateChannel, "#{match[2]} has a new episode: #{match[1]}")
#      startOfRelease = body.indexOf("<div class=\"updateinfo\">", startOfRelease + startOfBlockRegex.length)
#    if shouldUpdateBrain
#      robot.brain.set(animeBrainKey, watchedSeries)
#      robot.brain.save()
#  .fail (err) ->
#    console.log("Failed to get webpage: #{err}")
#  setTimeout (->
#    scrapeAnimetakeTask(robot)), 1000 * 60 * 10
#
#handleWebResponse = (err, res) ->
#  failure = ""
#  if err
#    failure = "Failed to complete web request: #{err}"
#  if res.statusCode isnt 200
#    failure = "Invalid request: #{res.statusCode}"
#  return failure
#
#scrapeAnimetake = (robot) ->
#  promise = q.defer()
#  robot.http("http://www.animetake.com")
#  .get() (err, res, body) ->
#    error = handleWebResponse(err, res)
#    if error is ""
#        promise.resolve(body)
#    else
#      promise.reject(error)
#  return promise.promise
