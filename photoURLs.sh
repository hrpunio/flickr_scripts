#!/bin/bash
# Je¿eli nie podano opcji -l log, wszystkie argumenty s± traktowane jako idpsy
#
LOG="upload.log"

if [ ! "$1" = "" ] ; then 
    if [ "$1" = "-l" ] ; then 
      LOG="$2"; shift ; shift
      #echo "LOG file is $LOG" 2>&1
    fi
fi

if [ ! -f "$LOG" ] ; then
      echo "ERROR: $LOG do not exist!" 2>&1 ;
      exit 1;
fi

perl -e '
use LWP::Simple;

# Possible sizes are: [Square][Thumbnail][Small][Medium][Large][Original]
my $selected_url="Thumbnail";
print STDERR "Photos default size is :: $selected_url\n";

my ($p, $current_size, $photo_name);

$log_file = $ARGV[0]; # first argument is log-file name 
@args = @ARGV[1..$#ARGV]; # rest are photo ids
unless (@args ) { print STDERR "Warning *** No idps *** \n"; }

open (LOG, $log_file);

## basic authentication
require ("login2flickr.rc");

while(<LOG>) {
if (! /file/) { next } # skip some lines

  m/name="([^"]*)" id="([^"]*)"/; 

  $f_name = "$1";
  $f_id = $2;
  $f_name =~ s/\.([^\.]+)$//;
  $f_exten = $1;

  if (@args) {
    for $x (@args) {
       $x =~ s/\.([^\.]+)$//;
       if ($f_name eq $x) { getSize($f_name, $f_id, $f_exten); last }
    }
  } else {
      getSize($f_name, $f_id, $f_exten);
  } 
}

sub getSize {
  my $title = shift;
  my $f_id = shift;
  my $exten = shift;

  my $method="flickr.photos.getSizes";
  my $url = "http://www.flickr.com/services/rest/?method=$method&api_key=$api_key&photo_id=$f_id";
  $xml = get $url;

  ## all arguments are treated as photos ids:

  while ( $xml =~ /label="([^"]+)".*source="([^"]+)"/g ) {
   if ($1 eq $selected_url ) { print "$title.$exten => $2 ($f_id)\n"; }
  }}
' $LOG "$@"
