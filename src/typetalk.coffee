HTTPS          = require 'https'
Request        = require 'request'
{EventEmitter} = require 'events'
Package        = require '../package'
Hubot          = require.main.require 'hubot'
Querystring    = require 'querystring'
_              = require 'underscore'
WebSocket      = require 'ws'

class Typetalk extends Hubot.Adapter
  # override
  send: (envelope, strings...) ->
    for string in strings
      option =
        if envelope.is_reply
          replyTo: envelope.message.id
        else
          {}
      @bot.Topic(envelope.room).create string, option, (err, data) =>
        @robot.logger.error "Typetalk send error: #{err}" if err?

  # override
  reply: (envelope, strings...) ->
    envelope.is_reply = true
    @send envelope, strings.map((str) -> "@#{envelope.user.name} #{str}")...

  # override
  run: ->
    options =
      clientId: process.env.HUBOT_TYPETALK_CLIENT_ID
      clientSecret: process.env.HUBOT_TYPETALK_CLIENT_SECRET
      rooms: process.env.HUBOT_TYPETALK_ROOMS
      autoReconnect: if process.env.HUBOT_TYPETALK_AUTO_RECONNECT == "false" then false else true
      streaming_url: process.env.HUBOT_TYPETALK_STREAMING_URL

    bot = new TypetalkStreaming options, @robot
    @bot = bot

    bot.on 'message', (roomId, id, account, body) =>
      return if account.id is bot.info.account.id

      user = @robot.brain.userForId account.id,
        name: account.name
        room: roomId
      @receive new Hubot.TextMessage user, body, id

    bot.Profile (err, data) ->
      bot.info = data
      bot.name = bot.info.account.name
      bot.listen()

    @emit 'connected'

exports.use = (robot) ->
  new Typetalk robot

class TypetalkStreaming extends EventEmitter
  constructor: (options, @robot) ->
    unless options.clientId? and options.clientSecret? and options.rooms?
      @robot.logger.error \
        'Not enough parameters provided. ' \
        + 'Please set client id, client secret and rooms'
      process.exit 1

    @clientId = options.clientId
    @clientSecret = options.clientSecret
    @rooms = options.rooms.split ','
    @autoReconnect = options.autoReconnect
    @streaming_url = options.streaming_url
    @host = 'typetalk.com'
    @msg_host = 'message.typetalk.com'

    for roomId in @rooms
      unless roomId.length > 0 and parseInt(roomId) > 0
        @robot.logger.error 'Room id must be greater than 0'
        process.exit 1

  listen: =>
    setupWebSocket = () =>
      ws = new WebSocket @streaming_url || "https://#{@msg_host}/api/v1/streaming",
                           headers:
                             'Authorization'         : "Bearer #{@accessToken}"
                             'User-Agent'            : "#{Package.name} v#{Package.version}"
      connected = false

      ws.on 'open', () =>
        connected = true
        clearInterval timerId
        timerId = setInterval =>
          ws.ping 'ping'
        , 1000 * 10 * 15
        @robot.logger.info "Typetalk WebSocket connected"

      ws.on 'error', (event) =>
        @robot.logger.error "Typetalk WebSocket error: #{event}"
        if not connected and @autoReconnect
          @robot.logger.info "Typetalk WebSocket try to reconnect"
          setTimeout ->
            setupWebSocket()
          , 30000

      ws.on 'pong', (data, flags) =>
        @robot.logger.debug "pong"

      ws.on 'close', (code, message) =>
        connected = false
        @robot.logger.info "Typetalk WebSocket disconnected: code=#{code}, message=#{message}"
        if @autoReconnect
          @robot.logger.info "Typetalk WebSocket try to reconnect"
          setTimeout ->
            setupWebSocket()
          , 30000

      ws.on 'message', (data, flags) =>
        event = try JSON.parse data catch e then data or {}
        if event.type == 'postMessage'
          topic = event.data.topic
          post = event.data.post
          if topic.id+"" in @rooms
            @emit 'message',
                   topic.id,
                   post.id,
                   post.account,
                   post.message

    setupWebSocket()
    return

  Profile: (callback) ->
    @get '/profile', '', callback

  Topics: (callback) ->
    @get '/topics', '', callback

  Topic: (id) ->
    get: (opts, callback) =>
      params = Querystring.stringify opts
      params = "?#{params}" if params
      path = "/topics/#{id}#{params}"
      @get path, '', callback

    create: (message, opts, callback) =>
      data = _.clone opts
      data.message = message
      @post "/topics/#{id}", data, callback

  get: (path, body, callback) ->
    @request "GET", path, body, callback

  post: (path, body, callback) ->
    @request "POST", path, body, callback

  put: (path, body, callback) ->
    @request "PUT", path, body, callback

  delete: (path, body, callback) ->
    @request "DELETE", path, body, callback

  updateAccessToken: (callback) ->
    logger = @robot.logger

    options =
      url: "https://#{@host}/oauth2/access_token"
      form:
        client_id: @clientId
        client_secret: @clientSecret
        grant_type: 'client_credentials'
        scope: 'my,topic.read,topic.post'
      headers:
        'User-Agent': "#{Package.name} v#{Package.version}"

    Request.post options, (err, res, body) =>
      if err
        logger.error "Typetalk HTTPS response error: #{err}"
        callback err, {} if callback
        return

      if res.statusCode >= 400
        throw new Error "Typetalk API returned unexpected status code: " \
          + "#{res.statusCode}"

      json = try JSON.parse body catch e then body or {}
      @accessToken = json.access_token
      @refreshToken = json.refresh_token

      callback null, json if callback

  request: (method, path, body, callback) ->
    logger = @robot.logger

    req = (err, data) =>
      options =
        url: "https://#{@host}/api/v1#{path}"
        method: method
        headers:
          Authorization: "Bearer #{@accessToken}"
          'User-Agent': "#{Package.name} v#{Package.version}"

      if method is 'POST'
        options.form = body
      else
        options.body = body

      Request options, (err, res, body) =>
        if err
          logger.error "Typetalk response error: #{err}"
          callback err, {} if callback
          return

        if res.statusCode == 401
          @updateAccessToken req

        if callback
          json = try JSON.parse body catch e then body or {}
          callback null, json

    if @accessToken
      req()
    else
      @updateAccessToken req
