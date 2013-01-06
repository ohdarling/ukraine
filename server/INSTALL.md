## Install nodejs and npm

See [Installing Node.js via package manager](https://github.com/joyent/node/wiki/Installing-Node.js-via-package-manager)

## Install forever

	npm install forever -g

## Setup users

    groupadd nodejs
    useradd -g nodejs -m -s /bin/bash nodejs
    
## Get and install ukraine

    cd /srv
    git clone https://github.com/ohdarling/ukraine
    git checkout domains-support
    cd ukraine
    npm install
    chown -R nodejs.nodejs /srv/ukraine
    
## Install init script

    cd /srv/ukraine
    cp server/init-script/ukraine /etc/init.d/
    chmod +x /etc/init.d/ukraine
    
## Use nginx as frontend

This needs compile nginx chunkin module first, see <http://wiki.nginx.org/NginxHttpChunkinModule>

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
		}
	}

	
## Disable direct visit to haibu

	iptables -A INPUT -p tcp --dport 8000 -i venet0 -j DROP
	iptables -A INPUT -p tcp --dport 9002 -i venet0 -j DROP

## Start ukraine
    
    service ukraine start
    
