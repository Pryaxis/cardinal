# stripped down version of https://github.com/dtaniwaki/hubot-privilege/blob/master/src/privilege.coffee

if process.env.HUBOT_ADMINS
  hubot_admins = process.env.HUBOT_ADMINS.split(',')
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
      if (msg.user?.id not in permissions or msg.user?.id not in hubot_admins)
        if ((msg.text.toLowerCase().substr(0, robot.name.length + 1) is "#{robot.name.toLowerCase()} ") or (msg.text.toLowerCase().substr(0, robot.name.length + 2) is "\@#{robot.name.toLowerCase()} "))
          robot.send(msg.user, "#{msg.user?.name}:#{msg.user?.id} does not have permission to use #{robot?.name}.")
      else
        receiveOrg.bind(robot)(msg)

  robot.topic (msg) ->
    console.log(msg)
    if (msg.message.user.id not in hubot_admins)
      msg.send("Only admins can change topics.")
      msg.finish()

  robot.respond /allow (.+)/i, (msg) ->
    if (msg.message.user.id in hubot_admins)
      user = robot.brain.userForName(msg.match[1])
      if user
        permissions.push(user.id)
        robot.brain.set("permissions", permissions)
        robot.brain.save()
        msg.send("#{msg.match[1]} is now allowed to use #{robot.name}.")
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
