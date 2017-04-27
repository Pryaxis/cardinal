# Description:
#   Helps you help other people.
# Commands:
#   hubot guide me - Gets you the canonical guide to TShock's unstable builds.
#   hubot guide <person> - Tells person how to get TShock's unstable builds.
#   remember me - Sure hubot will remember you.

module.exports = (robot) ->
  robot.respond /explain unstable builds/i, (msg) ->
    msg.send "Here's the canonical guide to whatever just got asked. Enjoy: https://gist.github.com/hakusaro/8bbbf1d532c06fa39bef8ee6b4602324"

  robot.respond /explain unstable builds to (.*)/, (msg) ->
    msg.send "#{msg.match[1]}, read this: https://gist.github.com/hakusaro/8bbbf1d532c06fa39bef8ee6b4602324"

  robot.respond /remember me/, (msg) ->
    msg.send "I won't be remembering anybody today."

  robot.respond /explain backseat moderation/, (msg) ->
    msg.send "The process by which someone attempts to tell a moderator or a leader of a community to change how they're operating to be more compliant with the 'rules' they think it's their job to enforce. Also, the behavior of someone to take action on rules or guidelines without having the power to enforce them in the first place."