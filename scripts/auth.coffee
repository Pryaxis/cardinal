# stripped down version of https://github.com/dtaniwaki/hubot-privilege/blob/master/src/privilege.coffee
{Robot, Adapter, EnterMessage, LeaveMessage, TopicMessage} = require 'hubot'
Html5Entities = require('html-entities').Html5Entities
entities = new Html5Entities()

if process.env.HUBOT_ADMINS
  hubot_admins = process.env.HUBOT_ADMINS.split(',')
else
  hubot_admins = [1]

permissions = []
topicLocks = {}
brainLoaded = false
aliases = []

module.exports = (robot) ->
  robot.brain.on 'loaded', ->
    if(brainLoaded)
      return
    brainLoaded = true
    permissions = robot.brain.get("permissions")
    topicLocks = robot.brain.get("topicLocks")
    aliases = robot.brain.get("aliases")
    if not aliases
      aliases = []
      robot.brain.set("aliases", aliases)
      robot.brain.save()

    if not topicLocks
      topicLocks = {}
      robot.brain.set("topicLocks", topicLocks)
      robot.brain.save()

    if not permissions
      permissions = []
      robot.brain.set("permissions", permissions)
      robot.brain.save()

  receiveOrg = robot.receive
  robot.receive = (msg) ->

    #TopicLocking feature for slack.
    if msg instanceof TopicMessage
      room = msg.user.room
      oldTopic = '(none)'
      if (room of topicLocks)
        oldTopic = topicLocks[room]

      if msg.user.id not in hubot_admins
        robot.send(msg.user, "#{msg.user?.name}:#{msg.user?.id} does not have permission to set topics.")
        msg.finish()
        fake_envelope = {room: room, user: robot.brain.userForName(process.env.ADMIN_TOPIC_NAME or "nicatrontg")}
        robot.adapter.topic(fake_envelope, entities.decode(oldTopic))
      else
          topicLocks[room] = msg.text
          robot.brain.set("topicLocks", topicLocks)
          robot.brain.save()
      return

    #Aliases for the bot because hubot danbooru image me
    if (msg.text)
      first_space = msg.text.indexOf(" ")
      if (first_space > -1)
        first_word = msg.text.substr(0, first_space).toLowerCase()
        if (first_word != robot.name.toLowerCase())
          if(first_word in aliases)
            msg.text = "#{robot.name} #{msg.text.substring(first_space + 1)}"

    #Permission Checks for Commands and other hubot responses.
    if (msg.text)
      if (msg.user?.id not in permissions and msg.user?.id not in hubot_admins)
        if ((msg.text.toLowerCase().substr(0, robot.name.length + 1) is "#{robot.name.toLowerCase()} ") or (msg.text.toLowerCase().substr(0, robot.name.length + 2) is "\@#{robot.name.toLowerCase()} "))
          robot.send(msg.user, "#{msg.user?.name}:#{msg.user?.id} does not have permission to use #{robot?.name}.")
      else
        receiveOrg.bind(robot)(msg)

  robot.respond /allow (.+)/i, (msg) ->
    if (msg.message.user.id in hubot_admins)
      user = robot.brain.userForName(msg.match[1])
      if user
        if (user.id not in permissions)
          permissions.push(user.id)
          robot.brain.set("permissions", permissions)
          robot.brain.save()
          msg.send("#{msg.match[1]} is now allowed to use #{robot.name}.")
        else
          msg.send("#{user.name} is already allowed.")
      else
        msg.send("Could not find a user called #{msg.match[1]}")
    else
      msg.send("#{msg.message.user.name} is not an admin.  This event has been logged.")

  robot.respond /disallow (.+)/i, (msg) ->
    if (msg.message.user.id in hubot_admins)
      user = robot.brain.userForName(msg.match[1])
      if user
        i = permissions.indexOf(user.id)
        if (i > -1)
          permissions.splice(i, 1)
          robot.brain.set("permissions", permissions)
          robot.brain.save()
          msg.send("#{user.name} is not allowed to use #{robot.name}.")
        else
          msg.send("#{user.name} was not allowed previously.")
      else
        msg.send("Could not find a user called #{msg.match[1]}")
    else
      msg.send("#{msg.message.user.name} is not an admin.  This event has been logged.")

  robot.respond /alias (rem|add) (.+)/i, (msg) ->
    if (msg.message.user.id in hubot_admins)
      if (msg.match[1].toLowerCase() is "rem")
        index = aliases.indexOf(msg.match[2].toLowerCase())
        if (index > -1)
          aliases.splice(index, 1)
          robot.brain.set("aliases", aliases)
          robot.brain.save()
          msg.send("I will stop responding to #{msg.match[2].toLowerCase()}")
      else if (msg.match[1].toLowerCase() is "add")
        aliases.push(msg.match[2].toLowerCase())
        robot.brain.set("aliases", aliases)
        robot.brain.save()
        msg.send("I will now respond to #{msg.match[2].toLowerCase()}")
    else
      msg.send("#{msg.message.user.name} is not an admin.  This event has been logged.")
