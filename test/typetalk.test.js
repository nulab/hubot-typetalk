const { expect } = require('chai');
const mockery = require('mockery');
const { Robot } = require('hubot');
const Typetalk = require('../lib/typetalk');

mockery.registerMock('hubot-typetalk', Typetalk);

describe('Typetalk', () => {
  beforeEach(() => {
    mockery.enable({
      warnOnUnregistered: false,
    });
    this.robot = new Robot(null, 'typetalk');
    this.adapter = this.robot.adapter;
  });

  afterEach(() => {
    mockery.disable();
    this.robot.shutdown();
  });

  it('assigns robot', () => {
    expect(this.adapter.robot).to.equal(this.robot);
  });

  describe('send', () => {
    it('is a function', () => {
      expect(this.adapter.send).to.be.a('function');
    });
  });

  describe('reply', () => {
    it('is a function', () => {
      expect(this.adapter.reply).to.be.a('function');
    });
  });

  describe('run', () => {
    it('is a function', () => {
      expect(this.adapter.run).to.be.a('function');
    });
  });
});
