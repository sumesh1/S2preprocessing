#!/bin/bash

if [ -z "$1" ]
  then
    echo "No config file provided! Aborting"
    exit 1
fi

# read configs
. $1

if [ -z "$2" ]
  then
    echo "please specify level ('L1C' or 'L2A') as second argument"
    echo "e.g. \$bash uploadraster.sh demo.site L1C"
    exit 0
fi
# either L1C or L2A
level=$2

# database connection
psql="psql -d $dbase --username=russwurm --host=$dbhost"

#files="data/bavaria/test/S2A_OPER_PRD_MSIL1C_PDMC_20160522T182438_R065_V20160522T102029_20160522T102029_10m.tif"

# query already present products
productsindb=$($psql -c "Select distinct filename from $dbtable")


echo $psql
while read p;
do

    # select product name
    if [ "$level" = "L1C" ]; then
        product=$p
    elif [ "$level" = "L2A" ]; then
     # predict L2A product name
      product=$(echo $p | sed 's/MSIL1C/MSIL2A/g' | sed 's/OPER/USER/g' )
    fi

    # query if filename does not already exists
    #echo $filename
    if [[ "$productsindb" == *"$p"* ]] ; then
      echo "product $p already in database table $dbtable. skipping..."
      continue
    fi
    echo "loading $p to database"
    raster2pgsql -s $srs -I -C -M $tifpath/$p*.tif -F -t 100x100 $dbtable | $psql
done <$path/$queryfile
# type := 10m, 20m, 60m or SCL

# add columns
$psql <<EOF
\x
ALTER TABLE $dbtable ADD COLUMN IF NOT EXISTS year integer;
ALTER TABLE $dbtable ADD COLUMN IF NOT EXISTS doy integer;
ALTER TABLE $dbtable ADD COLUMN IF NOT EXISTS date date;
ALTER TABLE $dbtable ADD COLUMN IF NOT EXISTS level varchar(5);
ALTER TABLE $dbtable ADD COLUMN IF NOT EXISTS sat varchar(5);
ALTER TABLE $dbtable ADD COLUMN IF NOT EXISTS type varchar(5);
EOF

# add meta information
#$project/conda/bin/python uploadmeta.py $1