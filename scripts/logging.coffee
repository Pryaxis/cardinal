fs = require('fs')
{TextMessage} = require 'hubot'
module.exports = (robot) ->
  receiveOrg = robot.receive
  robot.receive = (msg) ->
    if msg instanceof TextMessage
      room = msg.user.room
      text = msg.text
      time = msg.id
      #console.log(msg)
      fs.appendFile(room + ".log", "#{time}: #{text}\n", (err) ->
        if err
          console.log("Failed to write msg to log.  #{msg.user.name}> #{time}: #{text}")
      )
    receiveOrg.bind(robot)(msg)
