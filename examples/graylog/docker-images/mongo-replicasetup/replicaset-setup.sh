#!/bin/bash -e
REPLICASET_NAME=$1
shift
HOSTS=($@)

for host in "${HOSTS[@]}"; do
    /wait-for-it.sh $host:27017 -s -t 20 -- echo "$host ok" >&2
done

REPLICA_CMD="var conf = {_id:'$REPLICASET_NAME', members:["
for (( i = 0 ; i < ${#HOSTS[@]} ; i++ )) do echo ${names[$i]}
    if [[ i -ne 0 ]]; then
        REPLICA_CMD="$REPLICA_CMD,"
    fi

    REPLICA_CMD="$REPLICA_CMD { _id:$i, host:'${HOSTS[$i]}:27017'}"
done
REPLICA_CMD="$REPLICA_CMD]}; rs.initiate(conf);"

echo $REPLICA_CMD | mongo --quiet >&2
