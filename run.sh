#!/bin/bash
if [ ! -z $1 ]; then
    WL=$1
else
    WL="workloads/workloada"
fi

if [ ! -z $2 ]; then
    DB=$2
else
    DB="test"
fi

if [ ! -z $4 ]; then
    WrConc=$4
else
    WrConc="safe"
fi

if [ ! -z $5 ]; then
    THREADS=$5
else
    THREADS=1
fi

if [ ! -z $6 ]; then
    HOST=$6
else
    HOST="localhost"
fi
REPL="localhost"

# currently, [single] and [replica] modes are treated the same
#if [ ! -z $3 ] && [ "$3" = "single" ]; then
    echo "Single mode"
    ./bin/ycsb load mongodb -P "$WL" -threads "$THREADS" -p mongodb.url="${HOST}:27017" -p mongodb.database="$DB" -p mongodb.writeConcern="$WrConc" 2>err.txt 1>histogram_load.txt
    echo "H-Load complete"
    sleep 3s
    ./bin/ycsb run mongodb -P "$WL" -threads "$THREADS" -p mongodb.url="${HOST}:27017" -p mongodb.database="$DB" -p mongodb.writeConcern="$WrConc" 2>>err.txt 1>histogram_run.txt
    echo "H-Run complete"
    sleep 5s
    ./bin/ycsb load mongodb -P "$WL" -threads "$THREADS" -p mongodb.url="${HOST}:27017" -p mongodb.database="${DB}_2" -p mongodb.writeConcern="$WrConc" -p measurementtype=timeseries -p timeseries.granularity=5 2>>err.txt 1>timeseries_load.txt
    echo "T-Load complete"
    sleep 3s
    ./bin/ycsb run mongodb -P "$WL" -threads "$THREADS" -p mongodb.url="${HOST}:27017" -p mongodb.database="${DB}_2" -p mongodb.writeConcern="$WrConc" -p measurementtype=timeseries -p timeseries.granularity=5 2>>err.txt 1>timeseries_run.txt
    echo "T-Run complete"
#else
#    echo "Replica-Set mode"
#    ./bin/ycsb load mongodb -P "$WL" -threads "$THREADS" -p mongodb.url="${HOST}:27017,${REPL}:27019" -p mongodb.database="$DB" -p mongodb.writeConcern="$WrConc" 2>err.txt 1>histogram_load.txt
#    echo "H-Load complete"
#    sleep 3s
#    ./bin/ycsb run mongodb -P "$WL" -threads "$THREADS" -p mongodb.url="${HOST}:27017,${REPL}:27019" -p mongodb.database="$DB" -p mongodb.writeConcern="$WrConc" 2>>err.txt 1>>histogram_run.txt
#    echo "H-Run complete"
#    sleep 5s
#    ./bin/ycsb load mongodb -P "$WL" -threads "$THREADS" -p mongodb.url="${HOST}:27017,${REPL}:27019" -p mongodb.database="${DB}_2" -p mongodb.writeConcern="$WrConc" -p measurementtype=timeseries -p timeseries.granularity=5 2>>err.txt 1>timeseries_load.txt
#    echo "T-Load complete"
#    sleep 3s
#    ./bin/ycsb run mongodb -P "$WL" -threads "$THREADS" -p mongodb.url="${HOST}:27017,${REPL}:27019" -p mongodb.database="${DB}_2" -p mongodb.writeConcern="$WrConc" -p measurementtype=timeseries -p timeseries.granularity=5  2>>err.txt 1>>timeseries_run.txt
#    echo "T-Run complete"
#fi
./../mongo/mongo --host="${HOST}" "$DB" --eval "db.dropDatabase()"
./../mongo/mongo --host="${HOST}" "${DB}_2" --eval "db.dropDatabase()"
