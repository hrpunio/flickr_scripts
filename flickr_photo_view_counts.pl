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
my $pageno = 0;
my $method = 'flickr.photos.search';
my $max_per_page = 500;
my $total_pages = 0;
my $current_page = 0;

my $photos ;
my $photo_log = '';

my $search_query =  "&extras=geo,views"; # http://www.flickr.com/services/api/flickr.photos.search.html
if ( $user_id ) { $search_query .=  "&user_id=$user_id";  }
if ( $tags_txt ) { $search_query .=  "&tags=$tags_txt" }

printf STDERR " *** Looking for %s's photos with tags: %s\n", $user_id, $tags_txt;

do {

   $pageno++;

   print "$pageno\n";

   #  user_id=$user_id 
   #  The NSID of the user who's photo to search. If this parameter isn't passed then everybody's public photos will be searched
   my $resp = get ( "http://www.flickr.com/services/rest/?" .
	"method=$method&api_key=$api_key&per_page=$max_per_page&page=$pageno" . $search_query );

   print "$api_key : $resp\n";
   print ( "http://www.flickr.com/services/rest/?" .
        "method=$method&api_key=$api_key&per_page=$max_per_page&page=$pageno" . $search_query );

   for (my $i=0; $i<3; $i++) {
     eval { $photos = $parser->parse_string($resp) } ;

     unless ($@) {
       if ( $photos->getElementsByTagName('rsp' )->[0]->getAttribute( 'stat' ) eq 'ok') {
	 $total_pages = $photos->getElementsByTagName('photos' )->[0]->getAttribute('pages' );
	 $current_page = $photos->getElementsByTagName('photos' )->[0]->getAttribute('page' );
	 my $photo_list = $photos->getElementsByTagName('photos' )->[0];
	 $photo_log .= sprintf "%s", $photo_list->toString(); ## lista zdjêæ

	 printf STDERR " *** Page %d  of %d retreived...\n", $current_page, $total_pages;
	 last; ## zakoñcz pêtle uda³o siê
       }
      } else {
       ## 3 minuty przerwy je¿eli nie uda³a siê próba ##
       sleep(180);
     }
   }
} while ( $current_page < $total_pages  );

my $dzis = today();
my $outfile=">${my_flickr_id}_${dzis}.xml";

if (open (OUT, $outfile)) { print OUT "<photolist time.checked='$dzis'>\n$photo_log</photolist>\n" ;
close OUT; } else {  warn "*** Cannot write to $outfile\n****"; }

## ### ### ###

sub today {## zwraca czas biezacy
  my ($ss, $mm, $hh, $dd, $mc, $yy) = (localtime)[0,1,2,3,4,5] ; ## teraz
  return ( sprintf ("%4.4d%2.2d%2.2d%2.2d%2.2d", $yy +1900, $mc+1, $dd, $hh, $mm));
}
## OK
