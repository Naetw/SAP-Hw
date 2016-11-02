#!/bin/sh 


#check argument number 
if [ $# == 0 ]; then
    echo "Wrong argument number!"
    exit 1
fi

if [ $1 != "--list" -a $1 != "--delete" ]; then
    #target=$1
    
    # set rotate_count
    if [ "$2" == "" ]; then
        rotate_count=19
    else
        rotate_count=$(( $2-1 ))
    fi

    # check snapshot number, if reach max, then delete oldest one (-q for no output)
    zfs list -t snapshot | grep -q "^${target}@zbackup\.${rotate_count}"
    if [ $? == 0 ]; then
        total=$(zfs list -t snapshot | grep "^${target}@zbackup\..*" | awk -F '\n' 'END{print NR}')
    fi 
elif [ $1 == "--list" ]; then
    
    # generate zbackup list
    list=$(zfs list -r -t snapshot -o name,creation | grep -e NAME -e ".*@zbackup\..*") # grep two pattern
    
    # add index
    list=$(echo "$list" | awk -F '\n' 'BEGIN{idx=1}{if(NR > 1){print idx "\t" $1; idx=idx+1}else print "ID\t" $1}')
    
    # change field name
    list=$(echo "$list" | awk -F '\n' '{
    if(NR == 1){
        sub(/NAME   /, "Dataset", $1); 
        sub(/CREATION/, "Time", $1);
        print $1
    } 
    else print $1
    }')
 
    if [ "$2" == "" ]; then #just list snapshot
        echo "$list"
    else 
        #list specified snapshot  
        # specified ID 
        if [ "$3" != "" ]; then
            echo "$list" | awk -F '\n' -v spec_idx=$3 '{if(NR == spec_idx+1 || NR == 1)print $1;}' 
        else
            echo "$list" | grep $2
        fi
    fi
elif [ $1 == "--delete" ]; then

fi

