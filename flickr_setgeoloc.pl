#!/usr/bin/perl
use Flickr::API;
use Data::Dumper;
use Getopt::Long;
use Text::Iconv;

## Warning: tags are expected to contain ISO-8859-2 characters
## I am not using perlio, Encode or encoding pragmas as
## they are not working (invalid signature are returend at best)
use bytes;

my $USAGE='usage: flickr_setgeloc.pl -p photo [-g coordinates] [-l location]
   if \'location\' was specified the location database is searched for; if
   found coordinates are fetched from the database; if not found
   -g \'coordinates\' must be present and specifies coordinates for that location.
   It is an error to specify -g without -l. If you specify -l and
   the location is found in the database, -g is ignored.

   The -g coordinates has the following format \'lat:long\' where
   \'lat\' and \'long\' are decimal numbers.
   Do not precede location with \'loc:\' prefix.

   Examples: flickr_setgeloc.pl -p 12456 -l \'Gdañsk-Osowa#Rondo\'' . "\n";

my ($LAT, $LON, $ACC) = (0, 1, 2);
my ($latitude, $longitude, $accuracy);
my $default_accr = 11;
my $found = 0;

## include utility subroutines:
require 'flickr_utils.rc';

GetOptions("help=s" => \$show_help,
	   "photo=s" => \$photo_id,
	   "geo=s" => \$coord,
           "loc=s" => \$location);

if ( $show_help or (! $photo_id ) or 
   ((! $location ) and (! $coord) )) { 
  print "Photo id = $photo_id location: $location coord: $coord\n" ;
  die "?\n". $USAGE
					  }

# Get locations base
if ( $location ) {
  $konwerter = Text::Iconv->new("iso-8859-2", "utf-8");
  $location = $konwerter->convert($location);
  print "Search [[$location]]\n";

  my $locs_base = './knows/where.flk';
  my %gc = get_mylocation_base($locs_base);
  print "Fetched locations from: $locs_base\n";
  for $loc (keys %gc ) {
    #print "$loc: $gc{$loc}[$LAT]",
    #  " x $gc{$loc}[$LON] x $gc{$loc}[$ACC]\n";
    if ($loc eq $location ) {
        $found = 1;
        $latitude = $gc{$loc}[$LAT];
        $longitude = $gc{$loc}[$LON];

	if ( $gc{$loc}[$ACC] = -1) { $accuracy = $default_accr; }
	else {  $accuracy = $gc{$loc}[$ACC]; }

	last;
    }
  }
  if ($found > 0) {
    print "Found [[$location => lat: $latitude lon: $longitude acc: $accuracy]]\n"; }
  else { print "[[$location]] Not found\n"; }
}


#print "[$latitude]\n";

# There were no location in the database
if ((! $latitude) and ( $found < 1 )) {
  if (! ($coord =~ /:/ )) {die "-geo $coord: bad format\n" . $USAGE }
  ($latitude, $longitude) = split /:/, $coord;
  if ( $location ) {
     $accuracy = $default_accr;
     print "Add $location => lat: $latitude lon: $longitude acc: $accuracy!\n"
  }
  else { die $USAGE }
}

# Authentication:
require 'login2flickr.rc';

print "Add: [$latitude $longitude $accuracy] to [$photo_id]\n";

my $api = new Flickr::API({'key' => $api_key,
   'secret' => $shared_secret } );
##
## http://www.flickr.com/services/api/flickr.photos.geo.setLocation.html
my $response = $api->execute_method('flickr.photos.geo.setLocation',
    { auth_token => $auth_token,
      photo_id   => $photo_id,e
      lat        => $latitude,
      lon        => $longitude,
      accuracy   => $accuracy,
    });

print "Success: $response->{success}\n";
print "Error code: $response->{error_code}\n";
##print Dumper ($response);

