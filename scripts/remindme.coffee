# Description:
#   RemindMe allows users to tell hubot to remind them to do something in x minutes.
#
#
# Configuration:
#   None
#
# Commands:
#   hubot remind me to <action> in <minutes> - Stores reminder.
#   hubot remind me in <minutes> to <action> - Stores reminder
#

q = require 'q'

reminders = []
brainLoaded = false

module.exports = (robot) ->
  robot.brain.on 'loaded', ->
    if(brainLoaded)
      return
    brainLoaded = true
    reminders = robot.brain.get("reminders")
    console.log(reminders)
    if not reminders
      reminders = []
      robot.brain.set("reminders", reminders)
      robot.brain.save()
    setTimeout(checkReminders, 1000)

  robot.respond /remind me in (\d+) (minute(s?))? to (.+)/i, (msg) ->
    if brainLoaded
      minutes = Math.ceil(msg.match[1])
      time = new Date()
      time.setMinutes(time.getMinutes() + parseInt(minutes))
      reminder = {}
      reminder.uid = msg.message.user.id
      reminder.time = time
      reminder.reminder = msg.match[4]
      msg.send("I will remind you to '#{reminder.reminder}' on #{reminder.time.toLocaleString()}")
      reminders.push(reminder)
      robot.brain.set("reminders", reminders)
      robot.brain.save()
  robot.respond /remind me to (.+) in (\d+).*/i, (msg) ->
    if brainLoaded
      minutes = Math.ceil(msg.match[2])
      time = new Date()
      time.setMinutes(time.getMinutes() + parseInt(minutes))
      reminder = {}
      reminder.uid = msg.message.user.id
      reminder.time = time
      reminder.reminder = msg.match[1]
      msg.send("I will remind you to '#{reminder.reminder}' on #{reminder.time.toLocaleString()}")
      reminders.push(reminder)
      robot.brain.set("reminders", reminders)
      robot.brain.save()

checkReminders = (robot) ->
  #console.log("Running reminder checks")
  now = new Date()
  k = 0
  while k < reminders.length
    v = reminders[k]
    try
      time = Date.parse(v.time)
      if time <= now.getTime()
        user = robot.brain.userForId(v.uid)
        robot.send({'room': user.name}, "#{user.mention_name ? user.name}: I am reminding you to '#{v.reminder}")
        reminders.splice(k, 1)
        robot.brain.set("reminders", reminders)
        robot.brain.save()
      else
        k++
    catch e
      console.error(e)
      console.log("Removing entry #{k}")
      reminders.splice(k, 1)
      robot.brain.set("reminders", reminders)
      robot.brain.save()
  setTimeout (-> checkReminders(robot)), 5000