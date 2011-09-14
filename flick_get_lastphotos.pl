#!/usr/bin/perl -s 
#
# The program prints URL of random image out of $max_photos photos from 
# photoalbum of $my_flickr_id user using flickr.people.getPublicPhotos.
# Valid $api_key variable must be provided.
# (c) T.Przechlewski 2007; licence GPL
#
use LWP::Simple; 
#
my $my_flickr_id='20425995@N00';
my $my_flickr_dir='http://www.flickr.com/photos/tprzechlewski';
my $max_photos = '20'; 
my $api_key = '000000000000000000000000'; # insert your API key here
my $method = 'flickr.people.getPublicPhotos'; 

my $url = "http://www.flickr.com/services/rest/?method=$method&api_key=$api_key&user_id=$my_flickr_id&per_page=$max_photos"; 

my $xml = get $url; 

if ($xml =~ m/rsp stat=[ \t]*[\`\"]ok/) {# no errors so print
   while ($xml =~ m/id=[ \t]*[\`\"]([^\"\']+)[\`\"]/g) { push @Photos, $1; } 
} else { die "** Problems fetching $max_photos of $my_flickr_id **"; }

my $r = print_random(); print "$my_flickr_dir/$r\n";

1; ## ok, finish now

### all photos: ###
sub print_all_photos { for (@Photos) { print "$my_flickr_dir/$_\n"; } }

### random photo: ###
sub print_random { return $Photos[ int(rand($max_photos)) ]; }

## end ###
