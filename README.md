hubot-typetalk
==============

A Hubot adapter for typetalk.

[![Build Status](https://travis-ci.org/nulab/hubot-typetalk.png?branch=master)](https://travis-ci.org/nulab/hubot-typetalk)
[![Coverage Status](https://coveralls.io/repos/nulab/hubot-typetalk/badge.png?branch=master)](https://coveralls.io/r/nulab/hubot-typetalk?branch=master)
[![NPM version](https://badge.fury.io/js/hubot-typetalk.png)](http://badge.fury.io/js/hubot-typetalk)

## Installation

1. Add `hubot-typetalk` to dependencies in your hubot's `package.json`.
  ```javascript
"dependencies": {
    "hubot-typetalk": "0.1.0"
}
  ```

2. Install `hubot-typetalk`.
  ```sh
npm install
  ```

3. Setup your hubot.
  ```sh
export HUBOT_TYPETALK_CLIENT_ID='DEADBEEF'     # see http://developer.nulab-inc.com/docs/typetalk/auth#client
export HUBOT_TYPETALK_CLIENT_SECRET='FACEFEED'
export HUBOT_TYPETALK_ROOMS='2321,2684'        # comma separated
  ```

4. Run hubot with typetalk adapter.
  ```sh
bin/hubot -a typetalk
  ```

## License

The MIT License. See `LICENSE` file.
