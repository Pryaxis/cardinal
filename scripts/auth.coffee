# stripped down version of https://github.com/dtaniwaki/hubot-privilege/blob/master/src/privilege.coffee

if process.env.HUBOT_ADMINS
  hubot_admins = process.env.HUBOT_ADMINS
else
  hubot_admins = []

permissions = []
brainLoaded = false

module.exports = (robot) ->
  robot.brain.on 'loaded', ->
    if(brainLoaded)
      return
    brainLoaded = true
    permissions = robot.brain.get("permissions")
    if not permissions
      permissions = []
      robot.brain.set("permissions", permissions)
      robot.brain.save()
    else
      console.log("Permissions: #{permissions}")

  receiveOrg = robot.receive
  robot.receive = (msg) ->
    if (msg.text)
      if (msg.text.toLowerCase().substr(0, robot.name.length + 1) is "#{robot.name.toLowerCase()} ")
        if (msg.user?.name in permissions or msg.user?.name in hubot_admins)
          receiveOrg.bind(robot)(msg)
        else
          robot.send(msg.user, "#{msg.user?.name} does not have permission to use #{robot?.name}.")

  robot.topic (msg) ->
    if (msg.message.user.name not in hubot_admins)
      msg.send("Only admins can change topics.")
      msg.finish()

  robot.respond /allow (.+)/i, (msg) ->
    if (msg.message.user.name in hubot_admins)
      permissions.push(msg.match[1])
      robot.brain.set("permissions", permissions)
      robot.brain.save()
      msg.send("#{msg.match[1]} is now allowed to use #{robot.name}.")
    else
      msg.send("#{msg.message.user.name} is not an admin.  This event has been logged.")

  robot.respond /disallow (.+)/i, (msg) ->
    if (msg.message.user.name in hubot_admins)
      i = permissions.indexOf(msg.match[1])
      if (i > -1)
        permissions.splice(i, 1)
        robot.brain.set("permissions", permissions)
        robot.brain.save()
        msg.send("#{msg.match[1]} is not allowed to use #{robot.name}.")
      else
        msg.send("#{msg.match[1]} was not allowed previously.")
    else
      msg.send("#{msg.message.user.name} is not an admin.  This event has been logged.")
