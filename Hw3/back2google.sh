#!/bin/sh 

if [ $# == 0 ]; then
    printf "\nYou have to specify snapshot!\n\n"
    exit 1
fi

snapshot=$1

filename=$(echo $1 | gawk '{match($1, /(.*)@.*/, dataset); print dataset[1]}')
filename=$(echo $filename | awk '{sub(/\//, "-", $1); print $1}')
filename=$(echo $filename"@"`/bin/date "+%Y-%m-%d-%H-%M-%S"`)

zfs send ${snapshot} | xz > $filename.xz
openssl aes-256-cbc -in $filename.xz -out $filename.xz.enc

size=$(ls -al $filename.xz.enc | awk '{print $5}')

pv -s $size $filename.xz.enc | /usr/home/nae/gdrive upload - ./$filename.xz.enc
