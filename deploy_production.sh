#!/bin/sh

cd /srv/production
git pull origin production

echo "`date`: production deployed" >> /home/deploy/deployments.log
