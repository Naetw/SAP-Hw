#!/bin/sh 


upload () {
    snapshot=$2

    filename=$(echo $snapshot | gawk '{match($1, /(.*)@.*/, dataset); print dataset[1]}')
    filename=$(echo $filename | awk '{sub(/\//, "-", $1); print $1}')
    filename=$(echo $filename"@"`/bin/date "+%Y-%m-%d-%H-%M-%S"`)

    zfs send ${snapshot} | xz > $filename.xz
    openssl aes-256-cbc -in $filename.xz -out $filename.xz.enc

    size=$(ls -al $filename.xz.enc | awk '{print $5}')

    pv -s $size $filename.xz.enc | /usr/home/nae/gdrive upload - $filename.xz.enc
}

rollback () {
    fileID=$2

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
    xz -fd $outfile 
}

if [ "$1" == "--upload" ]; then
    upload
elif [ "$1" == "--rollback" ]; then
    rollback
fi

