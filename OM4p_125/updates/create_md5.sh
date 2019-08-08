#!/bin/bash

#Julius Busecke: This script creates a new textfile with md5 checksums for all files collected in this folder.
# You can check if the files have been modified with `md5sum -c md5_check.txt`
FILENAME=md5_check.txt

{
if [ -f $FILENAME ]; then
    echo "File already exists. If you really want to recreate it, delete it manually!"
    exit 0
fi
}


touch $FILENAME
find . -name '*.nc' -exec md5sum {} >> $FILENAME \;
