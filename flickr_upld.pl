#!/usr/bin/perl
# Flickr upload preprocessor with simpler syntax. This script runs flickr_xload.pl via system
# command to do actual upload. Useful in combination w Emacs to speed-up photo(s) description.
#
# (c) T.Przechlewski 12/2007 (tprzechlewski@acm.org)
# One can distribute/modify the file under the terms of the GNU General Public License.
#
# cf. http://gnu.univ.gda.pl/~tomasz/prog/perl/scripts/flickr/scripts/
#
use Text::Iconv;
use Image::ExifTool; 
use Geo::Coordinates::DecimalDegrees;
use Getopt::Long;
use bytes;

my $locs_base = "$ENV{HOME}/.flickr/knows/where.flk";
my $perl_site_dir = '/usr/local/lib/perl5/site_perl';
## http://www.flickr.com/services/api/flickr.photos.geo.setLocation.html
my $default_accuracy = 11; # my default accuracy
my $accuracy = 16 ; # flickr default if not changed
##
## my $verbose = 1;

my $USAGE = 'flupload [-title tytul] [-keys kw1,kw2...] [-geo loc ] [-lrot|rrot] [-sets sets] [-file filespec]
    gdzie -title title = photo title
          -kw kw1,kw2... = keywords
          -geo location = location
          -lrot | -rrot = rotation (left and right)
          -sets sets = sets
          -pool pools = groups
          -file filespec = filespec ' .
           "\n";

GetOptions(
	   "script=s" => \$Script, ## read descriptions from the file $Script
           "descr=s"  => \$description, ## description
           "file=s"   => \$file2proc,
           "geo=s"    => \$location,
	   "help|?"   => \$showhelp,
	   "keys=s"   => \$tags,
           "lrot"     => \$rotateleft,
	   "matched"  => \$matchedtags,
           "rrot"     => \$rotateright,
           "sets=s"   => \$insets,
           "pool=s"   => \$inpools,
           "title=s"  => \$title,
);

if ( $showhelp ) { die $USAGE  ;  }
if ( ! $file2proc ) {  $file2proc = "*.jpg" }; ##

my ($LAT, $LON, $ACC) = (0, 1, 2);
## latitude/longitude, ie. 54.43894/18.54995 (for Sopot, nearby my house)
my ($latitude, $longitude );
## include utility subroutines/authentication:
require 'flickr_utils.rc';
require 'login2flickr.rc';

$conv = Text::Iconv->new("iso-8859-2", "UTF-8");
$vnoc = Text::Iconv->new("UTF-8", "iso-8859-2");

## reading photo(s) descriptions from file:

if ($Script) {
  print STDERR "** Fetched photo(s) descriptons from: $Script\n";
  ## Read from stdin:
  open (SF, "<$Script") or die "** Problems reading $Script **";
  #open SF, "<$Script" || die "** Problems reading $Script **"; ## wrong : open () || die ...

  while (<SF>) {
    my ($file2proc, $location, $tags, $insets, $inpools, $title, $rotateleft);
    my ($rotateright, $description, $arguments );

    chomp($_);

    ## Stop mark
    if ($_ =~ /^#+[ \t]*STOP[ \t]*#+[ \t]*$/) { die "Stop!\n" }
    # skip empty lines and the ones starting with `#':
    if ( ($_ =~ /^[ \t]*$/) || ($_ =~ /^#/)) { next }

    $_ =~ s/^([^ \t]+)[ \t]+\>\>[ \t]*//; $file2proc = $1 ;

    my @photodscr = split /\@/, $_ ; # each field starts with @ sign

    for $f (@photodscr ) {
      if ($f =~ /^g/)    { $location = field($f) }    # @g g-location
      if ($f =~ /^k/)    { $tags = field($f) }        # @k keywords
      if ($f =~ /^lrot/) { $rotateleft = 90 }         # @lrot
      if ($f =~ /^rrot/) { $rotateright = 270 }       # @rrot
      if ($f =~ /^s/)    { $insets = field($f) }      # @s sets
      if ($f =~ /^p/)    { $inpools = field($f) }     # @p pools
      if ($f =~ /^t/)    { $title = field($f) }       # @t title
      if ($f =~ /^d/)    { $description = field($f) } # @d description
      if ($f =~ /^c/)    { $credentials = field($f) } # @d credentials (creator name)
      if ($f =~ /^a/)    { $arguments = field($f) }   # @a arguments passed verbatim
    }
    my $rot = $rotateleft || $rotateright ; # giving both is a non-sense
    process_file ($file2proc, $location, $tags, $insets, $inpools, $title, $rot, 
        $description, $arguments, $credentials );
    #print "** $file2proc#$location=$tags=$insets=$inpools=$title=$rot\n";
    print "** ==========================================================\n\n";
    
  }

}
##
## reading photo(s) descriptions from the command line:
else {
  # Geocorrdinates
  if ($rotateleft) { $rot = $rotateleft }
  elsif ( $rotateright) { $rot = $rotateright } ; # giving both is a non-sense

  process_file ($file2proc, $location, $tags, $insets, $inpools, $title, $rot, $description, $arguments );
}


# /////////////
sub process_file {
  my ( $file2proc, $location, $tags, $insets, $inpools, $title, $rot, $descr, $xargs, $creds ) = @_ ;
  my ($ori_location, $geotagged, $auto_geotagged );

  my $exifTool = new Image::ExifTool;
  my $photo_info = $exifTool->ImageInfo($file2proc);
  my $gcrds = $exifTool->GetValue('GPSLatitude'); # is already geotagged

  if ( $location && $location !~ /^(#|=)/) {
    $ori_location = $location; # $location encoded with iso-8859-2

    $location = $conv->convert($location);
    if ($verbose) { print STDERR "** Search [$location]\n"; }

    my %gc = get_mylocation_base($locs_base);
    # 0 + keys %gc returns # of locations
    print STDERR "** Fetched ", 0 + keys %gc,  " locations from: $locs_base\n";
    for $loc (keys %gc ) {

      if ($loc eq $location ) {
        $geotagged = 1;
        $latitude = $gc{$loc}[$LAT];
        $longitude = $gc{$loc}[$LON];
	if ( $gc{$loc}[$ACC] = -1) { $accuracy = $default_accuracy; }
	else {  $accuracy = $gc{$loc}[$ACC] }

	last;
      }
    }
    if ($geotagged > 0) {
      print STDERR "** Photo location [$location: $latitude/$longitude/$accuracy]\n"; }
    else { die "** Error: [$location] not found\n"; }
  }
  ### GPS coordinates explicity given as #lat:lon
  elsif ( $location && $location =~ /^#/ ) { $location =~ s/^#[ \t]*//; # remove leading hash
    print STDERR "** Coordinates for [$file2proc] given explicitly... \n";

    ## $latitude:$longitude ie. 54.43894/18.54995 (for Sopot, nearby my house)
    ($latitude, $longitude) = split (/:/, $location);
    #$accuracy ## assume max accuracy if coordinates explicity given
    $location = ''; ## location is empty to avoid assigning geo:loc (see below)
    $geotagged = 1;
  }
  ### GPS coordinates explicity given as other file name after `='
  elsif ( $location && $location =~ /^=/ ) { $location =~ s/^=[ \t]*//;  # nazwa pliku
    my $exifTool2 = new Image::ExifTool;
    my $other_photo_info = $exifTool2->ImageInfo($location);
    my $gcrds2 = $exifTool2->GetValue('GPSLatitude'); # is already geotagged

    $location = ''; ## location is empty to avoid assigning geo:loc (see below)

    if (defined($gcrds2)) {
      $latitude = dms_str2dec ($exifTool2->GetValue('GPSLatitude') );
      $longitude = dms_str2dec ($exifTool2->GetValue('GPSLongitude'));
      $geotagged = 1;
      $auto_geotagged = 0;
    }
    else { die " *** File $gcrds2 does not contains GEO coordinates!\n ***"; }
  }
  elsif ( defined($gcrds) ) {
    print STDERR "** Photo [$file2proc] contains location coordinates...\n";
    ## conversion is needed:
    ##  $decimal_degrees = dms2decimal($degrees, $minutes, $seconds);
    $latitude = dms_str2dec ($exifTool->GetValue('GPSLatitude') );
    $longitude = dms_str2dec ($exifTool->GetValue('GPSLongitude'));
    $geotagged = 1;
    $auto_geotagged = 1;
  }

  if ($geotagged == 0) { print STDERR "** No geocoordinates for [$file2proc]...\n";}

  else { $geo_lon_str = sprintf "geo:lon=%.6f", $longitude;
     $geo_lat_str = sprintf "geo:lat=%.6f", $latitude }

  if ( $tags ) {
    my @tags=(); @tags = split /,/, $tags;
    for $t (@tags) { $t =~ s/^[ \t]+|[ \t]$//; $t=~ s/_/ /g; $t="\"$t\""; }

    # add geo:tags, geotags are oneword
    if ( $geotagged) { push @tags, ($geo_lon_str, $geo_lat_str);
        if ($location) { push (@tags, "geo:loc=$ori_location") }  }

    $tags = $conv->convert("@tags");

    if ($verbose) { print STDERR "** Photo tags: [$tags]\n"; }

  } elsif ($geotagged > 0 ) {# No tags but valid location was passed
    $tags = "$geo_lon_str " . "$geo_lat_str" ;

    if ($location) { $tags .= " geo:loc=$ori_location" }

    $tags = $conv->convert("$tags");
  }

  # If auto geotagged add appriopriate tags:
  if ($verbose) { print "$file2proc :: gcrds: $gcrds $auto_geotagged\n"; }

  if ( $title ) { print STDERR "** Photo title: $title\n"; }

  my @args = ("perl", "$perl_site_dir/flickr_xload.pl");

  if ($title)     { push  @args, ("--title", "$title") }
  if ($descr)     { push  @args, ("--description", $conv->convert($descr)) }
  if ($creds)     { push  @args, ("--credentials", $conv->convert($creds)) }
  if ($xargs)     { push  ( @args, (split (/[ "]+/, $conv->($xargs))) ) }

  if ($rot)       { push  @args, ("--rot", "$rot") }
  if ($insets)    { push  @args, ("--set", "$insets") }
  if ($inpools)   { push  @args, ("--pool", "$inpools") }
  if ($tags)      { push  @args, ("--tag", "$tags") } ## no need for "'$tags'"
  if ($geotagged) { push  @args, ("--gt", "$latitude:$longitude:$location:$accuracy")  }
  ## do not update GPSLatitude GPSLongitude, etc:
  if ($auto_geotagged) {push  @args, ("--preserve-geo") }

  push  @args, "$file2proc";

  if ($verbose) { print STDERR ">> @args <<\n"; } ### print "@args\n";
  #print STDERR "** Uploading Photo...\n";
  system(@args) == 0 or die "** system command [ @args ] failed: $? **";

} ## process_file

sub dms_str2dec {# the argument is something like: 18 deg 32' 49.06
    my $str = shift @_;
    my $sign ;

    ## Poprawka na biegun/półkulę (N/E dodatnie; S/W ujemne)
    ##my ($d, $m, $s) = $str =~ m/([-+]?[0-9]+)[^0-9]+([0-9]+)[^0-9]+([0-9\.]+)/;
    ##41 deg 8' 49.93" N 8 deg 36' 56.27" W
    my ($d, $m, $s, $sign) = $str =~ m/([-+]?[0-9]+)[^0-9]+([0-9]+)[^0-9]+([0-9\.]+)[^0-9EWSN,]+([EWSN])/;

    if ($verbose) { print "dms: $str = $d, $m, $s\n"; }
    if (defined($d)) { 
      if ($sign eq 'W' || $sign eq 'S') { $sign = -1 }
      elsif ( $sign eq 'E' || $sign eq 'N' ) { $sign = 1 }
      else {   die "*** Wrong geocoordinate format: $d, $m, $s, $sign"; }

     ##return (dms2decimal($d, $m, $s)); 
     return ( $sign * dms2decimal($d, $m, $s));
    }

    else { die "*** Strange coordinated [$str] cannot convert *** " }
}

sub field {# process field, field starts with single letter
  my $f = shift @_;

  $f =~ s/^[ \t]+|[ \t]+$//g; ## remove leading/trailing spaces
  $f =~ s/^[^ \t]+[ \t]*//g; ## remove field descriptor + possible following spaces

  return $f;

}
