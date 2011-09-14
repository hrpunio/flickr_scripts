#!/usr/bin/perl 
use LWP::Simple; 
# login2flickr.rc contains authentication stuff, namely it
# defines appropriate values to: $api_key, $shared_secret, $auth_token
# and $my_flickr_id:
require 'login2flickr.rc';

$method = 'flickr.people.getInfo'; 

print "$my_flickr_id\n";
$url = "http://www.flickr.com/services/rest/?method=$method&api_key=$api_key&user_id=$my_flickr_id"; 
$xml = get $url; 
print $xml;
