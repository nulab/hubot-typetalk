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

  it('occurs an error without invalit room id', () => {
    expect(() => {
      /* eslint-disable-next-line no-new */
      new TypetalkStreaming({
        clientId: 'DUMMYCLIENTID',
        clientSecret: 'DUMMYCLIENTSECRET',
        rooms: '-1',
        streamingURL: 'ws://localhost:8080',
      });
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
        streamingURL: 'ws://localhost:8080',
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
        .get('/api/v1/profile')
        .reply(200, Fixture.profile)
        .post('/api/v1/topics/12345', { message: 'Hello, world!' })
        .reply(200, '{}')
        .post('/api/v1/topics/23456')
        .reply(401)
        .post('/api/v1/topics/34567')
        .reply(200, '{{{')
        .post('/api/v1/topics/45678')
        .replyWithError('something happened');
    });

    it('should be a function', () => {
      expect(this.ts.postMessage).to.be.a('function');
    });

    it('should post message', () => {
      this.ts.accessToken = 'DUMMYACCESSTOKEN';
      this.ts.postMessage('12345', 'Hello, world!', {}, (err, data) => {
        expect(err).to.equal(null);
        expect(data).to.deep.equal({});
      });
    });

    it('receives unauthorized', () => {
      this.ts.postMessage('23456', 'Hello, world!', {}, (err) => {
        expect(err).to.be.instanceOf(Error);
      });
    });

    it('receives invalid json', () => {
      this.ts.postMessage('34567', 'Hello, world!', {}, (err) => {
        expect(err).to.be.instanceOf(SyntaxError);
      });
    });

    it('receives error response', () => {
      this.ts.postMessage('45678', 'Hello, world!', {}, (err) => {
        expect(err).to.be.instanceOf(Error);
      });
    });
  });

  describe('updateAccessToken', () => {
    beforeEach(() => {
      mockery.enable({
        warnOnReplace: false,
        warnOnUnregistered: false,
      });
      nock('https://typetalk.com')
        .post('/oauth2/access_token', {
          client_id: 'VALIDCLIENTID',
          client_secret: 'VALIDCLIENTSECRET',
          grant_type: 'client_credentials',
          scope: 'my,topic.read,topic.post',
        })
        .reply(200, Fixture.oauth2);
      nock('https://typetalk.com')
        .post('/oauth2/access_token', {
          client_id: 'INVALIDCLIENTID',
          client_secret: 'INVALIDCLIENTSECRET',
          grant_type: 'client_credentials',
          scope: 'my,topic.read,topic.post',
        })
        .reply(400);
    });

    it('should be a function', () => {
      const robot = new Robot(null, 'typetalk');
      const ts = new TypetalkStreaming({
        clientId: 'DUMMYCLIENTID',
        clientSecret: 'DUMMYCLIENTSECRET',
        rooms: '12345',
      }, robot);
      expect(ts.updateAccessToken).to.be.a('function');
    });

    it('receives access token', () => {
      const robot = new Robot(null, 'typetalk');
      const ts = new TypetalkStreaming({
        clientId: 'VALIDCLIENTID',
        clientSecret: 'VALIDCLIENTSECRET',
        rooms: '12345',
      }, robot);
      ts.updateAccessToken((err, data) => {
        expect(data).to.deep.equal(Fixture.oauth2);
      });
    });

    it('receives bad request', () => {
      const robot = new Robot(null, 'typetalk');
      const ts = new TypetalkStreaming({
        clientId: 'INVALIDCLIENTID',
        clientSecret: 'INVALIDCLIENTSECRET',
        rooms: '12345',
      }, robot);
      ts.updateAccessToken((err) => {
        expect(err).to.be.instanceOf(Error);
      });
    });
  });
});
