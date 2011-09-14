#!/usr/bin/perl -s 
use LWP::Simple; 
#Hack 38: converting a username into a Flickr user ID. 
#
$username = shift; 
die ("Please specify a Flickr username\n") if !$username; 

# login2flickr.rc contains authentication stuff, namely it
# defines appropriate values to: $api_key, $shared_secret, $auth_token
# and $my_flickr_id:
require 'login2flickr.rc';


$method = 'flickr.people.findByUsername'; 

$url = "http://www.flickr.com/services/rest/?method=$method&api_key=$api_key&username=$username"; 
$xml = get $url; 
print $xml;
