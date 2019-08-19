hubot-typetalk
==============

A Hubot adapter for [Typetalk](http://www.typetalk.com/).

[![Build Status](https://travis-ci.org/nulab/hubot-typetalk.svg?branch=master)](https://travis-ci.org/nulab/hubot-typetalk)
[![Coverage Status](https://coveralls.io/repos/github/nulab/hubot-typetalk/badge.svg?branch=master)](https://coveralls.io/github/nulab/hubot-typetalk?branch=master)
[![NPM version](https://badge.fury.io/js/hubot-typetalk.svg)](http://badge.fury.io/js/hubot-typetalk)

## Usage

1. Install hubot-typetalk.
  ```sh
$ npm install -g yo generator-hubot
$ yo hubot --adapter typetalk
  ```

2. Set environment variables.
  ```sh
$ export HUBOT_TYPETALK_CLIENT_ID='DEADBEEF' # see https://developer.nulab.com/docs/typetalk/auth#client
$ export HUBOT_TYPETALK_CLIENT_SECRET='FACEFEED'
$ export HUBOT_TYPETALK_ROOMS='2321,2684' # comma separated
  ```

3. Run.
  ```sh
$ bin/hubot -a typetalk
  ```

## License

The MIT License. See `LICENSE` file.
