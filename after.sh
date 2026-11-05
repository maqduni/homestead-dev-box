#!/bin/sh

# If you would like to do some extra provisioning you may
# add any commands you wish to this file and they will
# be run after the Homestead machine is provisioned.

set -e

# Install PHP 8.5 (Homestead provisioner tops out at 8.3)
if ! command -v php8.5 >/dev/null 2>&1; then
    sudo apt-get update
    sudo apt-get install -y \
        php8.5-fpm php8.5-cli php8.5-common php8.5-mysql \
        php8.5-mbstring php8.5-xml php8.5-curl php8.5-zip \
        php8.5-bcmath php8.5-gd php8.5-intl php8.5-redis \
        php8.5-pgsql
fi

sudo systemctl enable --now php8.5-fpm

# Point nginx sites at php8.5-fpm.sock
for conf in /etc/nginx/sites-available/*; do
    [ -f "$conf" ] && sudo sed -i -E 's|php8\.[0-9]+-fpm\.sock|php8.5-fpm.sock|g' "$conf"
done
sudo nginx -t && sudo systemctl reload nginx

# Make 8.5 the default `php` on the CLI
sudo update-alternatives --set php /usr/bin/php8.5

# Allow www-data (PHP-FPM) to traverse into /home/vagrant.
# Jammy's default is 0750 which blocks www-data; Focal/Bionic used 0755.
sudo chmod 755 /home/vagrant

# Grant BOTH `vagrant` (CLI user, e.g. `php artisan` from ssh) and `www-data`
# (PHP-FPM) read/write on Laravel's storage and bootstrap/cache using POSIX ACLs
# with a default (-d) rule so newly created files inherit the perms. Without
# this, each user keeps creating files the other can't write to, producing an
# endless ping-pong of "Permission denied" on log/cache writes.
sudo apt-get install -y acl >/dev/null 2>&1 || true
for dir in \
    /home/vagrant/Code/vazhaju/server/storage \
    /home/vagrant/Code/vazhaju/server/bootstrap/cache; do
    if [ -d "$dir" ]; then
        sudo setfacl -R    -m u:www-data:rwX,u:vagrant:rwX "$dir"
        sudo setfacl -R -d -m u:www-data:rwX,u:vagrant:rwX "$dir"
    fi
done
