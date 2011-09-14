#!/usr/bin/perl
# Compute time offset between digital camera time and GPS time (in seconds)
# Usage exif_datetime.pl -f picture [ -t gps_display_time ] [ -o gps_offset ]
# Where: gps_display_time - gps_offset = gps_internal_time
# And:   time_offset = gps_internal_time - $camera_time
#
# Use following format for time-related parameters:
# gps_display_time = hh:mm:ss ; gps_offset =  seconds
#
# My GPS for example uses GMT internally and diplays local time.
#
use strict;
use Getopt::Long;
use Image::ExifTool;
use Time::Local;
my ($file, $b_time, $offset, $modeA);
my $history_file = "$ENV{HOME}/.time_offset"; ## write last recored offset to disk, if '' supress
my $gps_offset ;

GetOptions( 'base=s' => \$b_time, 'file=s' => \$file, 'offset=i' => \$offset, 'auto' => \$modeA) ;
if ($offset) { $gps_offset = $offset ; }
## (localtime)[2] - (gmtime)[2] ) zwraca offset w godzinach:
else { $gps_offset = ( (localtime)[2] - (gmtime)[2] ) * 3600 ; }

print STDERR " === $0 -b gps_display_time -f picture -o GMT_offset_in_seconds\n"
  . " === where gps_display_time - GMT_offset_in_seconds = gps_GMT_time\n"
  . " === GMT_offset_in_seconds is: $gps_offset\n"
  . " ===\n"
  . " === if arguments given displays $history_file \n";

## wy¶wietl zawarto¶æ pliku $history_file i zakoñcz
if ((! $file ) && -f "$history_file" ) { 

  my %time_Offsets ; my %time_Offsets_Rec ;

  print STDERR " *** No arguments\n";
  my ($camera, $last_time_offset, $xdate, $last_time); 
  print STDERR " *** Reading  $history_file\n";
  if (open (LOG, "$history_file")) {
     while (<LOG>) { chomp();
       ($camera, $last_time, $xdate) = split (/ : /, $_ );
       $time_Offsets{$camera} = $last_time;
       $time_Offsets_Rec{$camera} = $xdate;
    }
     for (keys %time_Offsets ) {
        print STDERR " *** Found offset for $_ at $time_Offsets_Rec{$_} : $time_Offsets{$_}\n"; }
  } else { print STDERR " *** Problems reading $history_file\n"; }


  if( my $some_file = get_some_jpeg_file()) {
     print STDERR " === Offset for $some_file === \n";
      my ($datetime, $cameraModel) = get_exif_from_file($some_file);  
      print " *** THIS_CAMERA_OFFSET $time_Offsets{$cameraModel} ***\n";
  }

  exit 0;

} elsif ( ! $file ) {
  die "*** ERROR history file $history_file not found\n";
} elsif ( ! -f $file ) {
  die "*** ERROR file $file don't exist\n"

}

##

my ($datetime, $cameraModel) = get_exif_from_file($file);

print STDERR " *** CameraModel: $cameraModel\n";

if ( ! defined($datetime)) { die " *** STRANGE : No EXIF dateTime?\n"; }

my  $cmtp_offset ;
my ($date, $time) = split (" ", $datetime );
my ($rr, $mm, $dd, $gg, $mn, $ss) = split ":", "$date:$time" ;
$date =~ s/:/-/g;

if ($b_time) { my ($gg_, $mn_, $ss_) =  split ":", $b_time; $rr -= 1900 ; $mm-- ;
  my $camera_time = timelocal($ss, $mn, $gg, $dd, $mm, $rr);
  my $gps_time =  timelocal($ss_, $mn_, $gg_, $dd, $mm, $rr);
  print STDERR " === File Date Time ( GPS - Camera ) \n";
  ## --timeoffset seconds Camera time + seconds = GMT. No default.
  $cmtp_offset =  ($gps_time  - $gps_offset) - $camera_time;
  print " === $file $date $time ( $cmtp_offset ) \n"; }
else { print "$file $date $time\n"; }

if ($history_file ) {
  open (TIMELOG, ">>$history_file") || warn "*** Problems writing $history_file\n";
  print TIMELOG "$cameraModel : $cmtp_offset : $date\n";
  print STDERR " *** Updating $history_file *** $cameraModel : $cmtp_offset : $date\n";
  close (TIMELOG,);
} else {  print STDERR " *** File $history_file not updated!\n"; }

## --- subs ---

sub get_some_jpeg_file { # return some .jpeg file
   while (<*>) { if (/\.jpg|\.jpeg/) { return $_ } } }

sub get_exif_from_file { # get and return some exif data
   my $pic = shift;

   my $exifTool = new Image::ExifTool;
   my $info = $exifTool->ImageInfo($pic); 

   my $dt = $exifTool->GetValue('DateTimeOriginal');
   # http://www.sno.phy.queensu.ca/~phil/exiftool/TagNames/EXIF.html
   my $camera = $exifTool->GetValue('Model'); $camera =~ s/[ \t:]//g;
   return ( $dt, $camera );
}

## --- end ---
