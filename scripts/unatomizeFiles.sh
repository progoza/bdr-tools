#/bin/bash

if [ "$#" -ne 1 ]; then
    echo "provide the directory to unatomize!"
    exit 0
fi

if [ ! -d "$1" ]; then
    echo "Provided argument $1 is not valid directory"
    exit 0
fi

echo "Step 1/2: Searching for atomized files...."
RANDOM_NUMBER=`date +%N`
TMP_FILENAME="list${RANDOM_NUMBER}.txt"

find $1 -type f -name "*-part_aa" > $TMP_FILENAME

TOTAL_FILES=`cat $TMP_FILENAME | wc -l`

echo "Step 2/2: Unatomizing $TOTAL_FILES files..."

CNT=0

while read FILENAME; do
    ORIGINAL_FILENAME_NO_ESC=`echo "$FILENAME" | sed "s/-part_aa//g"`
    ORIGINAL_FILENAME="$ORIGINAL_FILENAME_NO_ESC"
    CNT=$(($CNT+1))
    echo "Unatomizing file# ${CNT}: ${ORIGINAL_FILENAME}"
    cat "${ORIGINAL_FILENAME}"-part_?? > "${ORIGINAL_FILENAME}"
    rm "${ORIGINAL_FILENAME}"-part_??
    MODDATE=`cat "${ORIGINAL_FILENAME}-moddate"`
    rm "${ORIGINAL_FILENAME}-moddate"
    touch -d "${MODDATE}" "${ORIGINAL_FILENAME}"
done < $TMP_FILENAME

echo -e "\n Finished."

rm $TMP_FILENAME
