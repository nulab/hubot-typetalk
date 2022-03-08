const _ = require('underscore');
const { EventEmitter } = require('events');
const Request = require('request');
const WebSocket = require('ws');
const Package = require('../package.json');

class TypetalkStreaming extends EventEmitter {
  constructor(options, robot) {
    if (!options || !options.clientId || !options.clientSecret || !options.rooms) {
      const errMsg = 'Not enough parameters provided. Please set client id, client secret and rooms';
      throw new Error(errMsg);
    }

    super();

    this.clientId = options.clientId;
    this.clientSecret = options.clientSecret;
    this.rooms = options.rooms.split(',');
    this.autoReconnect = options.autoReconnect;
    this.hostname = options.hostname || 'typetalk.com';
    this.streamingURL = options.streamingURL || 'https://message.typetalk.com/api/v1/streaming';

    this.robot = robot;

    this.rooms.forEach((room) => {
      if (room.length <= 0 || parseInt(room, 10) <= 0) {
        const errMsg = 'Room id must be greater than 0';
        throw new Error(errMsg);
      }
    });
  }

  listen() {
    const setupWebSocket = () => {
      const ws = new WebSocket(this.streamingURL, {
        headers: {
          Authorization: `Bearer ${this.accessToken}`,
          'User-Agent': `${Package.name} v${Package.version}`,
        },
      });

      this.connected = false;

      ws.on('open', () => {
        this.connected = true;
        clearInterval(this.timerId);
        this.timerId = setInterval(() => {
          ws.ping('ping');
        }, 1000 * 30);
        this.robot.logger.info('Typetalk WebSocket connected');
      });

      ws.on('close', (code, message) => {
        this.connected = false;
        this.robot.logger.info(`Typetalk WebSocket disconnected: code=${code}, message=${message}`);
        if (this.autoReconnect) {
          this.robot.logger.info('Typetalk WebSocket try to reconnect');
          setTimeout(() => {
            setupWebSocket();
          }, 1000 * 30);
        }
      });

      ws.on('pong', () => {
        this.robot.logger.debug('pong');
      });

      ws.on('error', (event) => {
        this.robot.logger.error(`Typetalk WebSocket error: ${event}`);
        if (!this.connected && this.autoReconnect) {
          this.robot.logger.info('Typetalk WebSocket try to reconnect');
          setTimeout(() => {
            setupWebSocket();
          }, 1000 * 30);
        }
      });

      ws.on('message', (data) => {
        let event = {};
        try {
          event = JSON.parse(data);
        } catch (e) {
          return;
        }

        if (event.type === 'postMessage') {
          const { topic, post } = event.data;
          if (!topic.id || !this.rooms.includes(topic.id.toString())) {
            return;
          }
          this.emit('message', topic.id, post.id, post.account, post.message);
        }
      });
    };

    setupWebSocket();
  }

  getProfile(cb) {
    this.get('/profile', '', cb);
  }

  postMessage(topicId, message, opts, cb) {
    const data = _.clone(opts);
    data.message = message;
    this.post(`/topics/${topicId}`, data, cb);
  }

  get(path, body, cb) {
    this.request('GET', path, body, cb);
  }

  post(path, body, cb) {
    this.request('POST', path, body, cb);
  }

  updateAccessToken(cb) {
    const { logger } = this.robot;

    const options = {
      url: `https://${this.hostname}/oauth2/access_token`,
      form: {
        client_id: this.clientId,
        client_secret: this.clientSecret,
        grant_type: 'client_credentials',
        scope: 'my,topic.read,topic.post',
      },
      headers: {
        'User-Agent': `${Package.name} v${Package.version}`,
      },
    };

    Request.post(options, (err, res, body) => {
      if (err) {
        logger.error(`Typetalk HTTPS response error: ${err}`);
        if (cb) {
          cb(err, {});
        }
        return;
      }

      if (res.statusCode >= 400) {
        const errMsg = `Typetalk API returned unexpected status code: ${res.statusCode}`;
        logger.error(errMsg);
        if (cb) {
          cb(Error(errMsg), {});
        }
        return;
      }

      let json = {};
      try {
        json = JSON.parse(body);
      } catch (e) {
        if (cb) {
          cb(err, {});
        }
        return;
      }

      this.accessToken = json.access_token;
      this.refreshToken = json.refresh_token;

      if (cb) {
        cb(null, json);
      }
    });
  }

  request(method, path, requestBody, cb) {
    const { logger } = this.robot;

    const req = () => {
      const options = {
        url: `https://${this.hostname}/api/v1${path}`,
        method,
        headers: {
          Authorization: `Bearer ${this.accessToken}`,
          'User-Agent': `${Package.name} v${Package.version}`,
        },
      };

      if (method === 'POST') {
        options.form = requestBody;
      } else {
        options.body = requestBody;
      }

      Request(options, (errr, res, body) => {
        if (errr) {
          logger.error(`Typetalk response error: ${errr}`);
          if (cb) {
            cb(errr, {});
          }
          return;
        }

        if (res.statusCode === 401) {
          this.updateAccessToken(req);
        }

        if (cb) {
          let json = {};
          try {
            json = JSON.parse(body);
          } catch (errrr) {
            cb(errrr, {});
            return;
          }
          cb(null, json);
        }
      });
    };
    if (this.accessToken) {
      req();
    } else {
      this.updateAccessToken(req);
    }
  }
}

module.exports = TypetalkStreaming;
