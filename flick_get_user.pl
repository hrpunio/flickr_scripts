#!/usr/bin/perl -s 
use LWP::Simple; 
$username = shift; 
die ("Please specify a Flickr username\n") if !$username; 

$api_key = '000000000000000000000000000000000'; # insert your API key here 

$method = 'flickr.people.findByUsername'; 

$url = "http://www.flickr.com/services/rest/?method=$method&api_key=$api_key&username=$username"; 
$xml = get $url; 
print $xml;
