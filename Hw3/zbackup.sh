#!/bin/sh 


#check argument number 
if [ $# == 0 ] ; then
    echo "Wrong argument number!"
    exit 1
fi

create () {
    # make user to specify dataset easily, extract out target
    echo $1 | grep -q  "^\/.*"
    if [ $? == 0 ] ; then
        target=$(echo $1 | gawk '{match($1, /^\/([a-zA-Z0-9]+\/[a-zA-Z0-9]+)\/?/, dataset); print dataset[1]}')
    else
        target=$1
    fi
    
    # set rotate_count
    if [ "$2" == "" ] ; then
        rotate_count=19
    else
        rotate_count=$(( $2-1 ))
    fi
    
    # set total number of this Dataset
    total=$(zfs list -r -t snapshot | grep "^${target}@zbackup-.*" | awk -F '\n' 'END{print NR}')
    
    # check snapshot number, if reach max, then delete oldest one (-q for no output)
    zfs list -r -t snapshot | grep -q "^${target}@zbackup-${rotate_count}"
    if [ $? == 0 ] ; then
        
        # clean up 
        while [ $total -gt $rotate_count ] ; do
            # delete the oldest one
            zfs destroy -r ${target}@zbackup-`expr $total - 1`
            total=$(( $total-1 ))
        done
    fi
    
    # rename the remaining list
    while [ $total -gt 0 ] ; do
        src=$(( $total-1 ))
        zfs rename -r ${target}@zbackup-${src} ${target}@zbackup-${total}
        total=$(( $total-1 ))
    done

    # add new snapshot
    zfs snapshot -r ${target}@zbackup-0

}

make_list () {
    # generate zbackup list
    if [ $# == 0 ] ; then
        list=$(zfs list -r -t snapshot -o name,creation | grep -e NAME -e ".*@zbackup-.*") # grep two pattern
    else
        list=$(zfs list -r -t snapshot -o name,creation | grep -e NAME -e "$1@zbackup-.*") # grep two pattern
    fi

    # add index
    list=$(echo "$list" | awk -F '\n' 'BEGIN{idx=1}{if(NR > 1){print idx "\t" $1; idx=idx+1}else print "ID\t" $1}')
    
    # get time and convert the format and change field name
    time=$(zfs list -r -t snapshot -o  name,creation | grep ".*@zbackup-.*")
    echo "$time" | gawk -F '\n' '{match($1, /.*  ([A-Z].*)/, t); print "\"" t[1] "\""}' > tmp
    line_num=$(cat tmp | wc -l)
    idx=1
    while [ $idx -le $line_num ] ; do
        time_to_trans=$(sed -n "$idx p" tmp | tr -d \")
        time_tmp=$(/usr/local/bin/date --date="${time_to_trans}" "+%Y-%m-%d-%H-%M")
        list=$(echo "$list" | gawk -F '\n' -v i=$idx -v time=$time_tmp '{
        if(NR-1 == i){
            sub(/[A-Za-z]{3} [A-Za-z]{3}.*/, time, $1);
            sub(/@zbackup-[0-9]{2}/, "\t\t  ", $1);
            sub(/@zbackup-[0-9]{1}/, "\t\t ", $1);
            print $1
        }
        else if(NR == 1){
            sub(/NAME   /, "Dataset", $1); 
            sub(/CREATION/, "Time", $1);
            print $1
        }
        else print $1
        }')
        idx=$(( $idx + 1 ))
    done

    
   
    # delet the file
    rm -f tmp
}

show_list () {
    if [ "$1" == "" ] ; then #just list snapshot
        echo "$list"
    else 
        #list specified snapshot  
        # specified ID 
        if [ "$2" != "" ] ; then
            echo "$list" | awk -F '\n' -v spec_idx=$2 '{if(NR == spec_idx+1 || NR == 1)print $1;}' 
        else
            echo "$list" | grep  -e $1 -e ID
        fi
    fi

}

delete () {
    # check dataset specified
    if [ "$1" == "" ] ; then
        printf "\nYou need to specify the dataset!\n\n"
        exit 1
    fi
    
    if [ "$2" == "" ] ; then

        # no ID specified - delete all
        del_total=$(echo "$list" | grep $1 | wc -l)
        while [ $del_total -gt 0 ] ; do
            zfs destroy -r $1@zbackup-`expr $del_total - 1`
            del_total=$(( $del_total - 1 ))
        done
        printf "\nDelete done!\n\n"
    
    # delete specified ID
    else
        del_target=$(echo "$list" | grep "^$2")
        del_target=$(echo $del_target | awk '{print $2}')
        zfs destroy -r $del_target

        # reset name and order
        spec_total=$(echo "$list" | grep "$1" | wc -l)
        gap_num=$2
        while true ; do
            echo "$list" | grep -q "$1@zbackup-$gap_num"
            if [ $? == 0 ] ; then
                zfs rename -r $1@zbackup-`expr $spec_total - $gap_num + 1` $1@zbackup-`expr $spec_total - $gap_num`
            else
                break
            fi
            gap_num=$(( $gap_num - 1 ))
        done
    fi
}

if [ $1 != "--list" -a $1 != "--delete" ] ; then
    create $1 $2 
else
    if [ $1 == "--list" ] ; then
        make_list
        show_list $2 $3        
    elif [ $1 == "--delete" ] ; then
        make_list $2
        delete $2 $3
    fi
fi
