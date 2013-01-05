## Install nodejs and npm

[Installing Node.js via package manager](https://github.com/joyent/node/wiki/Installing-Node.js-via-package-manager)

## Install forever

	npm install forever -g

## Setup users

    groupadd nodejs
    useradd -g nodejs -m -s /bin/bash nodejs
    
## Get and install ukraine

    cd /srv
    git clone https://github.com/ohdarling/ukraine
    cd ukraine
    npm install
    chown -R nodejs.nodejs /srv/ukraine
    
## Install init script

    cd /srv/ukraine
    cp server/init.d/ukraine /etc/init.d/
    chmod +x /etc/init.d/ukraine

## Start
    
    service ukraine start
    
