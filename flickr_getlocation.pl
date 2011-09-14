#!/usr/bin/perl -s
use Flickr::API;
use Data::Dumper;
use XML::Simple;

$photo_id = shift || die "photo_id missing!";

# login2flickr.rc contains authentication stuff, namely it
# defines appropriate values to: $api_key, $shared_secret, $auth_token
# and $my_flickr_id:
require 'login2flickr.rc';

my $api = new Flickr::API({'key' => $api_key,
                           'secret' => $shared_secret } );
##
## http://www.flickr.com/services/api/flickr.photos.geo.setLocation.html
my $response = $api->execute_method('flickr.photos.geo.getLocation',
    { #'auth_token' => $auth_token,
      photo_id  => $photo_id,
    });

print "Success: $response->{success}\n";
print "Error code: $response->{error_code}\n";

$xmlp = new XML::Simple ( );

my $xm = $xmlp->XMLin($response->{_content});

$latitude = $xm->{photo}->{location}->{latitude};
$longitude = $xm->{photo}->{location}->{longitude};
$accuracy = $xm->{photo}->{location}->{accuracy};

print "Photo id = $photo_id => lat/lon/acc: $latitude x $longitude x $accuracy\n";
#
#print Dumper ($response);
