#/bin/bash

if [ "$#" < 1 ]; then
    echo "provide the directory to split!"
    exit 0
fi

if [ ! -d "$1" ]; then
    echo "Provided argument $1 is not valid directory"
    exit 0
fi

RANDOM_NUMBER=`date +%N`
TMP_FILE="list${RANDOM_NUMBER}.txt"

REL_BASE_DIR=$1

if [ -d "$2" ]; then
     REL_BASE_DIR=$2
     echo "Using $2 as the base directory for the iso fs"
fi

# BD-R MAX_VOL_SIZE=24900000000
# DVD. MAX_VOL_SIZE=4690000000
# CD.. MAX_VOL_SIZE=690000000
# custom MAX_VOL_SIZE=100000000

MAX_VOL_SIZE=24900000000

echo "Step 1/2: Reading contents of directory..."

find $1 -type f | sort > $TMP_FILE
TOTAL_FILES=`cat ${TMP_FILE} | wc -l`

echo "Step 2/2: Splitting $TOTAL_FILES into volumes..."

rm -rf ./volume_*.list
        
CURR_VOL_SIZE=0
CURR_VOL_NR=1001
CNT=0
PROGRESS_REFRESH=3
CURR_TIME=$((`date +%s`/$PROGRESS_REFRESH))
START_TIME=`date +%s`

while read FILENAME; do
    
    FILE_SIZE=`stat -c%s "$FILENAME"`
    
    if [ $FILE_SIZE -gt $MAX_VOL_SIZE ]
    then
        echo "\nError: File $FILENAME is larger than max volume size, skipping"
    else
        POTENTIAL_NEW_VOL_SIZE=$(($CURR_VOL_SIZE + $FILE_SIZE))
        if [ $POTENTIAL_NEW_VOL_SIZE -gt $MAX_VOL_SIZE ]
        then
             CURR_VOL_NR=$(($CURR_VOL_NR + 1))
             CURR_VOL_SIZE=$FILE_SIZE
        else
             CURR_VOL_SIZE=$POTENTIAL_NEW_VOL_SIZE
        fi;
        REAL_PATH=`realpath --relative-base=$REL_BASE_DIR "$FILENAME"`
        ABS_PATH=`realpath "$FILENAME"`
        echo "/${REAL_PATH}=${ABS_PATH}" >> volume_$CURR_VOL_NR.list
    fi
    
    CNT=$(($CNT+1))
    
    NEW_TIME=$((`date +%s`/$PROGRESS_REFRESH))
    if [ $CURR_TIME -ne $NEW_TIME ] 
    then
        CURR_TIME=$NEW_TIME
        PROGRESS_PREC=$(($CNT*1000/$TOTAL_FILES))
        PROGRESS_P=$(($PROGRESS_PREC/10))
        PROGRESS_D=$(($PROGRESS_PREC%10))
        DURATION=$((`date +%s`-$START_TIME))
        DURATION_MIN=$(($DURATION/60))
        DURATION_SEC=$(($DURATION%60))
        echo -ne "\rDone ${PROGRESS_P}.${PROGRESS_D}% ($CNT of $TOTAL_FILES), took ${DURATION_MIN}min ${DURATION_SEC}s. "
    fi
done < ${TMP_FILE}

echo -e "\n Finished."
rm ${TMP_FILE}

