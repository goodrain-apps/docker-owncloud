#!/usr/bin/env bash

cat > /tmp/init.sql <<EOF
CREATE DATABASE IF NOT EXISTS ${RAW_DB_NAME} DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci;
EOF
cat > /tmp/reinit.sql <<EOF
DROP DATABASE IF EXISTS ${RAW_DB_NAME};
CREATE DATABASE IF NOT EXISTS ${RAW_DB_NAME} DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci;
EOF

mysql -h${RAW_DB_HOST} -u${RAW_DB_USER} -p${RAW_DB_PASS} -P${RAW_DB_PORT} < /tmp/init.sql



