#!/bin/bash -e
BASEDIR=$(readlink -f $(dirname $0))

PORT=$1
CONSUL_HOST=$2
SERVICE_NAME=$3

cat > /run/haproxy.tmpl <<EOF
global
    maxconn {{or (key "service/haproxy/maxconn") 256}}
    debug

defaults
    timeout connect {{or (key "service/haproxy/timeouts/connect") "5000ms"}}
    timeout client {{or (key "service/haproxy/timeouts/client") "50000ms"}}
    timeout server {{or (key "service/haproxy/timeouts/server") "50000ms"}}

listen  haproxy
        bind *:$PORT{{range service "$SERVICE_NAME"}}
        server {{.Node}} {{.Address}}:{{.Port}}{{end}}
        mode http
EOF

cat > /run/consul-template.conf <<EOF
consul = "$CONSUL_HOST"

template {
  source = "/run/haproxy.tmpl"
  destination = "/etc/haproxy/haproxy.cfg"
  command = "haproxy -D -p /var/run/haproxy.pid -f /etc/haproxy/haproxy.cfg -sf \$(cat /var/run/haproxy.pid) || true"
}
EOF

/run/consul-template -config /run/consul-template.conf -consul $CONSUL_HOST
