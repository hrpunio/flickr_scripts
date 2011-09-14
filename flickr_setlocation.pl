#!/usr/bin/perl -s
# Test script
use Flickr::API;
use Data::Dumper;

# login2flickr.rc contains authentication stuff
require 'login2flickr.rc';

my $api = new Flickr::API({'key' => $api_key,
                           'secret' => $shared_secret } );
##
## http://www.flickr.com/services/api/flickr.photos.geo.setLocation.html
my $response = $api->execute_method('flickr.photos.geo.setLocation',
    { auth_token => $auth_token,
      photo_id   => '260536504',
      lat        => 54.446167,
      lon        => 18.571056,
      accuracy   => 16,
    });

print "Success: $response->{success}\n";
print "Error code: $response->{error_code}\n";
print Dumper ($response);
