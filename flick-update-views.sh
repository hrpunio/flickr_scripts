#!/bin/bash
ZFILE=00PHTML
DWDSCRIPT=flick-store-views.pl
REPSCRIPT=flick-report-views.pl
GRHSCRIPT=flick-graph-views.pl
GRHFILE=flick-views.png

perl $DWDSCRIPT

## http://steve-parker.org/sh/exitcodes.shtml
if [ "$?" -ne "0" ] ; then echo " *** Problems to store data *** " ; exit 1 ;
else 
  echo "OK: stored"
 fi

perl $REPSCRIPT -zeros -lang=pl  > 00-pl.phtml && \
perl $REPSCRIPT -zeros -lang=en  > 00-en.phtml && \
perl $REPSCRIPT -max=25 -lags -lang=pl > 25-pl.phtml && \
perl $REPSCRIPT -max=25 -lags -lang=en > 25-en.phtml && \
perl $GRHSCRIPT 

if [ "$?" -ne "0" ] ; then echo " *** Problems to produce summaries *** " ; exit 1 ; fi

echo " ** :: OK :: INFORMATION UPDATED :: **"


echo " ** Update remote server:: **"

zip $ZFILE.zip 00*.phtml 25*.phtml flick-views-log.phtml  $GRHFILE &&  \
scp -B $ZFILE.zip tomasz@gnu.univ.gda.pl:Download/$ZFILE.zip && \
ssh tomasz@gnu.univ.gda.pl 'cd Download && unzip -o -d ../public_html/images 00PHTML.zip \
     && cd ../public_html/images && ../../bin/my-patch '
rm -rf $ZFILE.zip
