brainLoaded = false
quotes = []

module.exports = (robot) ->
  scoreKeeper = null
  robot.brain.on 'loaded', ->
    if(brainLoaded)
      return
    brainLoaded = true
    quotes = robot.brain.get("quotes")
    if not quotes
      quotes = []
      robot.brain.save("quotes", quotes)

  robot.hear /quote add (.*)/i, (msg) ->
    quote = {who: msg.message.user['name'], quote: msg.match[1].trim()}
    quotes.push(quote)
    robot.brain.set("quotes", quotes)
    robot.brain.save()
    msg.send("Saved quote as quote #{quotes.length}.")

  robot.hear /quote read ([0-9]+)/i, (msg) ->
    quoteIndex = parseInt(msg.match[1])
    if quoteIndex > 0 and quoteIndex <= quotes.length
      quote = quotes[quoteIndex - 1]
      msg.send("#{quote.who}: #{quote.quote}")
    else
      msg.send("Invalid quote.")

  robot.hear /quote list/i, (msg) ->
    resp = ""
    for index of quotes
      resp += "#{quotes[index].who}: #{quotes[index].quote}\n"
    msg.send(resp)

  robot.hear /quote find (.*)/i, (msg) ->
    foundQuotes = []
    for index of quotes
      if quotes[index].quote.indexOf(msg.match[1]) isnt -1
        foundIndex = parseInt(index) + 1
        foundQuotes.push(foundIndex)
    if foundQuotes.length > 1
      msg.send("Found #{foundQuotes.length} quotes: #{foundQuotes.join()}.")
    else if foundQuotes.length > 0
      msg.send("Found one quote: #{foundQuotes[0]}.")
    else
      msg.send("Did not find any matches (potato).")
