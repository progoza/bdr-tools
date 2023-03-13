#!/bin/bash


REL_BASE_DIR="undef"

BDR=24900000000
DVD=4690000000
CD=690000000
VOL_SIZE=$BDR

while getopts r:s: name; do
    case $name in
    r)  REL_BASE_DIR="$OPTARG" ;;
    s)  if [ "$OPTARG" == "cd" ] ; then 
            VOL_SIZE=$CD
        elif [ "$OPTARG" == "dvd" ] ; then 
            VOL_SIZE=$DVD
        elif [ "$OPTARG" == "bdr" ] ; then
            VOL_SIZE=$BDR
        else 
            VOL_SIZE="$OPTARG"
        fi ;;
    ?)  printf "Usage: splitToVolumes.sh [-r <base-relative-directory>] [-s <size>] directories-to-split* \n   Note: pre-defined contants 'cd', 'dvd' and 'bdr' can be used for size."
    esac
done

MIN_SIZE=10000000

if [ "$VOL_SIZE" -lt "$MIN_SIZE" ] ; then
    echo "ERROR: size cannot be smaller than $MIN_SIZE"
    exit 0
else
    echo "Info: size of volume set to $VOL_SIZE"
fi

if [ -d "$REL_BASE_DIR" ]; then
     echo "Info: Using $REL_BASE_DIR as the base directory for the iso fs"
elif [ "$REL_BASE_DIR" != "undef" ]; then
    echo "ERROR: provided directory $REL_BASE_DIR does not exist"
    exit 0
fi

shift $(($OPTIND - 1))

if [ "$#" -lt 1 ]; then
    echo "ERROR: provide at least 1 directory to split!"
    exit 0
fi

if [ "$REL_BASE_DIR" == "undef" ]; then
    REL_BASE_DIR=$1
fi

RANDOM_NUMBER=`date +%N`
TMP_FILE="list${RANDOM_NUMBER}.txt"
touch $TMP_FILE

echo "Step 1/2: Reading contents of directory..."


for a_dir in "$@"
do
    if [ ! -d "${a_dir}" ]; then
        echo "Provided argument ${a_dir} is not valid directory"
        rm $TMP_FILE
        exit 0
    fi
    echo "Info: adding files from ${a_dir}..."
    find $a_dir -type f | sort >> $TMP_FILE
done

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
    
    if [ $FILE_SIZE -gt $VOL_SIZE ]
    then
        echo "\nError: File $FILENAME is larger than max volume size, skipping"
    else
        POTENTIAL_NEW_VOL_SIZE=$(($CURR_VOL_SIZE + $FILE_SIZE))
        if [ $POTENTIAL_NEW_VOL_SIZE -gt $VOL_SIZE ]
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

