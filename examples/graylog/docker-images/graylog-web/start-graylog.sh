#!/bin/bash
export GRAYLOG_CONF=$GRAYLOG_CONF

pgrep java > /dev/null
if [ $? -eq 0 ]; then
    killall java
fi

nohup /graylog/current/bin/graylog-web-interface > /graylog/web.log 2>&1 &
