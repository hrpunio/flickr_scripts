#!/bin/bash
# http://wiki.openstreetmap.org/index.php/MakingGpxTracks
# Reduce size of GPS trace with gpsbabel
if test $# -eq 0; then
  echo "`basename $0`: Brakuje nazwy pliku GPX." >&2
  exit 0
fi

OUTFILE=`basename $1 .gpx`
MAXCNTP=500
gpsbabel -i gpx -f $1 -x simplify,count=${MAXCNTP} -o gpx -F ${OUTFILE}-s.gpx
