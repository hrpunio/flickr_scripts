#!/usr/bin/perl -s 
use LWP::Simple; 
#Hack 38: converting a username into a Flickr user ID. 
#
$photo_id = shift; 
die ("Please specify some photo id\n") if !$photo_id;

# login2flickr.rc contains authentication stuff, namely it
# defines appropriate values to: $api_key, $shared_secret, $auth_token
# and $my_flickr_id:
require 'login2flickr.rc';


$method = 'flickr.photos.getAllContexts'; 

$url = "http://www.flickr.com/services/rest/?method=$method&api_key=$api_key&photo_id=$photo_id"; 
$xml = get $url; 
print $xml;
