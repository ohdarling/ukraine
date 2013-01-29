#!/usr/bin/env coffee
fs      = require 'fs'
winston = require 'winston'
request = require 'request'
Q       = require 'q'

haibu_api   = require './haibu_api.coffee'

task = exports

# CLI output on the default output.
winston.cli()

# The actual task.
task.stop = (ukraine_ip, app_dir, cfg) ->
    return Q.fcall( ->
        pkg = { name: app_dir }
        # Defined?
        unless pkg.name and pkg.name.length > 0
            throw 'name'.grey + ' field needs to be defined in ' + 'package.json'.grey 
        # Special chars?
        if encodeURIComponent(pkg.name) isnt pkg.name
            throw 'name'.grey + ' field in ' + 'package.json'.grey + ' contains characters that are not allowed in a URL'
        pkg
    # Is anyone listening?
    ).then(
        (pkg) ->
            winston.debug 'Is ' + 'haibu'.grey + ' up?'

            def = Q.defer()

            haibu_api.get ukraine_ip, 'version'
            , (err, res, body) ->
                if err
                    def.reject err
                else if res.statusCode isnt 200
                    def.reject body
                else
                    winston.info (JSON.parse(body)).version.grey + ' accepting connections'
                    def.resolve pkg

            def.promise
    # Attempt to stop the app.
    ).then(
        (pkg) ->
            def = Q.defer()

            winston.info 'Trying to stop ' + pkg.name.bold

            haibu_api.post ukraine_ip, "drones/#{pkg.name}/stop"
            , (err, res, body) ->
                if err then def.reject err
                else if res.statusCode isnt 200 then def.reject body?.error?.message or body
                else
                    def.resolve pkg

            def.promise
    # We do not trust what haibu says...
    ).then(
        (pkg) ->
            winston.debug 'Is ' + pkg.name.bold + ' still running?'

            def = Q.defer()
            
            haibu_api.get ukraine_ip, "drones/#{pkg.name}"
            , (err, res, body) ->
                if err then def.reject err
                else if res.statusCode isnt 404 then def.reject body
                else def.resolve pkg

            def.promise
    # OK or bust.
    ).done(
        (pkg, body) ->
            winston.info pkg.name.bold + ' stopped ' + 'ok'.green.bold
        , (err) ->
            try
                err = JSON.parse(err)
                winston.error err?.error?.message or err?.message or err
            catch e
                winston.error err?.error?.message or err?.message or err
    )