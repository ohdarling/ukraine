#!/usr/bin/env coffee
fs      = require 'fs'
winston = require 'winston'
request = require 'request'
Q       = require 'q'

# This is where this user stores their auth token.
CONFIG_PATH = process.env.HOME + '/.chernobyl'

api_request = (host, method, path, data, callback) ->
    # Load host config
    user_config = {}
    if fs.existsSync CONFIG_PATH then user_config = JSON.parse fs.readFileSync CONFIG_PATH
    host_config = if user_config[host]? then user_config[host] else {}
    
    # Format url
    scheme = if (host_config.https in ['true', '1', 'yes']) then 'https' else 'http'
    haibu_port = if host_config.haibu_port? then host_config.haibu_port else '9002'
    url = "#{scheme}://#{host}:#{haibu_port}/#{path}"
    
    # Send request
    params = 
        'url': url
        'headers':
            'x-auth-token': host_config.auth_token
    if data? then params['data'] = data
    request[method] params, callback
    
exports.get = (host, path, callback) ->
    api_request host, 'get', path, null, callback
    
exports.post = (host, path, callback) ->
    api_request host, 'post', path, null, callback
    
exports.post_data = (host, path, data, callback) ->
    api_request host, 'post', path, data, callback