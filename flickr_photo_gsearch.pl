#!/usr/bin/perl 
#
# http://code.flickr.com/blog/2008/08/19/standard-photos-response-apis-for-civilized-age/
# Wyszukuje zdjêcia wg. tagów; generuje plik GPX dla zdjêæ zawieraj±cych wsp. geo
use strict;

use XML::LibXML;
use LWP::Simple;
use Getopt::Long;

require 'login2flickr.rc';

our $api_key;
our $my_flickr_id;

my $tags_txt;
my $show_help;
my ($user_id, $all_users, $report_views);
my @Photos;

GetOptions(
     "help"   => \$show_help,
     "all"    => \$all_users,
     "user=s" => \$user_id,
     "views"  => \$report_views,
     "tags=s" => \$tags_txt);

unless ( $user_id ) {  $user_id = $my_flickr_id; }
if ( $all_users ) { $user_id = ''; } ## search all photos

my $parser = XML::LibXML->new;
my $pageno;
my $method = 'flickr.photos.search';
my $max_per_page = 500;
my ($total_pages, $current_page);

my $search_query =  "&extras=geo,views"; # http://www.flickr.com/services/api/flickr.photos.search.html
if ( $user_id ) { $search_query .=  "&user_id=$user_id";  }
if ( $tags_txt ) { $search_query .=  "&tags=$tags_txt" }

printf STDERR " *** Looking for %s's photos with tags: %s\n", $user_id, $tags_txt;

do {
   $pageno++;
#  user_id=$user_id 
#  The NSID of the user who's photo to search. If this parameter isn't passed then everybody's public photos will be searched
   my $resp = query_flickr( "method=$method&api_key=$api_key&per_page=$max_per_page&page=$pageno" . $search_query );

   unless (check_flickr_resp($resp) eq 'ok') { die "Problems with retriving photo list!\n" }

   my $photos = $parser->parse_string($resp);

   $total_pages = $photos->getElementsByTagName('photos' )->[0]->getAttribute('pages' );
   $current_page = $photos->getElementsByTagName('photos' )->[0]->getAttribute('page' );

   push @Photos, $photos->getElementsByTagName('photo' );

   printf STDERR " *** Page %d  of %d retreived...\n", $current_page, $total_pages;

} while ( $current_page < $total_pages  );

my ($resp, $photo_id, $owner_id, $flickr_id, $flickr_ext);
my ($lat, $lon, $rep_views);
my $viewsNo = 0;
my $skipped = 0;

gpx_header();

for my $p (@Photos) {
      $photo_id = $p->getAttribute( 'id' );
      $owner_id = $p->getAttribute( 'owner' );
      $viewsNo = $p->getAttribute( 'views' );

      if ($report_views) { $rep_views = "title='Views #: $viewsNo' "; }
      else { $rep_views = '' }

      $flickr_id = sprintf ("%s/%s_%s", $p->getAttribute( 'server' ),
         $photo_id, $p->getAttribute( 'secret' ));

      $flickr_ext = "<extensions><html><![CDATA[<a href='http://www.flickr.com/$owner_id/$photo_id/' target='_blank'>" .
	"<img ${rep_views}src='http://static.flickr.com/${flickr_id}_m.jpg' /></a>]]></html></extensions>\n";

      if ( ( $lat = $p->getAttribute( 'latitude' )) &&  ($lon = $p->getAttribute( 'longitude' )) ) {# photo is geotagged:
	printf "<wpt lat=\"%.6f\" lon=\"%.6f\"><name>%s</name>$flickr_ext</wpt>\n", $lat, $lon, $photo_id, $flickr_id;
      } else { $skipped++; } # skip photos w/o geolocation
}

print "</gpx>\n";

print STDERR " *** Photos w/o geolocations are skipped\n";
print STDERR " *** Total $#Photos photos processed ($skipped skipped)*** \n";

##
sub query_flickr {
  my $url =  shift ; ## np.  "http://www.flickr.com/services/rest/?method=$method&api_key=$api_key&photo_id=$photo_id";
  return ( get ( "http://www.flickr.com/services/rest/?" . $url ) ); ## resp is an XML file
}

sub check_flickr_resp {
  my $resp = shift ;
  my $doc = $parser->parse_string($resp);
  if ( my $root = $doc->getElementsByTagName('rsp' )->[0] ) {
    return ( $root->getAttribute( 'stat' ) ); }
}

sub gpx_header {

print '<?xml version="1.0" encoding="UTF-8"?>
<gpx version="1.0" creator="Perl"
xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns="http://www.topografix.com/GPX/1/0"
xsi:schemaLocation="http://www.topografix.com/GPX/1/0 http://www.topografix.com/GPX/1/0/gpx.xsd">
<time/>';

}

##
