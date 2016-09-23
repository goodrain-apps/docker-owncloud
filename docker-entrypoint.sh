#!/usr/bin/env bash

chown -R www-data:www-data /data


# first mysql password config
if [[ -n ${MYSQL_PASSWORD} ]]; then
    service mysql restart
    mysqladmin -u ${RAW_DB_USER} -p ${RAW_DB_PASS} password "${MYSQL_PASSWORD}"
    sudo -u ${OWN_CLOUD_USER} php occ db:convert-type --port="${RAW_DB_PORT}" --password="${MYSQL_PASSWORD}" --all-apps mysql ${RAW_DB_USER} ${RAW_DB_HOST} ${RAW_DB_NAME}
fi



# second owncloud admin config
if [[ -z ${OWN_CLOUD_ADMIN} ]]; then
    export OWN_CLOUD_ADMIN=${RAW_ADMIN}
    # 此时更新管理员密码
    if [[ -n ${OWN_CLOUD_PASSWORD} ]]; then
        export OC_PASS=${OWN_CLOUD_PASSWORD}
        su -s /bin/sh ${OWN_CLOUD_USER} -c "php occ user:resetpassword --password-from-env ${OWN_CLOUD_ADMIN}"
    fi
else
    # 更新 owncloud 的管理员账号
    export OC_PASS=${OWN_CLOUD_PASSWORD:-${RAW_PASSWORD}}
    su -s /bin/sh ${OWN_CLOUD_USER} -c "php occ user:add --password-from-env --display-name=\"${OWN_CLOUD_ADMIN}\" --group=\"admin\" ${OWN_CLOUD_ADMIN}"
    # sudo -u ${OWN_CLOUD_USER} php occ user:add --password-from-env --display-name="${OWN_CLOUD_ADMIN}" --group="admin" --group="db-admins" ${OWN_CLOUD_ADMIN}
    sudo -u ${OWN_CLOUD_USER} php occ user:delete ${RAW_ADMIN}
fi



# third apache port config
if [[ -z ${OWN_CLOUD_PORT} ]]; then
    export OWN_CLOUD_PORT=${RAW_PORT}
fi
sed -i -e "s|80|${OWN_CLOUD_PORT}|" /etc/apache2/ports.conf


# 检查是否重新设置
export RESET=${RESET:-'0'}
if [[ ${RESET} -ne '0' ]]; then
    rm -rf /data/*
    if [[ -n ${MYSQL_PASSWORD} ]]; then
        mysql -h${RAW_DB_HOST} -u${RAW_DB_USER} -p${MYSQL_PASSWORD} -P${RAW_DB_PORT} < /tmp/reinit.sql
    fi
fi


# 判断持久化数据中是否有config.php
if [[ -f /data/config.php ]]; then
    cp /data/config.php /var/www/owncloud/config/
fi


if [[ -f /var/www/owncloud/config/config.php ]]; then
    # 判断持久化中是否有数据
    echo "ok"
else
    # 这里需要初始化
    if [[ -n ${MYSQL_PASSWORD} ]]; then
        mysql -h${RAW_DB_HOST} -u${RAW_DB_USER} -p${MYSQL_PASSWORD} -P${RAW_DB_PORT} < /tmp/reinit.sql
        sudo -u www-data php occ maintenance:install --database "mysql" --database-name "${RAW_DB_NAME}" --database-user "${RAW_DB_USER}" --database-pass "${MYSQL_PASSWORD}" --admin-user "${OWN_CLOUD_ADMIN}" --admin-pass "${OWN_CLOUD_PASSWORD}" --data-dir /data/data
    else
        rm -rf /data/*
        sudo -u www-data php occ maintenance:install --database "sqlite" --admin-user "${OWN_CLOUD_ADMIN}" --admin-pass "${OWN_CLOUD_PASSWORD}" --data-dir "/data/data"
    fi
fi


if [[ -d /data/3rdparty ]]; then
    cp -r /data/3rdparty /var/www/owncloud/
fi
if [[ -d /data/data ]]; then
    cp -r /data/data /var/www/owncloud/
fi
#if [[ -d /data/3rdparty ]]; then
#    rm -rf /var/www/owncloud/3rdparty
#    ln -s /data/3rdparty var/www/owncloud/
#else
#    mkdir -p /data/3rdparty
#    cp -r /var/www/owncloud/3rdparty /data/
#    rm -rf /var/www/owncloud/3rdparty
#    ln -s /data/3rdparty var/www/owncloud/
#fi

#if [[ -d /data/owncloud/data ]]; then
#    rm -rf /var/www/owncloud/data
#    ln -s /data/owncloud/data var/www/owncloud/
#else
#    mkdir -p /data/owncloud
#    cp -r /var/www/owncloud/data /data/owncloud/
#    rm -rf /var/www/owncloud/data
#    ln -s /data/owncloud/data var/www/owncloud/
#fi


if [[ $1 == "bash" ]]; then
    /bin/bash
else
    #apache2ctl -D FOREGROUND
    service apache2 restart
    # start cron
    cron -f
fi

