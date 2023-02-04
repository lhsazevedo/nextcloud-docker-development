#!/bin/bash

# Source the enviroment variables
. /home/nextcloud/.env

# Clone Nextcloud repository, if needed
if [ ! -d ".git" ]; then
    git clone --progress --single-branch --depth 1 --branch "${VERSION_NEXTCLOUD}" --recurse-submodules -j 4 https://github.com/nextcloud/server /tmp/nextcloud
    rsync -r /tmp/nextcloud/ .
    mkdir data
    mkdir apps-writable
    mkdir apps-extra
    # chown -R www-data:www-data .
fi

# Wait for database
php /home/nextcloud/wait-for-db.php

# Set configurations, if needed
if [[ ! -f "config/config.php" && ${AUTOINSTALL} -eq 1 ]]; then
    if [[ ! -z ${POSTGRES_HOST} && ! -z ${POSTGRES_DB} && ! -z ${POSTGRES_USER} && ! -z ${POSTGRES_PASSWORD} ]]; then
        php occ maintenance:install --verbose --database=pgsql --database-name=${POSTGRES_DB} --database-host=${POSTGRES_HOST} --database-port= --database-user=${POSTGRES_USER} --database-pass=${POSTGRES_PASSWORD} --admin-user=${NEXTCLOUD_ADMIN_USER} --admin-pass=${NEXTCLOUD_ADMIN_PASSWORD} --admin-email=${NEXTCLOUD_ADMIN_EMAIL}
    elif [[ ! -z ${MYSQL_HOST} && ! -z ${MYSQL_DATABASE} && ! -z ${MYSQL_USER} && ! -z ${MYSQL_PASSWORD} ]]; then
        php occ maintenance:install --verbose --database=mysql --database-name=${MYSQL_DATABASE} --database-host=${MYSQL_HOST} --database-port= --database-user=${MYSQL_USER} --database-pass=${MYSQL_PASSWORD} --admin-user=${NEXTCLOUD_ADMIN_USER} --admin-pass=${NEXTCLOUD_ADMIN_PASSWORD} --admin-email=${NEXTCLOUD_ADMIN_EMAIL}
    fi

    php occ config:import <<EOF
{
    "system": {
        "apps_paths":[
            {
                "path":"/src/apps",
                "url":"/apps",
                "writable":false
            },
            {
                "path":"/src/apps-extra",
                "url":"/apps-extra",
                "writable":false
            },
            {
                "path":"/src/apps-writable",
                "url":"/apps-extra",
                "writable":true
            }
        ]
    }
}
EOF

    php occ config:system:set memcache.local             --value "\OC\Memcache\APCu"
    php occ config:system:set memcache.distributed       --value "\OC\Memcache\Redis"
    php occ config:system:set redis host                 --value "redis"

    php occ config:system:set debug                      --value true --type boolean
    php occ config:system:set loglevel                   --value 0 --type integer
    php occ config:system:set query_log_file             --value /src/data/database.log

    php occ config:system:set default_phone_region       --value ${DEFAULT_PHONE_REGION}
    php occ config:system:set allow_local_remote_servers --value true --type boolean

    php occ config:system:set mail_from_address          --value ${MAIL_FROM_ADDRESS}
    php occ config:system:set mail_domain                --value ${MAIL_DOMAIN}
    php occ config:system:set mail_smtpport              --value ${MAIL_SMTPPORT} --type integer
    php occ config:system:set mail_smtphost              --value ${MAIL_SMTPHOST}
fi

# Start PHP-FPM
php-fpm
