if process.env.HUBOT_ADMINS
  hubot_admins = process.env.HUBOT_ADMINS.split(',')
else
  hubot_admins = []

module.exports = (robot) ->
  brainLoaded = false
  triggers = {"test":"This is a trigger"}

  update_brain = () ->
    robot.brain.set("triggers", triggers)
    robot.brain.save()

  generate_triggers = () ->
    reg = ""
    for key, value of triggers
      if (reg.length > 0)
        reg = reg + "|"
      reg = reg + key
    return reg

  robot.brain.on 'loaded', ->
    if(brainLoaded)
      return
    brainLoaded = true
    triggers = robot.brain.get('triggers')
    if not triggers
      triggers = {}
      update_brain()

  robot.respond /add trigger ([a-z0-9\s]+):(.+)/i, (msg) ->
    if (msg.user.id in hubot_admins)
      triggers[msg.match[1]] = msg.match[2]
      update_brain()
      msg.reply("Added '#{msg.match[2]}' for trigger '#{msg.match[1]}'")
      msg.finish()

  robot.respond /del trigger ([a-z0-9\s]+)/i, (msg) ->
    if (msg.user.id in hubot_admins)
      delete triggers[msg.match[1]]
      update_brain()
      msg.reply("Deleted trigger '#{msg.match[1]}'")
      msg.finish()

  robot.hear /.+/i, (msg) ->
    pattern = generate_triggers()
    if (pattern)
      triggersHeard = ///#{pattern}///.exec(msg.match[0])
      if triggersHeard and triggersHeard.length > 0
        for trig in triggersHeard
          msg.reply(triggers[trig])
