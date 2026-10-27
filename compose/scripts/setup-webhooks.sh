#!/usr/bin/env sh

set -eu

cat >"/vhost.d/${VIRTUAL_HOST:?Please provide the fqdn}" <<EOF
location /hooks/ {
    proxy_pass http://${WEBHOOK_SERVICE_NAME:?Please provide the webhook service name}:${WEBHOOK_SERVICE_PORT:?Please provide the webhook service port};
    proxy_set_header Host \$host;
    proxy_set_header X-Real-IP \$remote_addr;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto \$scheme;
    proxy_read_timeout 90;
}
EOF
