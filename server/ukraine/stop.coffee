#!/usr/bin/env coffee
fs      = require 'fs'
path    = require 'path'
winston = require 'winston'
Q       = require 'q'

utility = require '../utility.coffee'

haibu = require '../../node_modules/haibu/lib/haibu.js' # direct path to local haibu!

# POST stop a running drone.
haibu.router.post '/drones/:name/stop', {} , (APP_NAME) ->
    req = @req ; res = @res
    
    # Stopping app.
    return Q.fcall( ->
        winston.debug 'Stopping app'

        def = Q.defer()

        haibu.running.drone.stop APP_NAME, (err, result) ->
            if err then def.reject err
            else def.resolve()

        def.promise
    # Update the routing table.
    ).then(
        ->
            utility.update_routes_table()
    # OK or bust.
    ).done(
        ->
            haibu.sendResponse res, 200, {}
        , (err) ->
            haibu.sendResponse res, 500,
                'error':
                    'message': err.message or err
    )