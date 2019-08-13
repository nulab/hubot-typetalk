should = (require 'chai').should()
mockery = require 'mockery'
nock = require 'nock'

Adapter = require '../src/typetalk'
Fixture = require './fixtures'
{Robot} = require 'hubot'
Querystring = require 'querystring'
Url = require 'url'

clientId = 'deadbeef'
clientSecret = 'deadbeef'
topicId = '1'
process.env.HUBOT_TYPETALK_CLIENT_ID = clientId
process.env.HUBOT_TYPETALK_CLIENT_SECRET = clientSecret
process.env.HUBOT_TYPETALK_ROOMS = topicId
process.env.HUBOT_TYPETALK_AUTO_RECONNECT = "false"
process.env.HUBOT_TYPETALK_STREAMING_URL = "http://localhost:8080"
process.env.HUBOT_LOG_LEVEL = "alert"

host = 'https://typetalk.com'

describe 'Typetalk', ->
  robot = null
  adapter = null

  beforeEach ->
    (nock 'https://typetalk.com')
      .post("/oauth2/access_token")
      .reply 200, Fixture.oauth2.access_token
    (nock 'https://typetalk.com')
      .get("/api/v1/profile")
      .reply 200, Fixture.profile.get

    mockery.enable {
      warnOnReplace: false,
      warnOnUnregistered: false
    }

    mockery.registerMock 'hubot-typetalk', Adapter

    robot = new Robot null, 'typetalk'
    adapter = robot.adapter

  afterEach ->
    mockery.disable
    robot.shutdown()

  describe '#run', ->
    it 'should emmit on connected', (done) ->
      adapter.on 'connected', done
      robot.run()

    it 'should set a bot', ->
      robot.run()
      adapter.should.have.a.property 'bot'

describe 'TypetalkStreaming', ->
  robot = null
  adapter = null
  bot = null

  beforeEach ->
    (nock 'https://typetalk.com')
      .post("/oauth2/access_token")
      .reply 200, Fixture.oauth2.access_token
    (nock 'https://typetalk.com')
      .get("/api/v1/profile")
      .reply 200, Fixture.profile.get

    mockery.enable {
      warnOnReplace: false,
      warnOnUnregistered: false
    }

    mockery.registerMock 'hubot-typetalk', Adapter

    robot = new Robot null, 'typetalk'
    adapter = robot.adapter

    robot.run()
    bot = adapter.bot

  afterEach ->
    mockery.disable()
    robot.shutdown()

  describe '#constructor', ->
    it 'should have configs from environment variables', ->
      bot.clientId.should.be.equal clientId
      bot.clientSecret.should.be.equal clientSecret
      bot.rooms.should.be.deep.equal [topicId]

    it 'should have host', ->
      bot.should.have.a.property 'host'

  describe '#Profile', ->
    it 'should get profile', (done) ->
      (nock 'https://typetalk.com')
        .post("/oauth2/access_token")
        .reply 200, Fixture.oauth2.access_token
      (nock 'https://typetalk.com')
        .get('/api/v1/profile')
        .reply 200, Fixture.profile.get

      bot.Profile (err, data) ->
        data.should.be.deep.equal Fixture.profile.get
        done()

  describe '#Topics', ->
    it 'should get topics', (done) ->
      (nock 'https://typetalk.com')
        .post("/oauth2/access_token")
        .reply 200, Fixture.oauth2.access_token
      (nock 'https://typetalk.com')
        .get('/api/v1/topics')
        .reply 200, Fixture.topics.get

      bot.Topics (err, data) ->
        data.should.be.deep.equal Fixture.topics.get
        done()

  describe '#Topic', ->
    topic = null

    beforeEach ->
      (nock 'https://typetalk.com')
        .post("/oauth2/access_token")
        .reply 200, Fixture.oauth2.access_token
      topic = bot.Topic topicId

    it 'should get topic messages', (done) ->
      opts =
        from: '1234'
        count: '100'

      (nock 'https://typetalk.com')
        .filteringPath(/\?.*/g, '')
        .get("/api/v1/topics/#{topicId}")
        .reply 200, (url, body) ->
          query = Querystring.parse (Url.parse url).query
          query.from.should.be.equal opts.from
          query.count.should.be.equal opts.count
          Fixture.topic.get

      topic.get opts, (err, data) ->
        data.should.be.deep.equal Fixture.topic.get
        done()

    it 'should create a message to the topic', (done) ->
      message = 'test'
      opts =
        replyTo: '1234'

      (nock 'https://typetalk.com')
        .post("/api/v1/topics/#{topicId}")
        .reply 200, (url, body) ->
          query = Querystring.parse body
          query.message.should.be.equal message
          delete query.message
          query.replyTo.should.be.equal opts.replyTo
          Fixture.topic.post

      topic.create message, opts, (err, data) ->
        data.should.be.deep.equal Fixture.topic.post
        done()
