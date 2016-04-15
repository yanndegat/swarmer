#!/bin/bash -e
BASEDIR=$(readlink -f $(dirname $0))
TIMEZONE=${TIMEZONE:-"Europe\/Paris"}
ADMIN_NETWORK=${ADMIN_NETWORK:-"default"}
BIND_ADDRESS=$(ip route | grep "${ADMIN_NETWORK}" | sed "s,.*dev \([a-zA-Z0-9]*\).*$,\1,g" | xargs ip a ls dev | sed -n "s,.*inet \(.*\)/.*,\1,p")

if [ -z $CONSUL_HOST ]; then
    echo "CONSUL_HOST not set." >&2
    exit 1
fi

if [ -z $GRAYLOG_SERVICE_NAME ]; then
    echo "GRAYLOG_SERVERS_HOSTS not set." >&2
    exit 1
fi

if [ -z $APPLICATION_SECRET ]; then
    echo "APPLICATION_SECRET not set." >&2
    exit 1
fi

GRAYLOG_CONF=/graylog/current/conf/graylog-web-interface.conf
GRAYLOG_CONF_TPL=/graylog/graylog-web-interface.conf.tpl
cp $GRAYLOG_CONF $GRAYLOG_CONF_TPL

sed -i "s/graylog2-server.uris=.*$/graylog2-server.uris=\"{{range \$index, \$elem := service \"$GRAYLOG_SERVICE_NAME\" \"passing\" }}{{if ne \$index 0 }},{{end}}http:\/\/{{.Address}}:{{.Port}}{{end}}\"/g" $GRAYLOG_CONF_TPL
sed -i "s/# timezone=\"Europe\/Berlin\"/timezone=\"$TIMEZONE\"/g" $GRAYLOG_CONF_TPL
sed -i "s/application.secret[ ]*=.*/application.secret = \"$APPLICATION_SECRET\"/g" $GRAYLOG_CONF_TPL

cat > /graylog/consul-template.conf <<EOF
consul = "$CONSUL_HOST"

template {
  source = "$GRAYLOG_CONF_TPL"
  destination = "$GRAYLOG_CONF"
  command = "/graylog/start-graylog.sh "
}
EOF

/graylog/consul-template -config /graylog/consul-template.conf -consul $CONSUL_HOST > /graylog/consul.log 2>&1 &
tail -f /graylog/web.log /graylog/consul.log &

TAIL_PID=$!
running(){
    pgrep consul-template > /dev/null
    echo $?
}

cleanup(){
    killall java consul-template tail
}

stop() {
  echo -en "\n*** Exiting ***\n"
  cleanup
  exit 0
}

# trap keyboard interrupt (control-c)
trap stop SIGINT

while [[ $(running) == 0 ]]; do
    sleep 2
done
echo "ERROR: Graylog-web has died!" >&2
cleanup
