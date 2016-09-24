#!/usr/bin/env bash

mkdir -p /data/owncloud
chown -R www-data:www-data /data/owncloud


# 检查是否重新设置
export RESET=${RESET:-'0'}
if [[ ${RESET} -ne '0' ]]; then
    rm -rf /data/*
fi


if [[ -d /data/owncloud/data ]]; then
    mv /data/owncloud/data /data/owncloud/bak
fi

# first install owncloud
sudo -u ${OWN_CLOUD_USER} php occ maintenance:install --database "sqlite" --admin-user "${RAW_ADMIN}" --admin-pass "${RAW_PASSWORD}" --data-dir "/data/owncloud/data"

if [[ -d /data/owncloud/bak ]]; then
    rm -rf /data/owncloud/data
    mv /data/owncloud/bak /data/owncloud/data
fi

# 添加管理员
if [[ -n ${OWN_CLOUD_ADMIN} ]]; then
    export OC_PASS=${OWN_CLOUD_PASSWORD:-${RAW_PASSWORD}}
    if [[ ${OWN_CLOUD_ADMIN} == "admin" ]]; then
        su -s /bin/sh ${OWN_CLOUD_USER} -c "php occ user:resetpassword --password-from-env ${OWN_CLOUD_ADMIN}"
    else
        su -s /bin/sh ${OWN_CLOUD_USER} -c "php occ user:add --password-from-env --display-name=\"${OWN_CLOUD_ADMIN}\" --group=\"admin\" ${OWN_CLOUD_ADMIN}"
    fi
fi

# 删除默认管理员
if [[ -n ${DISABLED_ORIGIN} ]]; then
    if [[ ${OWN_CLOUD_ADMIN} != "admin" ]]; then
        sudo -u ${OWN_CLOUD_USER} php occ user:delete ${RAW_ADMIN}
    fi
fi

# 添加信任url
if [[ -n ${TRUSTED_DOMAINS} ]]; then
    sudo -u ${OWN_CLOUD_USER} php occ config:system:set trusted_domains 1 --value=${TRUSTED_DOMAINS}
fi


# third apache port config
if [[ -z ${OWN_CLOUD_PORT} ]]; then
    export OWN_CLOUD_PORT=${RAW_PORT}
fi
sed -i -e "s|80|${OWN_CLOUD_PORT}|" /etc/apache2/ports.conf



# 判断持久化数据中是否有config.php
if [[ -f /data/owncloud/config.php ]]; then
    cp /data/owncloud/config.php /var/www/owncloud/config/
fi


if [[ -d /data/owncloud/3rdparty ]]; then
    cp -r /data/owncloud/3rdparty /var/www/owncloud/
fi


if [[ $1 == "bash" ]]; then
    /bin/bash
else
    #apache2ctl -D FOREGROUND
    service apache2 restart
    cp /var/www/owncloud/config/config.php /data/owncloud/config.php
    # start cron
    cron -f
fi

