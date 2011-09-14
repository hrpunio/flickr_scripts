#!/usr/bin/perl
use Flickr::API;
use Data::Dumper;
use Getopt::Long;
use Text::Iconv;

## Warning: tags are expected to contain ISO-8859-2 characters
## I am not using perlio, Encode or encoding pragmas as
## they are not working (invalid signature are returend at best)
my $USAGE='usage: flickr_settag.pl -p photo -t tags
   use comma to separate multiple tags, ie. -t "tag1,tag2..."
   thus BTW comma cannot be used as a valid tag character' . "\n";

#binmode(STDOUT, ":utf8"); # does not work
use bytes;

GetOptions("help=s" => \$show_help,
	   "photo=s" => \$photo_id,
           "tags=s" =>  \$tags);
if ( $show_help or (! $photo_id ) or (! $tags ) ) { die $USAGE  ;  }

# Authentication:
require 'login2flickr.rc';

# change string tag1,tag2 to string "\"tag1\" \"tag2\""
my @tags=(); @tags = split /,/, $tags;
for $t (@tags) { $t =~ s/^[ \t]+|[ \t]$//; $t="\"$t\""; }
#$tags = "@tags";

# convert to UTF-8
# $tags = Encode::decode("latin2", $tags); ## dobrze
# the above does not work, stick to Text::Iconv
$conv = Text::Iconv->new("iso-8859-2", "UTF-8");
$tags = $conv->convert("@tags");

print "Add: [$tags] to [$photo_id]\n";

my $api = new Flickr::API({'key' => $api_key,
    'secret' => $shared_secret } );

   ## http://www.flickr.com/services/api/flickr.photos.addTags
   my $response = $api->execute_method('flickr.photos.addTags',
   { auth_token  => $auth_token,
      photo_id   => $photo_id,
      tags       => $tags, });

print "Success: $response->{success}\n";
print "Error code: $response->{error_code}\n";
#print Dumper ($response); # debug
