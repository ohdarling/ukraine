#!/bin/bash

if [ "$UKRAINE_ROOT" == "" ]; then
    DIR=/srv/ukraine
else
    DIR=$UKRAINE_ROOT
fi

echo Entering $DIR ...

cd $DIR

echo Update ukraine ...
git pull

echo Backup haibu pakcages ...
mkdir -p .haibu_bak
mv node_modules/haibu/autostart .haibu_bak/
mv node_modules/haibu/local .haibu_bak/
mv node_modules/haibu/packages .haibu_bak/

echo Remove node_modules ...
rm -rf $DIR/node_modules

echo Reinstall node modules ...
npm install

echo Restore haibu packages ...
mv .haibu_bak/* $DIR/node_modules/haibu/
rmdir .haibu_bak

echo Restarting ukraine ...
service ukraine restart

echo Done.