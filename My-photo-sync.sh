#!/bin/bash
# Usage  photo_sync.sh -d directory -f file.gpx -o time_offset
# Run gpsPhoto.pl with some directory, file, and time_offset (all parameters mandatory)
# Where camera_time - time_offset = GMT_time (used internally by GPS)
# -----

USAGE="$0 -d dir -f file.gpx -t time-offset  _albo_  $0 -d dir -f file.gpx -a"

if test $# -eq 0; then echo "$USAGE" >&2 ;  exit 0 ; fi

while test $# -gt 0; do
  case "$1" in
    -help|--help) echo "$usage"; exit 0;;
       -d) shift; PHOTODIR="$1";;
      -d*) PHOTODIR="`echo :$1 | sed 's/^:-d//'`";;
    -f|-g) shift; FILE="$1";;
  -f*|-g*) FILE="`echo :$1 | sed 's/^:-[fg]//'`";;
    -t|-o)  shift; TOFFSET="$1";;
  -t*|-o*) TOFFSET="`echo :$1 | sed 's/^:-[to]//'`";;
       ## automatyczne okre¶lenie przesuniêcia na podstawie historii
       -a) TOFFSET="`My-exif-datetime | awk '/THIS_CAMERA_OFFSET/{print $(NF-1)}'`";;
  esac
  shift
done

if [ ! -f  "$FILE" ] ; then echo "*** ERROR: File $FILE do not exist!" >&2  ; exit ; fi
if [ ! -d  "$PHOTODIR" ] ; then 
    ##echo "*** ERROR: Directory $PHOTODIR do not exist!" >&2 ; exit ;
    PHOTODIR="." 
 fi
if [ "$TOFFSET" = "" ] ; then echo "*** ERROR: Time offset not specified!" >&2 ; exit ; fi

echo " ***** Directory: $PHOTODIR file: $FILE offset: $TOFFSET *****"

FNAME=`basename $FILE .gpx`

gpsPhoto.pl --dir=$PHOTODIR --gpsfile=$FILE --timeoffset=$TOFFSET --overwrite-geotagged --kml $FNAME.kml

