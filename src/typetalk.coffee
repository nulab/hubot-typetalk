HTTPS          = require 'https'
Request        = require 'request'
{EventEmitter} = require 'events'
Package        = require '../package'
Hubot          = require 'hubot'

class Typetalk extends Hubot.Adapter
  # override
  send: (envelope, strings...) ->
    for string in strings
      @bot.Topic(envelope.room).create string, {}, (err, data) =>
        @robot.logger.error "Typetalk send error: #{err}" if err?

  # override
  run: ->
    options =
      clientId: process.env.HUBOT_TYPETALK_CLIENT_ID
      clientSecret: process.env.HUBOT_TYPETALK_CLIENT_SECRET
      rooms: process.env.HUBOT_TYPETALK_ROOMS
      apiRate: process.env.HUBOT_TYPETALK_API_RATE

    bot = new TypetalkStreaming(options, @robot)
    @bot = bot

    @emit 'connected'

exports.use = (robot) ->
  new Typetalk robot

class TypetalkStreaming extends EventEmitter
  constructor: (options, @robot) ->
    unless options.clientId? and options.clientSecret? \
        and options.rooms? and options.apiRate?
      @robot.logger.error \
        'Not enough parameters provided. ' \
        + 'Please set client id, client secret, rooms and API rate'
      process.exit 1

    @clientId = options.clientId
    @clientSecret = options.clientSecret
    @rooms = options.rooms.split ','
    @rate = parseInt options.apiRate, 10
    @host = 'typetalk.in'

    unless @rate > 0
      @robot.logger.error 'API rate must be greater then 0'
      process.exit 1

  Topics: (callback) ->
    @get '/topics', "", callback

  Topic: (id) ->
    get: (opts, callback) =>
      @get "/topics/#{id}", "", callback

    create: (message, opts, callback) =>
      data =
        message: message
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

    Request.post options, (err, res, body) =>
      if err
        logger.error "Typetalk HTTPS response error: #{err}"
        if callback
          callback err, {}

      if res.statusCode >= 400
        switch res.statusCode
          when 401
            throw new Error "Invalid access token provided"
          else
            logger.error "Typetalk HTTPS status code: #{res.statusCode}"
            logger.error "Typetalk HTTPS response body:"
            logger.error body
            json = try JSON.parse body catch e then body or {}
            logger.error json

      json = try JSON.parse body catch e then body or {}
      @accessToken = json.access_token
      @refreshToken = json.refresh_token

      if callback
        callback null, json

  request: (method, path, body, callback) ->
    logger = @robot.logger

    @updateAccessToken (err, data) =>
      options =
        url: "https://#{@host}/api/v1#{path}"
        method: method
        headers:
          Authorization: "Bearer #{@accessToken}"

      if method is 'POST'
        options.form = body
      else
        options.body = body

      Request options, (err, res, body) ->
        if err
          logger.error "Typetalk HTTPS response error: #{err}"
          if callback
            callback err, {}

        if res.statusCode >= 400
          switch res.statusCode
            when 401
              throw new Error "Invalid access token provided"
            else
              logger.error "Typetalk HTTPS status code: #{res.statusCode}"
              logger.error "Typetalk HTTPS response body:"
              logger.error body
              json = try JSON.parse body catch e then body or {}
              logger.error json

        if callback
          json = try JSON.parse body catch e then body or {}
          callback null, json

