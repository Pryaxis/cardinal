# stripped down version of https://github.com/dtaniwaki/hubot-privilege/blob/master/src/privilege.coffee
{Robot, Adapter, EnterMessage, LeaveMessage, TopicMessage} = require 'hubot'
json = require('json')

if process.env.HUBOT_ADMINS
  hubot_admins = process.env.HUBOT_ADMINS.split(',')
else
  hubot_admins = []

permissions = []
topicLocks = {}
brainLoaded = false

module.exports = (robot) ->
  robot.brain.on 'loaded', ->
    if(brainLoaded)
      return
    brainLoaded = true
    permissions = robot.brain.get("permissions")
    topicLocks = robot.brain.get("topicLocks")
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
    if msg instanceof TopicMessage
      console.log("TopicMsg: #{json.stringify(msg.user)}")
      room = msg.user.room
      oldTopic = ''
      if (room.id in topicLocks)
        oldTopic = topicLocks[room.id]

      if msg.user.id not in hubot_admins
        robot.send(msg.user, "#{msg.user?.name}:#{msg.user?.id} does not have permission to set topics.")
        msg.finish()
        fake_envelope = {room: room, user: robot.brain.userForName(process.env.ADMIN_TOPIC_NAME or "nicatrontg")}
        robot.adapter.topic(fake_envelope, oldTopic)
      else
          robot.send(msg.user, "I have remembered this topic <3")
          topicLocks[room.id] = msg.text
          robot.brain.set("topicLocks", topicLocks)
          robot.brain.save()
      return

    if (msg.text)
      if (msg.user?.id not in permissions and msg.user?.id not in hubot_admins)
        if ((msg.text.toLowerCase().substr(0, robot.name.length + 1) is "#{robot.name.toLowerCase()} ") or (msg.text.toLowerCase().substr(0, robot.name.length + 2) is "\@#{robot.name.toLowerCase()} "))
          robot.send(msg.user, "#{msg.user?.name}:#{msg.user?.id} does not have permission to use #{robot?.name}.")
      else
        receiveOrg.bind(robot)(msg)

#  robot.topic (msg) ->
#    room = msg.envelope.room.name
#    oldTopic = ''
#    if (room in topicLocks)
#      oldTopic = topicLocks[room]
#
#    user = robot.brain.userForName(msg.envelope.user.name)
#    if user
#      if (user.id in hubot_admins)
#        topicLocks[room] = msg.envelope.room.message.text
#        robot.brain.set("topicLocks", topicLocks)
#        robot.brain.save()
#    fake_envelope = {room: room, user: robot.brain.userForName(process.env.ADMIN_TOPIC_NAME or "nicatrontg")}
#    robot.adapter.topic(fake_envelope, oldTopic)

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
