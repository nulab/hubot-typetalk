{Robot} = require 'hubot'

class RobotMock extends Robot

  constructor: (Adapter) ->
    super null, Adapter

  loadAdapter: (Adapter) ->
    @adapter = Adapter.use this

module.exports = RobotMock
