should = (require 'chai').should()
nock = require 'nock'
Typetalk = require '../src/typetalk'
fixtures = require './fixtures'

clientId = 'deadbeef'
clientSecret = 'deadbeef'
topicId = '1'
apiRate = '3600'
process.env.HUBOT_TYPETALK_CLIENT_ID = clientId
process.env.HUBOT_TYPETALK_CLIENT_SECRET = clientSecret
process.env.HUBOT_TYPETALK_ROOMS = topicId
process.env.HUBOT_TYPETALK_API_RATE = apiRate

class LoggerMock
  error: (message) -> new Error message

class BrainMock
  userForId: (id, options) ->
    id: id
    user: options

class RobotMock
  constructor: ->
    @logger = new LoggerMock
    @brain = new BrainMock

  receive: ->

describe 'TypetalkStreaming', ->
  api = null
  robot = null
  bot = null

  beforeEach ->
    nock.cleanAll()
    api = (nock 'https://typetalk.in')
      .persist()
      .post("/oauth2/access_token")
      .reply 200, fixtures.oauth2.access_token

    robot = new RobotMock()
    typetalk = Typetalk.use robot
    typetalk.run()
    bot = typetalk.bot

  it 'should have configs from environment variables', ->
    bot.clientId.should.be.equal clientId
    bot.clientSecret.should.be.equal clientSecret
    bot.rooms.should.be.deep.equal [topicId]
    bot.rate.should.be.equal parseInt apiRate, 10

  it 'should have host', ->
    bot.should.have.property 'host'

  describe '#Topics', ->
    it 'should get topics', (done) ->
      api.get('/api/v1/topics').reply 200, fixtures.topics.get
      bot.Topics (err, data) ->
        data.should.be.deep.equal fixtures.topics.get
        done()

  describe '#Topic', ->
    topic = null
    baseUrl = "/api/v1/topics/#{topicId}"

    before ->
      topic = bot.Topic topicId

    it 'should get topic messages', (done) ->
      opts = {}
      api.get(baseUrl).reply 200, fixtures.topic.get
      topic.get opts, (err, data) ->
        data.should.be.deep.equal fixtures.topic.get
        done()

    it 'should create a message to the topic', (done) ->
      opts = {}
      message = 'test'
      api.post(baseUrl).reply 200, (url, body) ->
        body.should.be.equal "message=#{message}"
        fixtures.topic.post
      topic.create message, opts, (err, data) ->
        data.should.be.deep.equal fixtures.topic.post
        done()

