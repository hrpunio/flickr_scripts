#!/bin/bash
# Usage:  to_thumb.sh -i in_file -o out_file [ -r angle ]
#
# Generate thumbnail from `in_file' to `out_file'. Rotate `out_file' by specified angle 
# if -r parameter  is present. Geotagged images are labelled with red rectagle in upper-left 
# corner. Auxilliary perl script photo_exif is used to detect if the photo is geotagged...
# 
ROT=""

while test $# -gt 0; do
  case "$1" in
    -i)  shift; IN="$1";;
    -o)  shift; OUT="$1";;
    -r)  shift; ROT="-rotate $1";;
  esac
  shift
done

# if GPSLatitude is defined returns OK
GPS=`photo_exif $IN  GPSLatitude` 

if [ "$GPS" = "OK" ] ; then 
  ## http://www.win.tue.nl/~aeb/linux/misc/convert/convert-draw-text.html
  convert -size 250x250 "$IN" -resize 250x250 +profile '*' $ROT -fill red -draw 'rectangle 0,0 33,33' "$OUT"
else 
  convert -size 250x250 "$IN" -resize 250x250 +profile '*' $ROT "$OUT"
fi
