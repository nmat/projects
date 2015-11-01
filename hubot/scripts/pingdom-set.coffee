# Description
#   Pingdom API set script.
#
# Configuration:
#   HUBOT_PINGDOM_USERNAME
#   HUBOT_PINGDOM_PASSWORD
#   HUBOT_PINGDOM_API
#
# Commands:
#   hubot pingdom set all <shortname> <paused|unpaused> - Pingdom set the service "shortname" to "state"
#   hubot pingdom set checkid <checkid> <pause|unpause> - Pingdom set the service "shortname" to "state"
#
# Examples:
#   hubot pingdom set all service paused - Will set the "service" to "pause"
#   hubot pingdom set all service pause - Same as above
#   hubot pingdom set all service unpause - Will remove the "pause" of "service"
#   hubot pingdom set checkid 12345 pause - Will pause checkid "12345"
#   hubot pingdom set checkid 12345 unpause - Will unpause checkid "12345"
#
# Tags:
#   pingdom,operations,admin
#
# Notes:
#   This script is based on pingdom.coffee located on github.
#   Please give the authors some credit for those script or this wouldn't exist at all.
#
#   https://github.com/cosm/hubot/blob/master/scripts/pingdom.coffee
#
#   Remove the Tags: and Examples: if you are not using advanced help hubot script
#
#   TODO: Should refactor code a bit at the moment its really ugly
#
# Author:
#   Niklas M <nmat@users.noreply.github.com>

# Set the apropriate variables in system
username = process.env.HUBOT_PINGDOM_USERNAME
password = process.env.HUBOT_PINGDOM_PASSWORD
app_key = process.env.HUBOT_PINGDOM_APP_KEY

class PingdomClient
  constructor: (@username, @password, @app_key) ->

  # Lets write the functions below:
  pingdomsetall: (msg, shortname, state) ->
    my = this
    filter = "#{shortname}"

    # Set the data for sending to pingdom api
    if "#{state}" is "pause" or "#{state}" is "paused"
      data = 'paused=true'
    else if "#{state}" is "unpause" or "#{state}" is "unpaused"
      data = 'paused=false'
    else
      msg.send "Script error: I don't recognize state: #{state}"

    my.request msg, 'checks', (response) ->
      if response.checks.length > 0
        lines = ["*Pingdom info:* I will now #{state} the following checks:"]
        for check in response.checks
          if check.name.match(filter.toLowerCase()) or check.name.match(filter.toUpperCase())
            my.requestput msg, "checks/#{check.id}", data, (response) ->
            lines.push ">Setting #{check.name}: CheckID: #{check.id} to #{state}"
        msg.send lines.join('\n')
      else
        msg.send "*Pingdom info:* Couldn't find any checks for #{@filter}"

  # Per checkid set
  pingdomsetcheckid: (msg, checkid, state) ->
    my = this

    # Set the data for sending to pingdom api
    if "#{state}" is "pause" or "#{state}" is "paused"
      data = 'paused=true'
    else if "#{state}" is "unpause" or "#{state}" is "unpaused"
      data = 'paused=false'
    else
      msg.send "Script error: I don't recognize state: #{state}"

    my.request msg, 'checks', (response) ->
      if response.checks.length > 0
        lines = ["*Pingdom info:* I will now #{state} the following check:"]
        for check in response.checks
          if "#{check.id}" == "#{checkid}"
            my.requestput msg, "checks/#{check.id}", data, (response) ->
            lines.push ">Setting #{check.name}: CheckID: #{check.id} to #{state}"
        msg.send lines.join('\n')
      else
        msg.send "*Pingdom info:* Couldn't find any checks for #{checkid}"

  # Connection info to post to API goes here
  requestput: (msg, url, data, handler) ->
    auth = new Buffer("#{@username}:#{@password}").toString('base64')
    pingdom_url = "https://api.pingdom.com/api/2.0"
    msg.http("#{pingdom_url}/#{url}")
      .headers(Authorization: "Basic #{auth}", 'App-key': @app_key)
      .put(data) (err, res, body) ->
        if err
          msg.send "*Pingdom Error:* #{err}"
          return
        content = JSON.parse(body)
        if content.error
          msg.send "*Pingdom Error:* #{content.error.statuscode} #{content.error.errormessage}"
          return
        handler content

  # Connection info to fetch from API goes here
  request: (msg, url, handler) ->
    auth = new Buffer("#{@username}:#{@password}").toString('base64')
    pingdom_url = "https://api.pingdom.com/api/2.0"
    msg.http("#{pingdom_url}/#{url}")
      .headers(Authorization: "Basic #{auth}", 'App-key': @app_key)
      .get() (err, res, body) ->
        if err
          msg.send "*PINGDOM ERROR*: #{err}"
          return
        content = JSON.parse(body)
        if content.error
          msg.send "*PINGDOM ERROR*: #{content.error.statuscode} #{content.error.errormessage}"
          return
        handler content

client = new PingdomClient(username, password, app_key)

# Bot command input
module.exports = (robot) ->
  robot.respond /pingdom set all (.*) (pause|paused|unpause|unpaused)$/i, (msg) ->
    shortname = msg.match[1].toLowerCase()
    state = msg.match[2].toLowerCase()
    client.pingdomsetall(msg,shortname,state)

  robot.respond /pingdom set checkid (.*) (pause|paused|unpause|unpaused)$/i, (msg) ->
    checkid = parseInt(msg.match[1])
    state = msg.match[2].toLowerCase()
    client.pingdomsetcheckid(msg,checkid,state)
