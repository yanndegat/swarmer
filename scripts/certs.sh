#!/bin/bash -e
BASEDIR=$(readlink -f "$(dirname "$0")")
STACK="$1"
DATACENTER="$2"

if [ -z "$STACK" ] || [ -z "$DATACENTER" ]; then
    echo "usage: $BASEDIR/swarmer.sh STACK DATACENTER [docker commands]"
fi

CERTDIR="$HOME/.swarmer/$STACK/$DATACENTER"
mkdir -p "$CERTDIR"

cat > "$CERTDIR"/run.sh <<EOF

cd /flocker
echo "create ca cert">&2
flocker-ca initialize ${STACK}
echo "create swarm cert">&2
flocker-ca create-control-certificate swarm.service.$DATACENTER.$STACK
echo "create consul cert">&2
flocker-ca create-control-certificate consul.service.$DATACENTER.$STACK
echo "create flocker cert">&2
flocker-ca create-control-certificate flocker.service.$DATACENTER.$STACK
echo "create registry cert">&2
flocker-ca create-control-certificate registry.service.$DATACENTER.$STACK

echo "create client cert">&2
flocker-ca create-api-certificate client
EOF

chmod +x "$CERTDIR/run.sh"
docker run --rm -v "$CERTDIR":/flocker yanndegat/flocker-tools /bin/bash -c "/flocker/run.sh > /dev/null"
sudo chown -R "$USER":"$USER" "$CERTDIR"
find "$CERTDIR" -type f -exec chmod 0600 {} \;
pushd "$CERTDIR" >/dev/null
# We don't want to ship the cacert with the tarball.
# Plus no one should be able to create new certs.
rm cluster.key
tar -cf "./certs.tar" ./*.key ./*.crt
popd >/dev/null

base64 > "$CERTDIR/certs.$DATACENTER.$STACK.tar.base64" < "$CERTDIR/certs.tar"

rm "$CERTDIR/certs.tar"

echo "certs are in $(readlink -f "$CERTDIR")"
