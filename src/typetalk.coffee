HTTPS          = require 'https'
Request        = require 'request'
{EventEmitter} = require 'events'
Package        = require '../package'
Hubot          = require 'hubot'
Querystring    = require 'querystring'

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
      apiRate: process.env.HUBOT_TYPETALK_API_RATE

    bot = new TypetalkStreaming options, @robot
    @bot = bot

    bot.on 'message', (roomId, id, account, body) =>
      return if account.id is bot.info.account.id

      user = @robot.brain.userForId account.id,
        name: account.name
        room: roomId
      message = new Hubot.TextMessage user, body, id
      @receive message

    bot.Profile (err, data) ->
      bot.info = data
      bot.name = bot.info.account.name

      for roomId in bot.rooms
        bot.Topic(roomId).listen()

    @emit 'connected'

exports.use = (robot) ->
  new Typetalk robot

class TypetalkStreaming extends EventEmitter
  constructor: (options, @robot) ->
    unless options.clientId? and options.clientSecret? and \
        options.rooms? and options.apiRate?
      @robot.logger.error \
        'Not enough parameters provided. ' \
        + 'Please set client id, client secret and rooms'
      process.exit 1

    @clientId = options.clientId
    @clientSecret = options.clientSecret
    @rooms = options.rooms.split ','
    @host = 'typetalk.in'
    @rate = parseInt options.apiRate, 10

    unless @rate > 0
      @robot.logger.error 'API rate must be greater then 0'
      process.exit 1

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
      data = opts
      data.message = message
      @post "/topics/#{id}", data, callback

    listen: =>
      lastPostId = 0
      setInterval =>
        opts =
          if lastPostId is 0
            {}
          else
            from: lastPostId
            direction: 'forward'
            count: 100

        @Topic(id).get opts, (err, data) =>
          for post in data.posts
            continue unless lastPostId < post.id

            lastPostId = post.id
            @emit 'message',
              id,
              post.id,
              post.account,
              post.message

      , 1000 / (@rate / (60 * 60))

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

        if res.statusCode >= 400
          @updateAccessToken req

        if callback
          json = try JSON.parse body catch e then body or {}
          callback null, json

    if @accessToken
      req()
    else
      @updateAccessToken req

