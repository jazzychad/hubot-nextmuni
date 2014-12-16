# Description:
#   Get SF Muni bus arrival predictions
#
# Dependencies:
#   xml2js
#
# Configuration:
#   None
#
# Commands:
#   hubot muni stopid <line> - Get predictions for this stopid
#
# Author:
#   jazzychad
#   Chad Etzel

Parser = require('xml2js').Parser

module.exports = (robot) ->
  robot.respond /muni ([\d]+)[ ]?(.*)?/i, (msg) ->
    # msg.send "got it..."
    stop_id = msg.match[1]
    line = msg.match[2] or "*"
    msg.http("http://webservices.nextbus.com/service/publicXMLFeed?command=predictions&a=sf-muni&stopId=#{stop_id}")
      .get() (err, res, body) ->
        (new Parser()).parseString body, (err, json) ->
          if err
            msg.send "error occurred"
            return

          json = json.body

          if json.Error?
            msg.send "Unknown Muni stop_id or line number. Check your input?"
            return

          if (json.predictions not instanceof Array) and not json.predictions?.direction?
            msg.send "NextMuni is down :("
            return

          if not json.predictions.length?
            json.predictions = [json.predictions]

          response = ""

          for p in json.predictions
            response = ""
            route_title = p["$"].routeTitle #"rtitle"
            route_tag = p["$"].routeTag #"rtag"
            stop_title = p["$"].stopTitle #"stitle"

            if line isnt "*" and route_tag.toLowerCase() isnt line.toLowerCase()
              continue

            if p["$"].dirTitleBecauseNoPredictions?
              title = p["$"].dirTitleBecauseNoPredictions
              msg.send "#{route_title} - #{title} - #{stop_title} => No Prediction"
              continue

            for d in p.direction
              title = d["$"].title #"title"
              response += "#{route_title} - #{title} - #{stop_title} => "
              if not d.prediction.length?
                d.prediction = [d.prediction]
              minutes = [pred["$"].minutes for pred in d.prediction]
              response += minutes.join(", ") + " minutes"
              msg.send response
