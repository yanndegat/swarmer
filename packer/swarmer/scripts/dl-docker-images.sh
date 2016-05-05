#!/bin/bash

BASEDIR=$(dirname "$0")
DL_DIR=${DL_DIR:-"$BASEDIR/../builds/docker-images"}

mkdir -p "$DL_DIR"

dl_image(){
    IMG=$1
    FILE="$DL_DIR/$(echo "$IMG" | sed -e 's/[\/:]/-/g').docker"
    if [ ! -f "$FILE" ]; then
        docker pull "$IMG"
        docker save -o "$FILE" "$IMG"
    else
        echo "image $IMG already downloaded."
    fi
}

for i in "$@"; do
    dl_image "$i"
done
