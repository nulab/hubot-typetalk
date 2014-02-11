should = (require 'chai').should()
nock = require 'nock'

Adapter = require '../src/typetalk'
Fixture = require './Fixtures'
RobotMock = require './mock/robot'

clientId = 'deadbeef'
clientSecret = 'deadbeef'
topicId = '1'
process.env.HUBOT_TYPETALK_CLIENT_ID = clientId
process.env.HUBOT_TYPETALK_CLIENT_SECRET = clientSecret
process.env.HUBOT_TYPETALK_ROOMS = topicId

host = 'https://typetalk.in'

describe 'Typetalk', ->
  robot = null
  adapter = null

  beforeEach ->
    (nock 'https://typetalk.in')
      .post("/oauth2/access_token")
      .reply 200, Fixture.oauth2.access_token

    robot = new RobotMock Adapter
    adapter = robot.adapter

  afterEach ->
    nock.cleanAll()

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
    (nock 'https://typetalk.in')
      .post("/oauth2/access_token")
      .reply 200, Fixture.oauth2.access_token

    robot = new RobotMock Adapter
    adapter = robot.adapter

    robot.run()
    bot = adapter.bot

  afterEach ->
    nock.cleanAll()

  it 'should have configs from environment variables', ->
    bot.clientId.should.be.equal clientId
    bot.clientSecret.should.be.equal clientSecret
    bot.rooms.should.be.deep.equal [topicId]

  it 'should have host', ->
    bot.should.have.a.property 'host'

  describe '#Topics', ->
    it 'should get topics', (done) ->
      (nock 'https://typetalk.in')
        .get('/api/v1/topics')
        .reply 200, Fixture.topics.get

      bot.Topics (err, data) ->
        data.should.be.deep.equal Fixture.topics.get
        done()

  describe '#Topic', ->
    topic = null

    beforeEach ->
      topic = bot.Topic topicId

    it 'should get topic messages', (done) ->
      opts = {}
      (nock 'https://typetalk.in')
        .get("/api/v1/topics/#{topicId}")
        .reply 200, Fixture.topic.get

      topic.get opts, (err, data) ->
        data.should.be.deep.equal Fixture.topic.get
        done()

    it 'should create a message to the topic', (done) ->
      opts = {}
      message = 'test'
      (nock 'https://typetalk.in')
        .post("/api/v1/topics/#{topicId}")
        .reply 200, (url, body) ->
          body.should.be.equal "message=#{message}"
          Fixture.topic.post

      topic.create message, opts, (err, data) ->
        data.should.be.deep.equal Fixture.topic.post
        done()

