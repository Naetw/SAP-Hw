#!/bin/sh 

#check argument number 
if [ $# == 0 ]; then
    echo "Wrong argument number!"
    exit 1
fi

if [ $1 == "--list" ];then
    if [ "$2" == "" ]; then #just list snapshot
        zfs list -r -t snapshot -o name,creation
    else #list specified snapshot
        list=$(zfs list -r -t snapshot -o name,creation | grep -e NAME -e $2) # grep two pattern

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
        
        # specified ID 
        if [ "$3" != "" ];then
            echo "$list" | awk -F '\n' -v spec_idx=$3 '{if(NR == spec_idx+1 || NR == 1)print $1;}' 
        else
            echo "$list"
        fi
    fi
fi

