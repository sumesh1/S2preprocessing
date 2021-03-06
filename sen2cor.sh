#!/bin/bash

# Runs sen2cor on all products, which are located in the L1C folder (defined by site.cfg)
#
# usage sh sen2cor.sh site.cfg
#

# read configs
. $1

# flag -delete for deletion of previous step or -single
flag=$2

L2AProcess="Sen2Cor-2.4.0-Linux64/bin/L2A_Process"

# default to project root config file if not set
if [ -z "$L2A_GIPP_path" ]; then
    L2A_GIPP_path=$project/cfg/L2A_GIPP.xml
fi

# for every line in the results file shuf shuffles sequence such that multiple processes will process a different sequence
cat $path/sen2cor.todo | shuf | while read product
do

    L2Aproductname=$(echo $product | sed 's/MSIL1C/MSIL2A/g' | sed 's/OPER/USER/g' )

    if [ "$flag" = "-delete" ]; then 
        echo "deleting previous $L2Aproductname.SAFE" 
        rm -r $path/$L2Aproductname.SAFE
    fi

    echo $(echo date "+%Y-%m-%d %H:%M:%S")" sen2cor: "$product" -> "$L2Aproductname
    #echo "$L2AProcess $path/$product.SAFE --GIP_L2A $L2A_GIPP_path > $path/$L2Aproductname.sen2cor"
    $L2AProcess $path/$product.SAFE --GIP_L2A $L2A_GIPP_path > $path/$L2Aproductname.sen2cor

    # stop loop after one image
    if [ "$flag" = "-single" ]; then 
        break
    fi

done

# delete folders of unsuccessfull processes (but leave log files)
#sh sen2cordeletefails.sh $1
