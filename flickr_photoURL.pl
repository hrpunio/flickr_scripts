#!/usr/bin/perl

## (c) T.Przechlewski, tprzechlewski@acm.org, 2006.
## One can distribute/modify it under the terms of the GNU General Public License.
##
## Usage: perl flickr_photoURL.pl -s size -bw photoid1 photoid2...
##
## Get the photo which id is `photo_id' at size `size', if size not given default is thumbnail
## then generate BW version of the picture, with:
##  convert $photo -colorspace GRAY $bw_photo_name
## and HTML fragment (to STDIO) containing appropriate links to pictures.
## 
## I want my pictures to be stored at flickr.com but have some thumbnails in color
## and bw variants to be stored locally. This script facilitates it.

use Flickr::API;
use Data::Dumper;
use XML::Simple;
use Getopt::Long;
use LWP::Simple;

my $default_size = 'thumbnail';
my $local_thumbs_dir = 'http://gnu.univ.gda.pl/~tomasz/images/thumbs';

my ($p, $current_size, $selected_url, $photo_name);

GetOptions("size=s"  => \$size,
	   "bw"      => \$generate_bw,  # create grayscale version of the image
);

if (! $size ) { $size = $default_size; }

# login2flickr.rc contains authentication stuff, namely it
# defines appropriate values to: $api_key, $shared_secret, $auth_token
# and $my_flickr_id:
require 'login2flickr.rc';

my $api = new Flickr::API({'key' => $api_key, 'secret' => $shared_secret } );
my $xmlp = new XML::Simple ( );


print "# Possible sizes are: [Square][Thumbnail][Small][Medium][Large][Original]\n";

## http://www.flickr.com/services/api/flickr.photos.getSizes
## all arguments are treated as photos ids:
for $photo_id (@ARGV) { 
  ##print STDERR  "$photo_id\n";
  my $response = $api->execute_method('flickr.photos.getSizes', { photo_id  => $photo_id, });

  #print STDERR "Success: $response->{success}\n";
  #print STDERR "Error code: $response->{error_code}\n";

  my $xm = $xmlp->XMLin($response->{_content} );
  my $phList = $xm->{sizes}->{size};

  print "# Looking for available sizes of $photo_id...\n# ";

  foreach $p (@{$phList}) {
    $current_size = ${$p}{label};
    ##printf ">%10.10s = %s\n", $current_size, ${$p}{source};
    printf "[%s]", $current_size;
    if (lc($current_size) eq lc($size) ) { $selected_url = ${$p}{source}; 
    }
  }

  print "\n";

  if ( $selected_url ) { $photo_name = $selected_url; $photo_name =~ s/.+\///;
      print "$selected_url $photo_id\n"; }

  if ( $generate_bw ) { 
     if ($selected_url) { generate_bw_picture($selected_url, $photo_name); }
     else { print STDERR "Not found!\n"; }
  }

}

# /////////////////////////////////////////////////////////////////////////

sub generate_bw_picture {
  my $su = shift;
  my $photo_name = shift;

  print STDERR ">>$photo_name\n";
  print "<a href=\"http://www.flickr.com/photos/tprzechlewski/$photo_id/\" "
      . "title=\"Photo Sharing\"><img src=\"$local_thumbs_dir/$photo_name\" "
	. "longdesc=\"##$photo_name\" width=\"100\" height=\"75\" alt=\"[]\" /></a>";

  my $photo_content = get($su);
  if ( $photo_content ) { print STDERR "OK!\n" } else {print STDERR "KO!\n"};

  ### save the picture:
  open PHOTO, ">$photo_name";
  print PHOTO $photo_content;
  close PHOTO;

  ### generate GW photo:
  my $bw_photo_name = $photo_name; 
  $bw_photo_name =~ s/\.jpg/\-\+bw.jpg/;
  my @sys_args = ("convert", "$photo_name", "-colorspace", "GRAY",  "$bw_photo_name");
  system(@sys_args) == 0 or die "system @sys_args failed: $?";

  ##system (convert plik_we -colorspace GRAY plik_wy )
  print STDERR "\n";
  ##print Dumper ($phList);

} ## //generate_bw_picture

## end ##

