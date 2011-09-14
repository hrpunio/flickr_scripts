#!/usr/bin/perl 
#
# http://code.flickr.com/blog/2008/08/19/standard-photos-response-apis-for-civilized-age/
# Wyszukuje zdjêcia wg. tagów; generuje plik GPX dla zdjêæ zawieraj±cych wsp. geo
use strict;

use XML::LibXML;
use LWP::Simple;

require 'login2flickr.rc';

our $api_key;
my $method = 'flickr.photos.getRecent';
my $Photos;

my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime time;
$year += 1900 ; $mon += 1;
my $today = sprintf "%4.4d%2.2d%2.2d%2.2d%2.2d", $year, $mon, $mday, $hour, $min;

my $max_per_page = 500;
my $max_pages = 5;
my ($current_page, $total_pages, $current_page);
my $pageno;

my $parser = XML::LibXML->new;
my $photos;

do { 
    $pageno++; ## nastêpna strona

   my $resp = get ( "http://www.flickr.com/services/rest/?" .
     "method=$method&api_key=$api_key&per_page=$max_per_page&page=$pageno&extras=geo,views,tags,machine_tags,license" );
   ## sprawd¼ czy jest OK:
   eval { $photos = $parser->parse_string($resp) } ;

   unless ($@) {## errors parsing ## pomiñ stronê z b³êdami
       unless ( $photos->getElementsByTagName('rsp' )->[0]->getAttribute( 'stat' ) eq 'ok') { 
          warn "Problems with retriving photo list!\n" ; next }

       $total_pages = $photos->getElementsByTagName('photos' )->[0]->getAttribute('pages' );
       $current_page = $photos->getElementsByTagName('photos' )->[0]->getAttribute('page' );

       $Photos .= $resp; 
   }

   print STDERR ".... $pageno\n";

} while ( ($current_page < $total_pages) && ($pageno < $max_pages) );

## zrobione
#
my $file_out = "f_$today.xml";
open OUT, ">$file_out";

print OUT "<recent_photos>\n$Photos\n</recent_photos>\n";

##

