#!/usr/bin/env coffee
fs      = require 'fs'
path    = require 'path'
winston = require 'winston'
require 'colors'

# CLI output on the default output.
winston.cli()

winston.info "Welcome to #{'chernobyl'.grey} comrade"

# Show welcome logo and desc.
( winston.help line.cyan.bold for line in fs.readFileSync(path.resolve(__dirname, 'logo.txt')).toString('utf-8').split('\n') )
winston.help ''
winston.help 'Deployment of Node.js cloud apps'
winston.help ''

# Show help.
help = ->
    winston.help 'Commands:'.cyan.underline.bold
    winston.help ''
    winston.help 'To deploy an app into cloud'.cyan
    winston.help '  chernobyl deploy <ukraine_ip> <app_path>'
    winston.help 'To stop an app in the cloud'.cyan
    winston.help '  chernobyl stop <ukraine_ip> <app_path>'
    winston.help 'To send an environment variable'.cyan
    winston.help '  chernobyl env <ukraine_ip> <app_path> <key>="<value>"'
    winston.help 'To authenticate this account'.cyan
    winston.help '  chernobyl auth <ukraine_ip> <auth_key>'
    winston.help 'To configure cloud hosting'.cyan
    winston.help '  chernobyl auth <ukraine_ip> <https=true>|<port=80>'
    winston.help ''

# All config should use 'chernobyl config' to configure
cfg = {}

if process.argv.length < 3 then help()
else
    # Expand the args.
    [ α, β, task, ukraine_ip, ε, ζ ] = process.argv

    # Default app path is "this" folder.
    app_path = app_path or '.'

    # Which task?    
    switch task
        when 'deploy', 'stop', 'env', 'auth', 'config'
            # Has the user supplied a path to ukraine?
            unless ukraine_ip
                winston.error "Path to #{'ukraine'.grey} not specified"
                help()
            else
                # Boost config with auth token if available.
                if fs.existsSync(t = process.env.HOME + '/.chernobyl')
                    try
                        user_config = JSON.parse fs.readFileSync t
                        if user_config[ukraine_ip]
                            host_config = user_config[ukraine_ip]
                            cfg[key] = value for key, value in host_config
                    catch e
                        # Silence!

                # env
                if task is 'env'
                        unless ζ
                            winston.error "No key=value pair specified"
                            help()
                        else
                            winston.info "Executing the #{task.magenta} command"
                            (require path.resolve(__dirname, "chernobyl/#{task}.coffee"))[task](ukraine_ip, ε, ζ, cfg)
                # deploy, stop, auth
                else
                    winston.info "Executing the #{task.magenta} command"
                    (require path.resolve(__dirname, "chernobyl/#{task}.coffee"))[task](ukraine_ip, ε, cfg)
        else
            help()