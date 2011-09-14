#!/usr/bin/perl -s 
#
# The program takes a username, converts it into a user_id, and then uses 
# that user_id to look up the most recent photo in the user's stream, 
# using flickr.people.getPublicPhotos.
# It then gets a little more info about the photo using flickr.photos.getInfo 
# and generates an HTML page that contains a view of the photo 
# and the information that was retrieved. 

use LWP::Simple; 
use XML::Simple; 
use Data::Dumper; 

$Data::Dumper::Terse = 1;  # avoids $VAR1 = * ; in dumper output 
$api_key = ''; # insert your Flickr API key here 
$debug =1;

$username = shift; 

require 'login2flickr.rc';

die ("Please specify a Flickr username\n") if !$username; 
# 
# Get user's ID 
# 
$method = 'flickr.people.findByUsername'; 
$url = "http://www.flickr.com/services/rest/?method=$method" . 
        "&api_key=${api_key}&username=${username}"; 
$xml = get $url; 
$xm = XMLin($xml); 
print Dumper($xm),"\n" if $debug; 
if ($xm->{err}) 
{ 
    print "Error getting user id: ",$xm->{err}->{msg},"\n"; 
    exit; 
} 
$user_id = $xm->{user}->{id}; 
# 
# Get user's most recent photos 
# 
$method = 'flickr.people.getPublicPhotos'; 
$url = "http://www.flickr.com/services/rest/?method=$method" .  
            "&api_key=$api_key&user_id=$user_id&per_page=1"; 
$xml = get $url; 
$xm = XMLin($xml); 
print Dumper($xm),"\n" if $debug; 
if ($xm->{err}) 
{ 
    print "Error getting most recent photo: ",$xm->{err}->{msg},"\n"; 
    exit; 
} 
$photo_id = $xm->{photos}->{photo}->{id}; 
$photo_secret = $xm->{photos}->{photo}->{secret}; 
$photo_server = $xm->{photos}->{photo}->{server}; 
# 
# Formulate URL to the photo (image) 
# 
$imgUrl = sprintf "http://static.flickr.com/%d/%d_%s.jpg",  
                $photo_server,$photo_id, $photo_secret; 
# 
# Formulate URL to the photo's Flickr page 
# 
$pageUrl = sprintf "http://www.flickr.com/photos/%s/%d/",  
                $user_id, $photo_id; 
# 
# Get photo info 
# 
$method = 'flickr.photos.getInfo'; 
$url = "http://www.flickr.com/services/rest/?method=$method" .  
                "&api_key=$api_key&photo_id=$photo_id"; 
$xml = get $url; 
$xm = XMLin($xml); 
print Dumper($xm),"\n" if $debug; 
if ($xm->{err}) 
{ 
    print "Error getting most recent photo: ",$xm->{err}->{msg},"\n"; 
    exit; 
} 
# 
# Get title 
# 
$title = $xm->{photo}->{title}; 
