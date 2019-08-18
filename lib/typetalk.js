const Adapter = require.main.require('hubot/src/adapter');
const { TextMessage } = require.main.require('hubot/src/message');

const TypetalkStreaming = require('./typetalk-streaming');

class Typetalk extends Adapter {
  send(envelope, ...strings) {
    strings.forEach((string) => {
      const option = envelope.is_reply ? { replyTo: envelope.message.id } : {};
      this.bot.postMessage(envelope.room, string, option, (err) => {
        if (err) {
          this.robot.logger.error(`Typetalk send error: ${err}`);
        }
      });
    });
  }

  reply(_envelope, ...strings) {
    const envelope = _envelope;
    envelope.is_reply = true;
    this.send(envelope, ...strings.map((string) => `@${envelope.user.name} ${string}`));
  }

  run() {
    const options = {
      clientId: process.env.HUBOT_TYPETALK_CLIENT_ID,
      clientSecret: process.env.HUBOT_TYPETALK_CLIENT_SECRET,
      rooms: process.env.HUBOT_TYPETALK_ROOMS,
      autoReconnect: process.env.HUBOT_TYPETALK_AUTO_RECONNECT !== 'false',
      streamingURL: process.env.HUBOT_TYPETALK_STREAMING_URL,
    };

    const bot = new TypetalkStreaming(options, this.robot);
    this.bot = bot;

    bot.on('message', (roomId, id, account, body) => {
      if (account.id === bot.info.account.id) {
        return;
      }

      const user = this.robot.brain.userForId(account.id, {
        name: account.name,
        room: roomId,
      });

      const textMessage = new TextMessage(user, body, id);
      this.receive(textMessage);
    });

    bot.getProfile((err, data) => {
      bot.info = data;
      bot.name = bot.info.account.name;
      bot.listen();
    });

    this.emit('connected');
  }
}

exports.use = (robot) => new Typetalk(robot);
