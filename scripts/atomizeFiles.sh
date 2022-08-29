#/bin/bash

if [ "$#" -ne 1 ]; then
    echo "provide the directory to atomize!"
    exit 0
fi

if [ ! -d "$1" ]; then
    echo "Provided argument $1 is not valid directory"
    exit 0
fi

MAX_FILE_SIZE_MB=256

RANDOM_NUMBER=`date +%N`
TMP_FILE="list${RANDOM_NUMBER}.txt"

echo "Step 1/2: Reading contents of directory..."

find $1 -type f -size +${MAX_FILE_SIZE_MB}M > ${TMP_FILE}
TOTAL_FILES=`cat ${TMP_FILE} | wc -l`

echo "Step 2/2: Atomizing $TOTAL_FILES files..."

CNT=0
while read FILENAME; do
    CNT=$(($CNT+1))
    echo "Atomizing file# ${CNT}: ${FILENAME}"
    split -b ${MAX_FILE_SIZE_MB}M "$FILENAME" "${FILENAME}-part_"
    date -R -r "${FILENAME}" > "${FILENAME}-moddate"
    rm "$FILENAME"
done < ${TMP_FILE}

echo -e "\n Finished."

rm ${TMP_FILE}
