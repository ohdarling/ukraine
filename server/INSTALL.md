# Setup ukraine as Private Cloud

This is a guide for setting up ukraine as a private cloud service like nodejitsu.

All of following opetaions are running with `root` user.

## Install nodejs and npm

node.js should >= 0.8.0.

See [Installing Node.js via package manager](https://github.com/joyent/node/wiki/Installing-Node.js-via-package-manager)

## Install forever

	npm install forever -g

## Setup users

    groupadd nodejs
    useradd -g nodejs -m -s /bin/bash nodejs
    
## Get and install ukraine

    cd /srv
    git clone https://github.com/ohdarling/ukraine
    cd ukraine
    git checkout private-cloud
    npm install
    chown -R nodejs.nodejs /srv/ukraine
    
## Configure ukraine

	cd /srv/ukraine
	cp config.example.json config.json
	vim config.json
	
For security reason, it is recommended set auth_token to non-empty value.

Replace `example.com` to the domain which you want to host node.js applications, all node.js application will assign a subdomain like `package-name.example.com`.
    
## Install init script

    cd /srv/ukraine
    cp server/init-script/ukraine /etc/init.d/
    chmod +x /etc/init.d/ukraine
    
## Use nginx as frontend

This needs compile nginx chunkin module first, see <http://wiki.nginx.org/NginxHttpChunkinModule>.

Or install `nginx-extras` package will install precompiled nginx with chunkin support.

Add followed configuration to `/etc/nginx/sites-available/haibu`, and add symbol link to this file in `/etc/nginx/sites-enabled`.

Replace `haibu.example.com` and `*.example.com` with your own domain for haibu service.

	server {
		listen   80;
		server_name  haibu.example.com;
		
		access_log  /var/log/nginx/localhost.access.log;

		chunkin on;
		
		error_page 411 = @my_411_error;
			location @my_411_error {
			chunkin_resume;
		}
		
		location / {
			proxy_pass http://localhost:9002;
			proxy_set_header  X-Real-IP  $remote_addr;
		}
	}
	
	server {
		listen   80;
		server_name  *.example.com;
		
		access_log  /var/log/nginx/localhost.access.log;
		
		location / {
			proxy_pass http://localhost:8000;
			proxy_set_header  X-Real-IP  $remote_addr;
			proxy_set_header Host $host;
		}
	}

It is recommended that enable SSL on haibu.example.com for protecting `auth_token`.

After add configuration should reload nginx config:

	nginx -s reload

## Start ukraine
    
    service ukraine start
    
## Check ukraine is running

Open a browser, and visit <http://haibu.example.com/version>, you will see:

	{"version":"haibu 0.9.7"}

It shows haibu started normally.

## Deploy your node.js app

First need install ukraine to local machine:

    npm install -g git://github.com/ohdarling/ukraine\#private-cloud

If you configured auth_token previously, you should config auth_token first.

	chernobyl config haibu.example.com auth_token=xxxx
	
If enabled SSL on haibu, also configure it:

	chernobyl config haibu.example.com https=true
	chernobyl config haibu.example.com haibu_port=443
	
Now can deploy node.js app:

	chernobyl deploy haibu.example.com .
	
## Bind custom domain

For bind a custom domains the node.js application, just add `domains` in `package.json`:

	{
	    "name": "example-app",
	    "version": "0.0.2",
	    "domains": [
	    	"custom-example.com"
	    ]
	    "dependencies": {
	        "express": "2.5.x"
	    },
	    "scripts": {
	        "start": "server.js"
	    },
	    "env": {
	        "key": "value"
	    }
	}

The nginx configuration also needs modify:

	server {
		listen   80;
		server_name  *.example.com, custom-example.com;
		
		access_log  /var/log/nginx/localhost.access.log;
		
		location / {
			proxy_pass http://localhost:8000;
			proxy_set_header  X-Real-IP  $remote_addr;
			proxy_set_header Host $host;
		}
	}	
