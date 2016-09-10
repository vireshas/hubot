{Robot, Adapter, TextMessage} = require 'hubot'
http                          = require 'http'
WebSocketServer               = require('ws').Server
HttpClient                    = require 'scoped-http-client'

PROXY_HOST = process.env.PROXY_HOST
PROXY_PORT = process.env.PROXY_PORT


class WebSocketAdapter extends Adapter

  send: (envelope, strings...) ->
    @wss.clients.forEach (client) =>
      client.send(JSON.stringify(strings))

  emote: (envelope, strings...) ->
    @send envelope, "* #{str}" for str in strings

  reply: (envelope, strings...) ->
    strings = strings.map (s) -> "#{envelope.user.name}: #{s}"
    @send envelope, strings...

  on_message: (e) =>
    e = JSON.parse e
    user = @robot.brain.userForId(e.user, {name: e.user, room: e.room})
    @receive new TextMessage(user, e.message, 'messageId')

  http: (url, options) ->
    client = HttpClient.create(url, options)
      .header('User-Agent', "Hubot/#{@version}")

    client.passthroughOptions.host = PROXY_HOST
    client.passthroughOptions.port = PROXY_PORT
    client

  run: ->
    # Hack robot to inject proxy settings
    if (PROXY_HOST)
      @robot.http = @http

    @wss = new WebSocketServer {port: 3000}
    @wss.on 'connection', (ws) =>
      ws.on 'message', @on_message

    @emit 'connected'

exports.use = (robot) ->
  new WebSocketAdapter robot

