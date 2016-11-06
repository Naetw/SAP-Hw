#!/bin/sh 

if [ $# == 0 ]; then
    echo "You need to specify fileID!!!"
    exit 1
fi

fileID=$1

# get file name
infile=$(/usr/home/nae/gdrive info $fileID | grep Name)
infile=$(echo "$infile" | gawk  -F '\n' '{match($1, /.* (.*)/, name); print name[1]}')
outfile=$(echo "$infile" | gawk -F '\n' '{match($1, /(.*)\.enc/, name); print name[1]}')


# grep size info for ETA in pv
size=$(/usr/home/nae/gdrive info --bytes  $fileID | grep Size)
size=$(echo "$size" | gawk -F '\n' '{match($1, /.* ([0-9]+) B/, num); print num[1]}')

printf "Downloading....\n"
# --stdout for pv to show progress, --no-progress for disabling gdrive progress info, redirect stdout garbage to null
/usr/home/nae/gdrive download $fileID --stdout --no-progress | pv -s $size 1>${infile}

printf "\nDone!\n\n"

printf "Rollback....\n"


openssl aes-256-cbc -d -in $infile -out $outfile
