#!/usr/bin/env coffee
fs      = require 'fs'
path    = require 'path'
winston = require 'winston'
Q       = require 'q'

haibu = require '../node_modules/haibu/lib/haibu.js' # direct path to local haibu!

# We request the same file in the main thread.
CFG = JSON.parse fs.readFileSync(path.resolve(__dirname, '../config.json')).toString('utf-8')

# Haibu only knows apps by name.
APP_USER = 'chernobyl'

update_routes_table = (args) ->
    winston.debug 'Updating proxy routes'

    routes = path.resolve(__dirname, 'routes.json')

    # Traverse running apps.
    table = {}
    
    queue = []
    
    save = (app_name, app_port) ->
        # Are we using non standard port? Else leave it out.
        port = (if (CFG.proxy_port is 80 || CFG.omit_haibu_port_when_hostname_only) then '' else ":#{CFG.proxy_port}")
        
        # 'Hostname Only' ProxyTable?
        if CFG.proxy_hostname_only
            table["#{app_name}.#{CFG.proxy_host}#{port}"] = "127.0.0.1:#{app_port}"
        else
            table["#{CFG.proxy_host}#{port}/#{app_name}/"] = "127.0.0.1:#{app_port}"
            
        prefix = "#{APP_USER}-#{app_name}-"

        # Get running instance of app
        Q.fcall(
            ->
                def = Q.defer()
                
                fs.readdir path.resolve(__dirname, "../node_modules/haibu/local/#{APP_USER}/#{app_name}"), (err, files) ->
                    if err then def.reject err
                    else def.resolve files[0] ? ''
                        
                def.promise
        # Load package.json
        ).then(
            (app_dir) ->
                def = Q.defer()
                
                if app_dir[0..prefix.length-1] == prefix
                    app_dir = path.resolve(__dirname, "../node_modules/haibu/local/#{APP_USER}/#{app_name}/#{app_dir}")

                    fs.readFile "#{app_dir}/package.json", 'utf-8', (err, text) ->
                        if err then def.resolve '{}'
                        else def.resolve text
                else
                    def.resolve '{}'
                    
                def.promise
        # Get domains from package.json
        ).when(
            (text) ->
                pkg = JSON.parse text ? '{}'
                domains = pkg.domains ? []
                (domain.length > 0 && table["#{domain}#{port}"] = "127.0.0.1:#{app_port}") for domain in domains
        )
            
    ( queue.push(save(app.name, app.port)) for app in haibu.running.drone.running() )
    
    Q.all(queue)
    .then(
        ->
            def = Q.defer()
            
            winston.debug 'routes.json:', JSON.stringify table

            fs.writeFile routes, JSON.stringify({ 'router': table, 'hostnameOnly': CFG.proxy_hostname_only }, null, 4), (err) ->
                if err then def.reject err
                else def.resolve args
                    
            def.promise
    )

exports.update_routes_table = update_routes_table
