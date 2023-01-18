#!/bin/bash

# When there are files named *-initiated in the provided directory,
# run the processing script for the targeted files.

# CONFIGURATION:
# - set values in `iiifify.ini`
# - set up a cron job to run this script every minute

# USAGE:
# /bin/bash /path/to/this/script.sh

## Not using glob anymore so this is unnecessary
## # set the nullglob in case there are no `*-initiated` files
## shopt -s nullglob

LOGDIR=/data/local/logs
SENDER=root@dibs.lib.uchicago.edu
TeamsEmail="dibsiiif_logs - Controlled Digital Lending <c2de5ca3.teams.uchicago.edu@amer.teams.ms>"
RECIPIENT="$TeamsEmail, Matt Teichman <teichman@lib.uchicago.edu>"

DIR=$(dirname "$0")
INI=$DIR/iiifify.ini
STATUS_FILES_DIR=$(source "$INI" && echo "$STATUS_FILES_DIR")
PYTHON=$(source "$INI" && echo "$PYTHON")

# expecting an absolute path as an argument
## for FILE in "$(source "$(dirname "$0")"/iiifify.ini && echo "$STATUS_FILES_DIR")"/*-initiated; do
#  Only process one file so we don't run into a race condition with cron.
#  Use ls -rt to get the oldest entry (i.e., the first checkbox selected by staff)
for FILE in $(ls -tr $STATUS_FILES_DIR/ | grep '^.*-initiated$' | head -1) ; do
    barcode=$(basename "$FILE" | cut -d '-' -f 1)
    TIMESTAMP=$(date "+%Y%m%d_%H%M%S")
    OUTFILE="$LOGDIR/dibsiiif_out_${barcode}_${TIMESTAMP}.txt"
    ## echo "$PYTHON $DIR/dibsiiif.py \"$barcode\" > $OUTFILE 2>&1"
    $PYTHON $DIR/dibsiiif.py "$barcode" > $OUTFILE 2>&1
    if [ -s "$OUTFILE" ]; then
        SUBJECT="dibsiiif error on barcode: $barcode"
        ## cat $OUTFILE | mail -s "${SUBJECT}" "${RECIPIENT}" -sendmail-option -f${SENDER}
        cat $OUTFILE | /host/bin/cronmail -s "${SUBJECT}" "${RECIPIENT}"
    else
        rm "$OUTFILE"
    fi
done
