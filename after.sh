#!/bin/sh

# If you would like to do some extra provisioning you may
# add any commands you wish to this file and they will
# be run after the Homestead machine is provisioned.

# PHP FPM
sudo service php7.4-fpm start
sudo service php8.1-fpm start


# Python virtual environments
#sudo pip install virtualenvwrapper
