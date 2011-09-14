#!/usr/bin/perl -s
use Flickr::API;
use Data::Dumper;

# Authentication:
require 'login2flickr.rc';

my $api = new Flickr::API({'key' => $api_key});

my $response = $api->execute_method('flickr.test.echo', {
	    'foo' => 'bar',
	    'baz' => 'quux',
    });

print "Success: $response->{success}\n";
print "Error code: $response->{error_code}\n";
print Dumper ($response);
