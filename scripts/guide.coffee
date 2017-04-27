# Description:
#   Helps you help other people.
# Commands:
#   hubot guide me - Gets you the canonical guide to TShock's unstable builds.

module.exports = (robot) ->
  robot.respond /guide me/i, (msg) ->
    msg.send "Here's the canonical guide to whatever just got asked. Enjoy: https://gist.github.com/hakusaro/8bbbf1d532c06fa39bef8ee6b4602324"