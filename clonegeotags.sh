#!/bin/bash
# Copy GPS coordinates from $1 to $2
#

while test $# -gt 0; do
  case "$1" in
    -help|--help) echo "$usage"; exit 0;;
    -f)  shift; FROM="$1";;
    -f*) FROM="`echo :$1 | sed 's/^:-f//'`";;
    -t)  shift; TO="$1";;
    -t*) TO="`echo :$1 | sed 's/^:-t//'`";;
    -h)  echo usage; exit;;
    -h*) echo usage; exit;;
  esac
  shift
done

# http://wrzasq.pl/blog/52.html
# W skrócie LANG=C zapobiega potraktowaniu przecinka jako kropki dziesiêtnej
exiftool -TagsFromFile $FROM -GPSLatitude -GPSLongitude -GPSLatitudeRef -GPSLongitudeRef $TO
