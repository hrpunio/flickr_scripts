#!/usr/bin/perl -s
# Get information on sets defined by the user. Stores it (as XML)
# in the flickr config directory

use Flickr::API;
use Data::Dumper;
$Data::Dumper::Terse = 1;  # avoids $VAR1 = * ; in dumper output 
$Data::Dumper::Indent = $verbose? 1 : 0;  # more concise output
use Compress::Zlib ;

use XML::Simple;

# login2flickr.rc contains authentication stuff
require 'login2flickr.rc';

$user_id = shift || $my_flickr_id;
$user_name = shift || $my_flickr_name;

my $outfile="$FLICKRCFG/$my_flickr_name.sets";
open (OFILE, ">$outfile");

print STDERR "Fetching info into $outfile [$my_flickr_id]...\n";

my $api = new Flickr::API({'key' => $api_key,
      'secret' => $shared_secret } );
##
## http://www.flickr.com/services/api/flickr.photosets.getList.html
my $response = $api->execute_method('flickr.photosets.getList', { user_id  => $user_id });
die "Problem: $response->{error_message}\n" if !$response->{success};

$xmlp = new XML::Simple ();

## zmienione 15.08.2011 (gzip as content-encoding)
my $content_encoding = $response->{_headers}->{'content-encoding'} ;
my $plain_content;
if ($content_encoding =~ /gzip/ ) {##
    $plain_content = Compress::Zlib::memGunzip( $response->{_content});
} else { $plain_content = $response->{_content};  }

my $xm = $xmlp->XMLin($plain_content, keyattr =>[]);
my $psl = $xm->{photosets};

foreach $set ( @{$psl->{photoset} } ) { $lid++; $set->{'local_id'} = "s$lid"; }
#print Dumper(@{$psl->{photoset}});

my $xo  = $xmlp->XMLout($psl, RootName => 'photosets');
print OFILE "$xo";

#print OFILE "\@photosets=(\n";
#my $setno;
#
#foreach $set ( @{$psl} ) {  print OFILE ($setno++? ",\n" : "") . Dumper($set); }
#
#print OFILE ")\n";
close OFILE;

print STDERR "OK, fetched...\n";

#print Dumper($psl);

# 'photos' => '',
# 'primary' => '',
# 'title' => '',
# 'secret' => '',
# 'id' => '',
# 'server' => '',
# 'description'
