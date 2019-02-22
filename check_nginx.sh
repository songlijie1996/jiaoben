#!/bin/bash
counter=$(ps -C nginx --no-heading|wc -l)
if [ "${counter}" = "0" ]; then
/usr/local/bin/nginx -c /opt/nginx/conf/nginx.conf
sleep 2
counter=$(ps -C nginx --no-heading|wc -l)
if [ "${counter}" = "0" ]; then
/etc/init.d/keepalived stop
fi
fi
