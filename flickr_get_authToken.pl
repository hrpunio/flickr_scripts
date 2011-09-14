#!/usr/bin/perl # get_auth_token.pl 
# This script requests an authentication token for a user  
# given a specific API key and shared secret. 
# 
# You can get a Flickr API key and shared secret and read the  
# full documentation for the Flickr API at: 
# 
# http://www.flickr.com/services/api/ 
use strict; 
use Flickr::API; 
use XML::Simple; 
use Digest::MD5 qw/md5_hex/; 

# Set your Flicker variables 
# Authentication:
require 'login2flickr.rc';
my $permission_wanted = 'write'; 

# Start the API 
my $api = new Flickr::API({'key' => $api_key, 
               'secret' => $shared_secret}); 
my $response = $api->execute_method('flickr.auth.getFrob'); 

# Grob the frob 
my $xmlsimple = XML::Simple->new( ); 
my $flickr_xml = $xmlsimple->XMLin($response->{_content}); 
my $frob = $flickr_xml->{frob}; 

# Get authorization for read access 
my $url = $api->request_auth_url($permission_wanted, $frob); 

## Open browser with auth URL (Windows only!) 
# $url =~ s/&/^&/gis; #Escape URL for command line 
# system "start $url";  

# Non-Windows systems should print out the URL 
print "Go to the following URL in a web browser:\n\n$url\n\n"; 
# Tell the user to check out the Flickr window 
print "Return to this window after you've finished the authorization process on Flickr.com and press Enter."; 
<STDIN>; 
# Get the auth token 
my $response = $api->execute_method('flickr.auth.getToken', { 
                'frob' => $frob}); 

my $flickr_xml = $xmlsimple->XMLin($response->{_content}); 

my $auth_token = $flickr_xml->{auth}->{token}; 
die "Couldn't get authentication token!" unless defined $auth_token; 
print "\nYour auth token is: $auth_token";

## auth token is:
## 1281600-b0e2ea1b39069518 (write)
