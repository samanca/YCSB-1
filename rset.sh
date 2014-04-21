#!/bin/bash
if [ ! -z $1 ]; then
    PRIMARY=$1
else
    PRIMARY="10.1.1.23"
fi

if [ ! -z $2 ]; then
    SECONDARY=$2
else
    SECONDARY="10.1.1.25"
fi

if [ ! -z $3 ]; then
    ARBITER=$3
else
    ARBITER="10.1.1.23"
fi

if [ ! -z $4 ]; then
    MONGO=$4
else
    MONGO="$HOME/mongodb/mongo/mongo"
fi

if [ ! -z $5 ]; then
    JOURNAL_MODE="$5"
else
    JOURNAL_MODE="journal"
fi

BASEPATH="/tmp/mongo_"
MONGOPATH="/root/mongodb/omongo"

# record start time
BEG=`date +%s`

# initialize PRIMARY
DBPATH="${BASEPATH}p"
ssh root@$PRIMARY "[ ! -d $DBPATH ] && mkdir $DBPATH && chmod 777 $DBPATH"
ssh root@$PRIMARY "rm -rf ${DBPATH}/*"
ssh root@$PRIMARY "rm -f /tmp/mongodb_p.log"
TEMP=`ssh root@$PRIMARY "${MONGOPATH}/mongod --dbpath=$DBPATH --replSet=rs0 --smallfiles --oplogSize=128 --port=27017 --$JOURNAL_MODE --fork --logpath=/tmp/mongodb_p.log --logappend"`
PRPID=`echo $TEMP | grep -o '[0-9]\+'`

# initialize SECONDARY
DBPATH="${BASEPATH}s"
ssh root@$SECONDARY "[ ! -d $DBPATH ] && mkdir $DBPATH && chmod 777 $DBPATH"
ssh root@$SECONDARY "rm -rf ${DBPATH}/*"
ssh root@$PRIMARY "rm -f /tmp/mongodb_s.log"
TEMP=`ssh root@$SECONDARY "${MONGOPATH}/mongod --dbpath=$DBPATH --replSet=rs0 --smallfiles --oplogSize=128 --port=27018 --$JOURNAL_MODE --fork --logpath=/tmp/mongodb_s.log --logappend"`
SCPID=`echo $TEMP | grep -o '[0-9]\+'`

# initialize ARBITER
DBPATH="${BASEPATH}a"
ssh root@$ARBITER "[ ! -d $DBPATH ] && mkdir $DBPATH && chmod 777 $DBPATH"
ssh root@$ARBITER "rm -rf ${DBPATH}/*"
ssh root@$PRIMARY "rm -f /tmp/mongodb_a.log"
TEMP=`ssh root@$ARBITER "${MONGOPATH}/mongod --dbpath=$DBPATH --replSet=rs0  --smallfiles --oplogSize=128 --port=27019 --$JOURNAL_MODE --fork --logpath=/tmp/mongodb_a.log --logappend"`
ABPID=`echo $TEMP | grep -o '[0-9]\+'`

echo "All instances are up and running ..."

# setup replica-set
#echo "rs.initiate(); rs.reconfig({ _id: \"rs0\", members: [ { _id: 0, host: \"$PRIMARY:27017\", arbiterOnly: false, priority: 2 }, { _id: 1, host: \"$SECONDARY:27018\", arbiterOnly: false, priority: 1 }, { _id: 2, host: \"$ARBITER:27019\", arbiterOnly: true, priority: 0 } ] });" > setup.js
#../omongo/mongo --host=$PRIMARY --eval  "rs.initiate(); rs.reconfig({ _id: \"rs0\", members: [ { _id: 0, host: \"$PRIMARY:27017\", arbiterOnly: false, priority: 2 }, { _id: 1, host: \"$SECONDARY:27018\", arbiterOnly: false, priority: 1 }, { _id: 2, host: \"$ARBITER:27019\", arbiterOnly: true, priority: 0 } ] });"
#../omongo/mongo --host=$PRIMARY --eval `cat setup.js`
#rm -f setup.js

# wait for user to confirm
read -p "Check rs.status() and press Y once the replicaSet is ready or N if there is any error:`echo $'\n> '`" -n1 INPUT
echo ""
if [ "$INPUT" == "Y" ] || [ "$INPUT" == "y" ]; then

    echo "start running tests ..."
    FS="pmfs"

    # running tests
    echo "==================== mongod --$JOURNAL_MODE (x1) ==================="
    ./run_all.sh "replica" "$FS" "$JOURNAL_MODE" 1 "$PRIMARY"
    sleep 10s

    echo "==================== mongod --$JOURNAL_MODE (x4) ==================="
    ./run_all.sh "replica" "$FS" "$JOURNAL_MODE" 4 "$PRIMARY"
    sleep 10s

    echo "==================== mongod --$JOURNAL_MODE (x16) ==================="
    ./run_all.sh "replica" "$FS" "$JOURNAL_MODE" 16 "$PRIMARY"
fi

# cleanup
ssh root@$PRIMARY "kill $PRPID"
ssh root@$SECONDARY "kill $SCPID"
ssh root@$ARBITER "kill $ABPID"

# print execution time
END=`date +%s`
let EXECTIME="$END - $BEG"
echo "Total execution time = ${EXECTIME}s"
