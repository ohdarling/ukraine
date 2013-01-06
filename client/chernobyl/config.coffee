#!/usr/bin/env coffee
fs      = require 'fs'
winston = require 'winston'
request = require 'request'
Q       = require 'q'

haibu_api   = require './haibu_api.coffee'

task = exports

# This is where this user stores their auth token.
CONFIG_PATH = process.env.HOME + '/.chernobyl'

# CLI output on the default output.
winston.cli()

# The actual task.
task.config = (ukraine_ip, key_value, cfg) ->
    
    # Checking config var format.
    return Q.fcall( ->
        winston.debug 'Checking the configuration format'

        key_value_pair = key_value.split('=')
        throw 'Needs to have delimiting = character' unless key_value.length > 1

        # Pop the key and value off.
        key = key_value_pair.reverse().pop()
        # Join on any extra equal signs.
        value = key_value_pair.reverse().join('=')
        
        [ key, value ]
        
    # Save to .chernobyl first
    ).when(
        ([ key, value ])->
            winston.debug 'Attempting to write into ' + '.chernobyl'.grey + ' file'

            # Does the file exist already?
            user_config = {}
            if fs.existsSync CONFIG_PATH then user_config = JSON.parse fs.readFileSync CONFIG_PATH

            # Convert original auth_token to host_config
            host_config = if user_config[ukraine_ip]? then user_config[ukraine_ip] else {}
            if host_config && typeof host_config != 'object'
                host_config = auth_token: host_config

            # Add or remove configuration
            if value is ''
                delete host_config[key]
            else
                host_config[key] = value
            
            user_config[ukraine_ip] = host_config

            # Write it, nicely.
            fs.writeFileSync CONFIG_PATH, JSON.stringify user_config, null, 4
        
    # Try to auth with ukraine.
    ).when(
        ->
            winston.debug 'Is ' + 'haibu'.grey + ' up and accepting our token?'

            def = Q.defer()
            
            haibu_api.get ukraine_ip, 'version'
            , (err, res, body) ->
                # Server down?
                if err then def.reject err
                # Bad token probably.
                else if res.statusCode isnt 200 then def.reject body
                # All good.
                else
                    winston.info (JSON.parse(body)).version.grey + ' accepting connections using our token'
                    def.resolve()

            def.promise
            
    # OK or bust.
    ).done(
        ->
            if key_value[0..'auth_token='.length-1] == 'auth_token='
                 winston.info 'Auth key saved ' + 'ok'.green.bold
            else
                winston.info 'Configuration saved ' + 'ok'.green.bold
        , (err) ->
            try
                err = JSON.parse(err)
                winston.error err?.error?.message or err?.message or err
            catch e
                winston.error err?.error?.message or err?.message or err
    )