const { expect } = require('chai');
const mockery = require('mockery');
const nock = require('nock');
const { Robot } = require('hubot');
const Fixture = require('./fixtures');
const Typetalk = require('../lib/typetalk');
const TypetalkStreaming = require('../lib/typetalk-streaming');

mockery.registerMock('hubot-typetalk', Typetalk);
process.env.HUBOT_LOG_LEVEL = 'alert';

describe('TypetalkStreaming', () => {
  it('occurs an error without enough params', () => {
    expect(() => {
      /* eslint-disable-next-line no-new */
      new TypetalkStreaming();
    }).to.throw();
  });

  describe('listen', () => {
    beforeEach(() => {
      mockery.enable({
        warnOnReplace: false,
        warnOnUnregistered: false,
      });
      const robot = new Robot(null, 'typetalk');
      this.ts = new TypetalkStreaming({
        clientId: 'DUMMYCLIENTID',
        clientSecret: 'DUMMYCLIENTSECRET',
        rooms: '12345',
        streamingURL: 'http://localhost:8080',
      }, robot);
    });

    it('should be a function', () => {
      expect(this.ts.listen).to.be.a('function');
    });

    it('does nothing without streaming', () => {
      this.ts.listen();
    });
  });

  describe('getProfile', () => {
    beforeEach(() => {
      mockery.enable({
        warnOnReplace: false,
        warnOnUnregistered: false,
      });
      const robot = new Robot(null, 'typetalk');
      this.ts = new TypetalkStreaming({
        clientId: 'DUMMYCLIENTID',
        clientSecret: 'DUMMYCLIENTSECRET',
        rooms: '12345',
      }, robot);
      nock('https://typetalk.com')
        .post('/oauth2/access_token')
        .reply(200, Fixture.oauth2);
      nock('https://typetalk.com')
        .get('/api/v1/profile')
        .reply(200, Fixture.profile);
    });

    it('should be a function', () => {
      expect(this.ts.getProfile).to.be.a('function');
    });

    it('should get profile', () => {
      this.ts.getProfile((err, data) => {
        expect(data).deep.equal(Fixture.profile);
      });
    });
  });

  describe('postMessage', () => {
    beforeEach(() => {
      mockery.enable({
        warnOnReplace: false,
        warnOnUnregistered: false,
      });
      const robot = new Robot(null, 'typetalk');
      this.ts = new TypetalkStreaming({
        clientId: 'DUMMYCLIENTID',
        clientSecret: 'DUMMYCLIENTSECRET',
        rooms: '12345',
      }, robot);
      nock('https://typetalk.com')
        .post('/oauth2/access_token')
        .reply(200, Fixture.oauth2);
      nock('https://typetalk.com')
        .get('/api/v1/profile')
        .reply(200, Fixture.profile);
      nock('https://typetalk.com')
        .post('/api/v1/topics/12345')
        .reply(200, {});
    });

    it('should be a function', () => {
      expect(this.ts.postMessage).to.be.a('function');
    });

    it('should post message', () => {
      this.ts.postMessage('12345', 'Hello, world!', {}, (err, data) => {
        expect(data).to.deep.equal({});
      });
    });
  });

  describe('updateAccessToken', () => {
    beforeEach(() => {
      mockery.enable({
        warnOnReplace: false,
        warnOnUnregistered: false,
      });
      const robot = new Robot(null, 'typetalk');
      this.ts = new TypetalkStreaming({
        clientId: 'DUMMYCLIENTID',
        clientSecret: 'DUMMYCLIENTSECRET',
        rooms: '12345',
      }, robot);
      nock('https://typetalk.com')
        .post('/oauth2/access_token')
        .reply(200, Fixture.oauth2);
    });

    it('should be a function', () => {
      expect(this.ts.updateAccessToken).to.be.a('function');
    });

    it('should get access token', () => {
      this.ts.updateAccessToken((err, data) => {
        expect(data).deep.equal(Fixture.oauth2);
      });
    });
  });
});
