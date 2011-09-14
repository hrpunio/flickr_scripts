#!/usr/bin/perl
#
# http://www.perlmonks.org/?node_id=495333
# Write thumbnail image, if image is geotagged put a red square in upper-left corner
# The scripts is quite slow. One can use photo_thumb.sh instead
use strict;
use warnings;

use Getopt::Long;
use Image::ExifTool;
use Image::Magick;

my ($filename, $filename_out, $rotate);
GetOptions( 'in=s' => \$filename, 'out=s' => \$filename_out, 'rotate=i' => \$rotate) ;

my $x_ = 250; my $y_ = 250;

my $image = Image::Magick->new (); $image->ReadImage ($filename);

if ($rotate) { $image->Rotate(degrees=>$rotate); }

$image->Thumbnail (width => $x_, height => $y_);

my $exifTool = new Image::ExifTool;
my $info = $exifTool->ImageInfo($filename);
my $geo_lat = $exifTool->GetValue('GPSLatitude');
my $geo_lon = $exifTool->GetValue('GPSLongitude');

#$image->Annotate(font => 'Helvetica', pointsize=>30, fill=>'red', text=>"G", x => 10, y => 20);

if ( defined($geo_lat) &&  defined($geo_lon) ) {##Je¿eli jest Geo-tagged zaznacz to
  #print " *** $geo_lat $geo_lon ***\n";
  $image->Draw(fill=>'red', primitive=>'rectangle', points=>'0,0 33,33'); 
}

$image->Write ("$filename_out");

##
