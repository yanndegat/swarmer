#!/bin/bash -e

BASEDIR=$(readlink -f $(dirname $0))
MASTER_MODE=${MASTER_MODE:-"true"}
ES_INDEX_PREFIX=${ES_INDEX_PREFIX:-"graylog2"}
ES_CLUSTER_NAME=${ES_CLUSTER_NAME:-"graylog2"}
ADMIN_NETWORK=${ADMIN_NETWORK:-"default"}
ADMIN_IP=$(ip route | grep "${ADMIN_NETWORK}" | sed "s,.*dev \([a-zA-Z0-9]*\).*$,\1,g" | xargs ip a ls dev | sed -n "s,.*inet \(.*\)/.*,\1,p")
BIND_ADDRESS=${BIND_ADDRESS:-$ADMIN_IP}
MONGO_RSET=${MONGO_RSET:-"graylog"}
ADMIN_PASSWORD_SHA256=${ADMIN_PASSWORD_SHA256:-88630b1fa7cfa07914190f15cfa7a92bdca8c459ad33c102ed8edf2e34d74a98}

if [ -z $BIND_ADDRESS ]; then
    echo "Failed to set BIND_ADDRESS from $ADMIN_NETWORK network." >&2
    exit 1
fi

if [ -z $PASSWORD_SECRET ]; then
    echo "PASSWORD_SECRET not set." >&2
    exit 1
fi

if [ -z $ES_HOSTS ]; then
    echo "ES_HOSTS not set." >&2
    exit 1
fi

if [ -z $MONGO_HOSTS ]; then
    echo "MONGO_HOSTS not set." >&2
    exit 1
fi

# wait for es_hosts to be online
for host in $(echo $ES_HOSTS | sed 's/,/ /g'); do
    $BASEDIR/wait-for-it.sh $host -s -t 20 -- echo "$host ok" >&2
done

# wait for mongo_hosts to be online
for host in $(echo $MONGO_HOSTS | sed 's/,/ /g'); do
    $BASEDIR/wait-for-it.sh $host -s -t 20 -- echo "$host ok" >&2
done

cp /graylog/current/graylog.conf.example /graylog/graylog.conf
export GRAYLOG_CONF=/graylog/graylog.conf

sed -i "s/is_master = true/is_master = $MASTER_MODE/g" $GRAYLOG_CONF
sed -i "s/elasticsearch_index_prefix = graylog2/elasticsearch_index_prefix = $ES_INDEX_PREFIX/g" $GRAYLOG_CONF
sed -i "s/#elasticsearch_cluster_name = graylog2/elasticsearch_cluster_name = $ES_CLUSTER_NAME/g" $GRAYLOG_CONF
sed -i "s/rest_listen_uri = http:\/\/127.0.0.1:12900\//rest_listen_uri = http:\/\/$BIND_ADDRESS:12900\//g" $GRAYLOG_CONF
sed -i "s/#rest_transport_uri = http:\/\/192.168.1.1:12900\//rest_transport_uri = http:\/\/$ADMIN_IP:12900\//g" $GRAYLOG_CONF

sed -i "s/#elasticsearch_network_bind_host =/elasticsearch_network_bind_host = $BIND_ADDRESS/g" $GRAYLOG_CONF
sed -i "s/#elasticsearch_network_publish_host =/elasticsearch_network_publish_host = $BIND_ADDRESS/g" $GRAYLOG_CONF
sed -i "s/#elasticsearch_discovery_zen_ping_unicast_hosts = 127.0.0.1:9300/elasticsearch_discovery_zen_ping_unicast_hosts = $ES_HOSTS/g" $GRAYLOG_CONF
sed -i "s/mongodb_uri = mongodb:\/\/localhost\/graylog2/mongodb_uri = mongodb:\/\/$MONGO_HOSTS\/graylog2?replicaSet=$MONGO_RSET/g" $GRAYLOG_CONF
sed -i "s/root_password_sha2[ ]*=.*/root_password_sha2 = $ADMIN_PASSWORD_SHA256/g" $GRAYLOG_CONF
sed -i "s/password_secret[ ]*=.*/password_secret = $PASSWORD_SECRET/g" $GRAYLOG_CONF


/graylog/current/bin/graylogctl run
