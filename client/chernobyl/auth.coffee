#!/usr/bin/env coffee
fs      = require 'fs'
winston = require 'winston'
request = require 'request'
Q       = require 'q'

haibu_api   = require './api.coffee'

task = exports

# This is where this user stores their auth token.
TOKEN_PATH = process.env.HOME + '/.chernobyl'

# CLI output on the default output.
winston.cli()

# The actual task.
task.auth = (ukraine_ip, auth_token, cfg) ->
    config = require './config.coffee'
    return config.config ukraine_ip, "auth_token=#{auth_token}", cfg
