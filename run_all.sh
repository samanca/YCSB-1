#!/bin/bash
if [ ! -z $1 ]; then
    MODE=$1
else
    MODE="single"
fi

if [ ! -z $2 ]; then
    FS=$2
else
    FS="pmfs"
fi

if [ ! -z $3 ]; then
    JOPT=$3
else
    JOPT="journal"
fi

if [ ! -z $4 ]; then
    THC=$4
else
    THC=1
fi

if [ ! -z $5 ]; then
    HOST=$5
else
    HOST="localhost"
fi

# prepare list of write concerns
if [ "$MODE" == "single" ]; then
    WRCONS=("acknowledged" "unacknowledged" "journaled" "fsync_safe" "safe")
else
    WRCONS=("majority" "replicas_safe" "unacknowledged" "safe" "journaled" "fsync_safe")
fi


echo "------------------- $MODE - $FS - $JOPT - $THC ------------------"

for WRCON in "${WRCONS[@]}"
do
    if [ "$JOPT" == "nojournal" ] && [ "$WRCON" == "journaled" ]; then
        continue
    fi
    if [ "$JOPT" == "journal" ] && [ "$WRCON" == "fsync_safe" ]; then
        continue
    fi
    echo "----------------------- Starting $WRCON -----------------------"
    #for L in a b c d e f g h
    for L in a b c d e f
    do
        #if [ "$THC" -gt 1 ] && [ "$L" == "g"]; then
        #    continue
        #fi
        sleep 10s
        WORKLOAD="workloads/workload${L}"
        DB="test_${L}_${WRCON}"
        DIRECTORY="/root/mongodb/experiments/${MODE}/${WRCON}/${FS}/${JOPT}/${L}_${THC}"
        mkdir -p "$DIRECTORY"
        ./run.sh "$WORKLOAD" "$DB" "$MODE" "$WRCON" "$THC" "$HOST" && mv histogram_*.txt timeseries_*.txt "$DIRECTORY" && cat err.txt
        echo "----------------------- TEST $L completed -----------------------"
    done
done
