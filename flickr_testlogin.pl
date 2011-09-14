#!/usr/bin/perl -s
use Flickr::API;
use Data::Dumper;

# Authentication:
require 'login2flickr.rc';

my $api = new Flickr::API({'key' => $api_key,
                           'secret' => $shared_secret } );
##
## see: http://www.flickr.com/services/api/flickr.test.login.html
my $response = $api->execute_method('flickr.test.login',
    { 'auth_token' => $auth_token });

print "Success: $response->{success}\n";
print "Error code: $response->{error_code}\n";
print Dumper ($response);
