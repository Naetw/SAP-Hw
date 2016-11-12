#!/bin/sh 


upload () {
    snapshot=$1

    filename=$(echo $snapshot | gawk '{match($1, /(.*)@.*/, dataset); print dataset[1]}')
    filename=$(echo $filename | awk '{sub(/\//, "-", $1); print $1}')
    filename=$(echo $filename"@"`/bin/date "+%Y-%m-%d-%H-%M-%S"`)

    zfs send ${snapshot} | xz > $filename.xz
    openssl aes-256-cbc -in $filename.xz -out $filename.xz.enc

    size=$(ls -al $filename.xz.enc | awk '{print $5}')

    pv -s $size $filename.xz.enc | /usr/home/nae/gdrive upload - $filename.xz.enc
    
    # delete file
    rm -f $filename.xz 
    rm -f $filename.xz.enc
}

rollback () {
    fileID=$1

    # get file name
    filename=$(/usr/home/nae/gdrive info $fileID | grep Name)
    filename=$(echo "$filename" | gawk  -F '\n' '{match($1, /.* (.*)\.xz\.enc/, name); print name[1]}')
    
    # get dataset
    dataset=$(echo "$filename" | gawk -F '\n' '{match($1, /(.*)@.*/, name); print name[1]}')
    dataset=$(echo "$dataset" | gawk -F '\n' '{sub(/-/, "/", $1); print $1}')

    # grep size info for ETA in pv
    size=$(/usr/home/nae/gdrive info --bytes  $fileID | grep Size)
    size=$(echo "$size" | gawk -F '\n' '{match($1, /.* ([0-9]+) B/, num); print num[1]}')

    printf "Downloading....\n"
    # --stdout for pv to show progress, --no-progress for disabling gdrive progress info, redirect stdout garbage to null
    /usr/home/nae/gdrive download $fileID --delete --stdout --no-progress | pv -s $size 1>$filename.xz.enc

    printf "\nDone!\n\n"

    openssl aes-256-cbc -d -in $filename.xz.enc -out $filename.xz
    xz -fd $filename.xz 
    
    # get snapshot namei and symbol
    snapshot=$(file $filename | gawk -F '\n' '{match($1, /.*name: .(.*)./, name); print name[1]}')
    symbol=$(echo "$snapshot" | gawk -F '\n' '{match($1, /.*@(.*)/, name); print name[1]}')

    printf "Rollback....\n"

    echo $dataset
    zfs recv ${dataset}-zbackup@${symbol} < $filename
    zfs rename ${dataset} ${dataset}-old
    zfs rename ${dataset}-zbackup ${dataset}
    zfs destroy -r ${dataset}-old

    # delete file
    rm -rf $filename.xz.enc 
}

if [ "$1" == "--upload" ]; then
    upload $2
elif [ "$1" == "--rollback" ]; then
    rollback $2 
fi

