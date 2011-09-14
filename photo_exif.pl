#!/usr/bin/perl
# Usage: photo_exif file Tag1 Tag2 ...
# Print OK if all tags are defined in the file (otherwise prints KO)  
# GPSLatitude
use strict;
use warnings;
use Image::ExifTool;
my $filename = shift ;

my $exifTool = new Image::ExifTool;
my $info = $exifTool->ImageInfo($filename);
for my $p (@ARGV) { my $x = $exifTool->GetValue($p); ## print "$p $x\n";
  if ( ! defined($x) ) { print "KO"; exit 1 } }

print "OK"; exit 0;
