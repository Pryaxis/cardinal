# Description:
#   Helps you help other people.
# Commands:
#   hubot explain unstable builds please - Gets you the canonical guide to TShock's unstable builds.
#   hubot explain unstable builds to <someone> - Tells person how to get TShock's unstable builds.
#   hubot remember me - Sure hubot will remember you.
#   hubot explain backseat moderation - Explains backseat moderation.
#   hubot explain the code of conduct - Explains the code of conduct.
#   hubot explain the catch-all - Explains the catch-all policy that makes it so the code of conduct works.

module.exports = (robot) ->
  robot.respond /explain unstable builds please/, (msg) ->
    msg.send "Here's the canonical guide to whatever just got asked. Enjoy: https://gist.github.com/hakusaro/8bbbf1d532c06fa39bef8ee6b4602324"

  robot.respond /explain unstable builds to (.*)/, (msg) ->
    msg.send "#{msg.match[1]}, read this: https://gist.github.com/hakusaro/8bbbf1d532c06fa39bef8ee6b4602324"

  robot.respond /remember me/, (msg) ->
    msg.send "I won't be remembering anybody today."

  robot.respond /explain backseat moderation/, (msg) ->
    msg.send "The process by which someone attempts to tell a moderator or a leader of a community to change how they're operating to be more compliant with the 'rules' they think it's their job to enforce. Also, the behavior of someone to take action on rules or guidelines without having the power to enforce them in the first place. Usually frowned upon."

  robot.respond /explain the code of conduct/, (msg) ->
    msg.send "By participating in the TShock for Terraria community, all members will adhere to maintaining decorum with respect to all humans, in and out of the community. Members will not engage in discussion that inappropriately disparages or marginalizes any group of people or any individual. Members will not attempt to further or advance an agenda to the point of being overbearing or close minded (such as through spreading FUD). Members will not abuse services provided to them and will follow the guidance of community leaders on a situational basis about what abuse consists of. Members will adhere to United States and international law. If members notice a violation of this code of conduct, they will not engage but will instead contact the leadership team on either the forums or Discord."

  robot.respond /explain the catch-all/, (msg) ->
    msg.send "Do not attempt to circumvent or bypass the code of conduct by using clever logic or reasoning (e.g. insulting Facepunch members, because they weren't directly mentioned here)."