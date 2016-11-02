#!/bin/sh 


#check argument number 
if [ $# == 0 ]; then
    echo "Wrong argument number!"
    exit 1
fi

if [ $1 != "--list" -a $1 != "--delete" ]; then
    target=$1
    
    # set rotate_count
    if [ "$2" == "" ]; then
        rotate_count=19
    else
        rotate_count=$(( $2-1 ))
    fi
    
    # set total number of this Dataset
    total=$(zfs list -r -t snapshot | grep "^${target}@zbackup\..*" | awk -F '\n' 'END{print NR}')
    echo $total
    # check snapshot number, if reach max, then delete oldest one (-q for no output)
    zfs list -r -t snapshot | grep -q "^${target}@zbackup\.${rotate_count}"
    if [ $? == 0 ]; then
        
        # clean up 
        while [ $total -gt $rotate_count ]; do
            # delete the oldest one
            zfs destroy -r ${target}@zbackup.`expr $total - 1`
            total=$(( $total-1 ))
        done
    fi
    
    # rename the remaining list
    while [ $total -gt 0 ]; do
        src=$(( $total-1 ))
        zfs rename -r ${target}@zbackup.${src} ${target}@zbackup.${total}
        total=$(( $total-1 ))
    done

    # add new snapshot
    zfs snapshot -r ${target}@zbackup.0
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
            echo "$list" | grep  -e $2 -e ID
        fi
    fi
elif [ $1 == "--delete" ]; then
    
    # check dataset specified
    if [ "$2" == "" ]; then
        printf "\nYou need to specify the dataset!\n"
        exit 1
    fi
    
    #if [ "$3" == "" ]; then

        # no ID specified - delete all
        

fi

