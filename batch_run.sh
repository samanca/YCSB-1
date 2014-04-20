#!/bin/bash
if [ ! -z $1 ]; then
    FS=$1
else 
    FS="pmfs"
fi

if [ ! -z $2 ]; then
    MODE=$2
else
    MODE="single"
fi

if [ ! -z $3 ]; then
    HOST=$3
else
    HOST="localhost"
fi
USER="root"

# TODO support for replica-sets should be considered

# record start time
BEG=`date +%s`

# remove db log file if exists
ssh "${USER}@${HOST}" "rm -f /root/mongodb/db.log"

# start mongod with --journal
ssh "${USER}@${HOST}" "/root/mongodb/mongo/mongod --dbpath=/mnt/pmfs/db --journal --fork --logpath=/root/mongodb/db.log --logappend"

# running tests
echo "==================== mongod --journal (x1) ==================="
./run_all.sh "$MODE" "$FS" "journal" 1 "$HOST"
sleep 10s

echo "==================== mongod --journal (x4) ==================="
./run_all.sh "$MODE" "$FS" "journal" 4 "$HOST"
sleep 10s

echo "==================== mongod --journal (x16) ==================="
./run_all.sh "$MODE" "$FS" "journal" 16 "$HOST"

# stop running mongod instance
ssh "${USER}@${HOST}" "pkill mongod"
#./kill_mongod.sh 27017 safe
sleep 5s

# cleaning data directory
echo "clean up ..."
ssh "${USER}@${HOST}" "rm -rf /mnt/pmfs/db/*"

# start mongod with --nojournal
ssh "${USER}@${HOST}" "/root/mongodb/mongo/mongod --dbpath=/mnt/pmfs/db --nojournal --fork --logpath=/root/mongodb/db.log --logappend"

# running tests
echo "=================== mongod --nojournal (x1) =================="
./run_all.sh "$MODE" "$FS" "nojournal" 1 "$HOST"
sleep 10s

echo "=================== mongod --nojournal (x4) =================="
./run_all.sh "$MODE" "$FS" "nojournal" 4 "$HOST"
sleep 10s

echo "=================== mongod --nojournal (x16) =================="
./run_all.sh "$MODE" "$FS" "nojournal" 16 "$HOST"

# stop running mongod instance
#./kill_mongod.sh 27017 safe
ssh "${USER}@${HOST}" "pkill mongod"

# print execution time
END=`date +%s`
let EXECTIME="$END - $BEG"
echo "Total execution time = ${EXECTIME}s"
