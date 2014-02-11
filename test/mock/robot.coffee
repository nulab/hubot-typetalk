{Robot} = require 'hubot'

class RobotMock extends Robot
  loadAdapter: (Adapter) ->
    @adapter = Adapter.use this

module.exports = RobotMock

