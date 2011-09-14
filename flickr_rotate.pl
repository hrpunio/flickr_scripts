#!/usr/bin/perl 
# Test script
use Flickr::API;
use Getopt::Long;
use Data::Dumper;

# login2flickr.rc contains authentication stuff
require 'login2flickr.rc';

GetOptions("help=s" => \$show_help,
           "id=s"   => \$photo_id,
           "r"      => \$right,
           "l"      => \$left,
);

if ($right) { $rotation = 270 } 
elsif ($left) {$ rotation = 90 }
else { die "ERROR ** Specify -l or -r " }

warn "Rotate $photo_id with $rotation\n";

my $api = new Flickr::API({'key' => $api_key,
             'secret' => $shared_secret } );

## http://www.flickr.com/services/api/flickr.photos.geo.setLocation.html
## http://developer.yahoo.com/java/howto-flickrAuth.html
my $response = $api->execute_method('flickr.photos.transform.rotate',
    { auth_token => $auth_token,
      photo_id => $photo_id,
      degrees => $rotation,
    });

print "Success: $response->{success}\n";
print "Error code: $response->{error_code}\n";
print Dumper ($response);
