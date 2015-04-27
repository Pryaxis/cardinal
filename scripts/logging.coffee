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

      data = {}
      data.time = time
      data.user = {}
      data.user.id = msg.user.id
      data.user.name = msg.user.name
      data.message = text
      data.channel = msg.user.room

      if process.env.REMOTE_LOGGER
        robot.http(process.env.REMOTE_LOGGER).header('Content-Type', 'application/json').post(JSON.stringify(data)) (err, res, body) ->
          console.log(data)
          if err
            console.log(err)

      fs.appendFile(room + ".log", "#{time}: #{text}\n", (err) ->
        if err
          console.log("Failed to write msg to log.  #{msg.user.name}> #{time}: #{text}")
      )
    receiveOrg.bind(robot)(msg)
