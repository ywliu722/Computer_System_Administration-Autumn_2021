#!/bin/sh

filename=$(echo "$1" | awk -F "usr" '{print $2}')
file_type=$(echo "$filename" | awk -F "." '{print $NF}')
target="/home/ftp/hidden/.exe/"

if [ $file_type == "exe" ]; then
        msg="$filename violate file detected. Uploaded by $UPLOAD_USER."
        logger -p local0.info -i -t tfpuscr $msg
        mv $filename $target
fi
