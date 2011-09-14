#!/usr/bin/perl
# Get tags from flickr for current user
# 20110815: change -- print using UTF-8
#
# to user-name.tags file in  $FLICKRCFG/
# Usage: flickr_getalltags [-u userid] 
#   -u userid = specifies photo owner (default: use $my_flickr_id)
# Example: perl flickr_getalltags.pl gets tags for $my_flickr_id
#
use Flickr::API;
use XML::Simple;
use Data::Dumper;
use Text::Iconv;
use Getopt::Long;
use Compress::Zlib ;

use bytes;

GetOptions("help=s" => \$show_help,
           "user=s" =>  \$user_id);
# jezeli jest user_ID nadpisz domyslny
# ustal ID uzytkownika i tryb pracy (niedokonczone)
if ($user_id) { $my_flickr_id = $user_id; $current_mode='m'; }

$xmlp = new XML::Simple ( );
 
my ($sec,$min,$hour,$mday,$mon,$year,
    $wday,$yday,$isdst) = localtime time;

# login2flickr.rc contains authentication stuff, namely it
# defines appropriate values to: $api_key, $shared_secret, $auth_token
# and $my_flickr_id:
require 'login2flickr.rc';

print STDERR "** Getting all raw tags for: $my_flickr_id\n";
print STDERR "** Omitting `geo:' tags\n";

my $flickr = new Flickr::API({'key' => $api_key, 'secret' => $shared_secret } );

print STDERR "** Fetching data (may take some time)...\n";

my $response = $flickr->execute_method('flickr.tags.getListUserRaw',
    { 'auth_token' => $auth_token , user_id  => $my_flickr_id, } 
);

print STDERR "Done...\n";

die "Problem: $response->{error_message}\n" if !$response->{success};


## zmienione 15.08.2011 (gzip as content-encoding)
my $content_encoding = $response->{_headers}->{'content-encoding'} ;
my $plain_content;
if ($content_encoding =~ /gzip/ ) {##
    $plain_content = Compress::Zlib::memGunzip( $response->{_content});
} else { $plain_content = $response->{_content};  }

my $xm = $xmlp->XMLin($plain_content, forcearray=>[raw]);

my $tagList = $xm->{who}->{tags}->{tag};

## zmiana 15.08.2010 ## baza jest kodowana w UTF
## $konwerter = Text::Iconv->new("utf-8", "iso-8859-2");
$now = sprintf "%d-%d-%d/%d-%d-%d", $sec, $min, $hour, $mday, $mon +1, $year + 1900;

my $outfile="$FLICKRCFG/$my_flickr_name.tags";
open (OFILE, ">$outfile");

foreach $t (@{$tagList}) { 
  $clean_tag = $t->{clean} ; 

  ## zmiana 15.08.2010 ## baza jest kodowana w UTF
  ## $clean_tag = lc( $konwerter->convert($clean_tag) );
  $clean_tag = lc( $clean_tag );

  foreach $raw_tag ( @{ %{$t}->{raw} } ) {
      if ($raw_tag !~ /^geo:/) { 
         ## zmiana 15.08.2010 ## baza jest kodowana w UTF
         ## $raw_tag = lc ( $konwerter->convert($raw_tag) );
         $raw_tag = lc ( $raw_tag );
         $raw_tgs{ $raw_tag } = $clean_tag ; 
         $tgs_tgs++;
      } 
  }
}

## zmiana 15.08.2010 ## baza jest kodowana w UTF
## print OFILE "<?xml version='1.0' encoding='iso-8859-2'?>\n";
print OFILE "<?xml version='1.0' encoding='utf-8'?>\n";
print OFILE "<!-- this file was fetched with: perl flickr_getalltags.pl -->\n";
print OFILE "<!-- DO NOT EDIT: Add a tag to flicker.com and re-fetch    -->\n";
print OFILE "<!-- Tags by  $my_flickr_id($my_flickr_name) at $now -->\n"; 
print OFILE "<!-- $tgs_tgs accepted (geo: prefixed omitted       -->\n";
print OFILE "<tags>\n";
print OFILE "<!-- raw_tag <!-.- clean_tag -.->                          -->\n"; 

foreach  $i (sort keys %raw_tgs ) {
  print OFILE ("<tag>", $i, "</tag><!--", $raw_tgs{$i}, "-->\n" ); 
}

print OFILE "</tags>\n";
close OFILE;

## Tagi do zdjec innych sa traktowane specjalnie (jest taki jeden)
##print "=============\n";
##print Dumper($xm);
##
