#!/usr/bin/perl -s
# Test script
use Flickr::API;
use Data::Dumper;
use Text::Iconv;

use bytes;

# Authentication:
require 'login2flickr.rc';

my $tags="abcê¶";
#my $tags="abcd";

print "$tags\n";

$konwerter = Text::Iconv->new("iso-8859-2", "utf-8");
$tags = $konwerter->convert($tags);

print "$tags\n";

my $api = new Flickr::API({'key' => $api_key,
                           'secret' => $shared_secret } );

   ## http://www.flickr.com/services/api/flickr.photos.addTags
   my $response = $api->execute_method('flickr.photos.addTags',
   { auth_token  => $auth_token,
      photo_id   => '260536504',
      tags       => $tags, });

print "Success: $response->{success}\n";
print "Error code: $response->{error_code}\n";
#print Dumper ($response);
