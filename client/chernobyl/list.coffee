#!/usr/bin/env coffee
fs      = require 'fs'
winston = require 'winston'
request = require 'request'
Q       = require 'q'
dateFormat = require 'dateformat'

haibu_api   = require './haibu_api.coffee'

task = exports

# CLI output on the default output.
winston.cli()

# The actual task.
task.list = (ukraine_ip, app_dir, cfg) ->
    # Is anyone listening?
    return Q.fcall(
        ->
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
                    def.resolve()

            def.promise
    # Attempt to get drones
    ).then(
        ->
            def = Q.defer()

            winston.info 'Retrieving running drones ...'

            haibu_api.get ukraine_ip, "drones"
            , (err, res, body) ->
                if err then def.reject err
                else if res.statusCode isnt 200 then def.reject body?.error?.message or body
                else
                    def.resolve JSON.parse body

            def.promise
    # Show drones
    ).done(
        (drones) ->
            drones = drones.sort (a, b) -> a.name.localeCompare(b.name)
            
            winston.info (drones.length+''), "drones running"
            winston.info ' ', ['name'.grey + '\t', 'version'.grey, 'port'.grey, 'start at'.grey].join('\t\t')
            
            for drone in drones
                t = new Date(drone.ctime)
                line = [
                    drone.name.cyan.bold,
                    (drone.version || 'N/A'),
                    drone.port,
                    dateFormat(t, 'yyyy-mm-dd HH:MM:ss')
                ]
                winston.info ' ', line.join('\t\t')
                
        , (err) ->
            try
                err = JSON.parse(err)
                winston.error err?.error?.message or err?.message or err
            catch e
                winston.error err?.error?.message or err?.message or err
    )
