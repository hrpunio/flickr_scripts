#!/usr/bin/perl -s
# Get information on groups to which one can add photos. Stores it (as XML)
# in the flickr config directory

use Flickr::API;
use XML::Simple;
use Data::Dumper;
$Data::Dumper::Terse = 1;  # avoids $VAR1 = * ; in dumper output
$Data::Dumper::Indent = $verbose? 1 : 0;  # more concise output
use Compress::Zlib ;

require 'login2flickr.rc';

my $outfile="$FLICKRCFG/$my_flickr_name.groups";
open (OFILE, ">$outfile");

print STDERR "Fetching info into $outfile [$my_flickr_id]...\n";

my $api = new Flickr::API({'key' => $api_key, 'secret' => $shared_secret } );

## http://www.flickr.com/services/api/flickr.photosets.getList.html
my $response = $api->execute_method('flickr.groups.pools.getGroups',
    { 'user_id'  => $user_id, 'auth_token' => $auth_token , });
die "Problem: $response->{error_message}\n" if !$response->{success};

$xmlp = new XML::Simple ();

## zmienione 15.08.2011 (gzip as content-encoding)
my $content_encoding = $response->{_headers}->{'content-encoding'} ;
my $plain_content;
if ($content_encoding =~ /gzip/ ) {##
    $plain_content = Compress::Zlib::memGunzip( $response->{_content});
} else { $plain_content = $response->{_content};  }

my $xm = $xmlp->XMLin($plain_content, keyattr =>[]);

my $psl = $xm->{groups};

foreach $set ( @{$psl->{group} } ) { $lid++; $set->{'local_id'} = "p$lid"; }
print Dumper(@{$psl->{photoset}});

my $xo  = $xmlp->XMLout($psl, RootName => 'groups');

print OFILE "<?xml version='1.0' encoding='utf-8'?>\n";
print OFILE "<!-- this file was fetched with: perl flickr_getgroups.pl -->\n";
print OFILE "<!-- DO NOT EDIT: Add a tag to flicker.com and re-fetch    -->\n";

print OFILE "$xo"; close OFILE;

print STDERR "OK, fetched...\n";

### ok :: koniec
