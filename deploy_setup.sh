#!/bin/bash

# check to make sure we're running as root
if [ `whoami` != "root" ]; then
  echo "Please run this script as root."
  exit 1
fi

echo ""
echo " ======================================================================="
echo "|               Balcom Agency Drupal Stack Deploy Script                |"
echo " ======================================================================="
echo ""

# get server IP address
IP_ADDRESS=`curl -s icanhazip.com`
HOSTNAME=`hostname`
echo "Let's get started. $HOSTNAME's external IP address is $IP_ADDRESS."
echo ""

echo " ====================="
echo "| Website Information |"
echo " ====================="
echo "Please enter up to 4 URLs for the production website (leave blank for none)."
echo -n "URL 1: http://"
read -e PRODUCTION_URL_1
echo -n "URL 2: http://"
read -e PRODUCTION_URL_2
echo -n "URL 3: http://"
read -e PRODUCTION_URL_3
echo -n "URL 4: http://"
read -e PRODUCTION_URL_4
echo ""

echo "Please enter up to 2 URLs for the staging website (leave blank for none)."
echo -n "URL 1: http://"
read -e STAGING_URL_1
echo -n "URL 2: http://"
read -e STAGING_URL_2
echo ""

echo " ==============="
echo "| Apache Setup  |"
echo " ==============="
echo "Setting up production Apache VirtualHost..."
cd /etc/apache2/sites-available
if [ "$PRODUCTION_URL_1" != "" ]; then
  sed -i.bak "s/#PRODUCTION_URL_1/ServerName $PRODUCTION_URL_1/" production
elif [ "$PRODUCTION_URL_2" != "" ]; then
  sed -i.bak "s/#PRODUCTION_URL_2/ServerAlias $PRODUCTION_URL_2/" production
elif [ "$PRODUCTION_URL_3" != "" ]; then
  sed -i.bak "s/#PRODUCTION_URL_3/ServerAlias $PRODUCTION_URL_3/" production
elif [ "$PRODUCTION_URL_4" != "" ]; then
  sed -i.bak "s/#PRODUCTION_URL_4/ServerAlias $PRODUCTION_URL_4/" production
fi

sed -i.bak "/PRODUCTION_URL/d" production

echo ""
echo -n "Do you wish to enable the production site now (Y/n)?"
read -e YES_OR_NO
if [ "$YES_OR_NO" == "y" ] || [ "$YES_OR_NO" == "Y"] || [ "$YES_OR_NO" == 'yes' ] || [ "$YES_OR_NO" == "Yes"]; then
  echo "Enabling production site..."
  a2ensite production
fi
echo ""

echo "Setting up staging Apache VirtualHost..."
cd /etc/apache2/sites-available
if [ "$STAGING_URL_1" != "" ]; then
  sed -i.bak "s/#STAGING_URL_1/ServerName $STAGING_URL_1/" staging
elif [ "$STAGING_URL_2" != "" ]; then
  sed -i.bak "s/#STAGING_URL_2/ServerAlias $STAGING_URL_2/" staging
fi

sed -i.bak "/^STAGING_URL/d" staging

echo ""
echo -n "Do you wish to enable the staging site now (Y/n)?"
read -e YES_OR_NO
if [ "$YES_OR_NO" == "y" ] || [ "$YES_OR_NO" == "Y"] || [ "$YES_OR_NO" == 'yes' ] || [ "$YES_OR_NO" == "Yes"]; then
  echo "Enabling staging site..."
  a2ensite staging
fi
echo ""

# SSL
echo -n "Do you need to add SSL to this website (Y/n)? "
read -e ENABLE_SSL
if [ "$ENABLE_SSL" = "y" ] || [ "$ENABLE_SSL" = "Y" ]; then
  echo "Going to use SSL."
  nano /etc/apache2/ssl/server.crt
  nano /etc/apache2/ssl/server.key
  sed -i.bak "s/\*/$IP_ADDRESS/" /etc/apache2/sites-available/ssl
  a2enmod ssl
  a2ensite ssl
else
  echo "Not going to use SSL."
fi
echo ""


echo "============="
echo "| Git Setup |"
echo "============="
# ask for the private git URL
echo "Please enter the URL of the git repository with read/write permissions."
echo -n "URL (e.g. git@github.com:username/repo.git): "
read -e GIT_REPO
echo "Git repo set to $GIT_REPO"
echo ""

chown -R deploy:deploy /srv

echo "Getting code for production site from $GIT_REPO..."
cd /srv/production
su deploy -c "git remote add origin $GIT_REPO"
su deploy -c "git checkout -b production"
su deploy -c "git pull origin production"
echo "`date`: production set up with $GIT_REPO(production)" | tee -a /home/deploy/deployments.log
echo ""

echo "Getting code for staging site from $GIT_REPO..."
cd /srv/staging
su deploy -c "git remote add origin $GIT_REPO"
su deploy -c "git checkout master"
su deploy -c "git pull origin master"
echo "`date`: staging set up with $GIT_REPO(staging)" | tee -a /home/deploy/deployments.log
echo ""

echo "================"
echo "| Housekeeping |"
echo "================"
# get varnish cache set up for this hostname
cd /var/lib/varnish/
rm -r balcom-drupal-stack/
mkdir $HOSTNAME
/etc/init.d/varnish restart

# restart Apache
/etc/init.d/apache2 restart

# chown deployments.log
"chown deploy:deploy /home/deploy/deployments.log..."
chown deploy:deploy /home/deploy/deployments.log

exit 0
