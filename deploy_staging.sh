#!/bin/sh

cd /srv/staging
git pull origin master

echo "`date`: staging deployed" >> /home/deploy/deployments.log
