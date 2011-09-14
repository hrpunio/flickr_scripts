#!/bin/bash
# Get Data from Garmin GPS Receiver with some post-processing
#
TODAY=`date +"%Y%m%d"`
## RS-323 (Etrex):
## DEVICE=/dev/ttyS0
## USB (Legend):
DEVICE=/dev/ttyUSB0

while test $# -gt 0; do
  case "$1" in
    -help|--help) echo "$usage"; exit 0;;
     ## Domy¶lnie importuj tylko ¶lad, z opcj± -all wszystko:
    -all)  shift; ALL="-r -w";;
    -etrex)  shift; DEVICE="/dev/ttyS0";;
    -rs)  shift; DEVICE="/dev/ttyS0";;
  esac
  shift
done

echo gpsbabel $ALL -t -i garmin -f $DEVICE -o gpx -F "$TODAY.gpx"

gpsbabel $ALL -t -i garmin -f $DEVICE -o gpx -F "$TODAY.gpx" && \
perl -i.bak -ne '
  if (/<\?xml version=/) { 
    print "<?xml version=\"1.0\" encoding=\"ISO-8859-2\" standalone=\"yes\"?>\n"; next }
  # dodaj po pierwszym elemencie <time> nag³ówek
  if (/^<time>/ && $done == 0) {
    print "<author>tomasz przechlewski</author>\n";
    print "<email>tprzechlewski[at]acm.org</email>\n";
    print "<url>http://gnu.univ.gda.pl/~tomasz/Geo/gpx</url>\n";
    print $_ ; $done++ } 
  else { print $_ ;  } ' "$TODAY.gpx" && \
echo "*** Consider to reduce trace data with gpsbabel -x simplify,count=500 ... "
echo "*** Geocode photos with gpsPhoto.pl: My-photo-sync.sh -d dir -f $TODAY.gpx -o time_offset "
echo "*** Compute time offset: My-exif-datetime -f photo_of_GPS -b time_displayed "
#
