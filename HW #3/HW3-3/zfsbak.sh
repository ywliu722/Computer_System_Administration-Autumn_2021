#!/bin/sh

zfs_create(){
    # get name of last snapshot
    last_snap=$(zfs_list $1 | tail -n1 | awk '{print $2 "@" $3}' | grep $1)

    # new snapshot
    snap_date=$(date +"%Y-%m-%d-%H:%M:%S")
    snap_name="$1@$snap_date"
    zfs snapshot $snap_name

    # check if the two snapshot is the same
    if [ "$last_snap" != "" ]; then
        snap_diff=$(zfs diff $last_snap $snap_name)
        if [ "$snap_diff" == "" ]; then
            echo "Snapshot is the same as latest one!"
            zfs destroy $snap_name
        else
            echo "Snap $snap_name"
        fi
    else
        echo "Snap $snap_name"
    fi

    if [ "$2" == "" ]; then # default rotation count = 20
        rotation_count=20
    else # set rotation count
        rotation_count=$2
    fi

    snap_count=$(zfs_list | grep $1 -c)
    if [ $snap_count -gt $rotation_count ]; then
        destroy_line=$(( $snap_count - $rotation_count ))
        zfs_list $1 | awk -v destroy_line=$destroy_line '{if((NR-destroy_line)<2 && NR>1) print $2 "@" $3}' | xargs -I % -L1 echo Destroy %
        zfs_list $1 | awk -v destroy_line=$destroy_line '{if((NR-destroy_line)<2 && NR>1) print $2 "@" $3}' | xargs -I % -L1 zfs destroy %
    fi
}

zfs_list(){
    if [ "$1" == "" ]; then # list all
        zfs list -t snapshot -o name,creation -s creation 2>&1 |
            awk '{if(NR>1) print $1}' |
            awk -F "@" 'BEGIN{print "ID\tDATASET\t\tTIME"}
                        {print NR "\t" $1 "\t" $2}'
    else
        echo $1 | grep -q "^[0-9]*$" # check if $1 is number or not using regular expression
        if [ $? == 0 ]; then # list only ID
            zfs list -t snapshot -o name,creation -s creation 2>&1 |
                awk '{if(NR>1) print $1}' |
                awk -F "@" -v ID=$1 'BEGIN{print "ID\tDATASET\t\tTIME"}
                                    {if(NR==ID){print NR "\t" $1 "\t" $2}}'
        elif [ "$2" == "" ]; then # list only dataset
            zfs list -t snapshot -o name,creation -s creation 2>&1 |
                awk '{if(NR>1) print $1}' |
                grep "$1" |
                awk -F "@" 'BEGIN{print "ID\tDATASET\t\tTIME"}
                        {print NR "\t" $1 "\t" $2}'
        else
            zfs list -t snapshot -o name,creation -s creation 2>&1 |
                awk '{if(NR>1) print $1}' |
                grep "$1" |
                awk -F "@" -v ID=$2 'BEGIN{print "ID\tDATASET\t\tTIME"}
                                    {if(NR==ID){print NR "\t" $1 "\t" $2}}'
        fi
    fi
}

zfs_delete(){
    if [ "$2" == "" ]; then #delete all
        zfs_list | awk '{if(NR>1) print $2 "@" $3}' | xargs -I % -L1 echo Destroy %
        zfs_list | awk '{if(NR>1) print $2 "@" $3}' | xargs -I % -L1 zfs destroy %
    else
        echo $2 | grep -q "^[0-9]*$" # check if $1 is number or not using regular expression
        if [ $? == 0 ]; then # set ID(s), but no dataset
            all_snap=""
            for i in "$@"; do
                echo $i | grep -q "^[0-9]*$"
                if [ $? == 0 ]; then
                    current_snap=$(zfs_list $i | awk '{if(NR>1) print $2 "@" $3}')
                    all_snap="$all_snap $current_snap"
                fi
            done
            echo $all_snap | xargs -I % -n1 echo Destroy %
            echo $all_snap | xargs -I % -n1 zfs destroy %
        elif [ "$3" == "" ]; then # set dataset only
            zfs_list $2 | awk '{if(NR>1) print $2 "@" $3}' | xargs -I % -L1 echo Destroy %
            zfs_list $2 | awk '{if(NR>1) print $2 "@" $3}' | xargs -I % -L1 zfs destroy %
        else # set both dataset and IDs
            all_snap=""
            for i in "$@"; do
                echo $i | grep -q "^[0-9]*$"
                if [ $? == 0 ]; then
                    current_snap=$(zfs_list $2 $i | awk '{if(NR>1) print $2 "@" $3}')
                    all_snap="$all_snap $current_snap"
                fi
            done
            echo $all_snap | xargs -I % -n1 echo Destroy %
            echo $all_snap | xargs -I % -n1 zfs destroy %
        fi
    fi
}

zfs_import(){
    echo "import not implement yet"
}

zfs_export(){
    echo "export not implement yet"
}

# parsing arguments
while getopts ldei-: op; do
    case $op in
        l)
            function="list" ;;
        d)
            function="delete" ;;
        e)
            function="export" ;;
        i)
            function="import" ;;
        -) # handle --list, --delete, --export, --import arguments
            function=$OPTARG ;;
        *)
            echo "NONE" ;;
    esac
done

# no arguments input, show usage, then exit
if [ "$1" == "" ]; then
        echo "Usage:"
        echo "- create: zfsbak DATASET [ROTATION_CNT]"
        echo "- list: zfsbak -l|--list [DATASET|ID|DATASET ID]"
        echo "- delete: zfsbak -d|--delete [DATASET|ID|DATASET ID]"
        echo "- export: zfsbak -e|--export DATASET [ID]"
        echo "- import: zfsbak -i|--import FILENAME DATASET"
        exit 0
fi

# what function user used
if [ "$function" == "" ]; then
    zfs_create $1 $2
elif [ "$function" == "list" ]; then
    zfs_list $2 $3
elif [ "$function" == "delete" ]; then
    zfs_delete $@
elif [ "$function" == "import" ]; then
    zfs_import
elif [ "$function" == "export" ]; then
    zfs_export
fi