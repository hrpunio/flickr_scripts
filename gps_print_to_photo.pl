#! /usr/bin/perl -w
# Pobiera wspó³rzêdne GEO z odpowiednich pól EXIF i umieszcza jako
# tekst na obrazku.  Dodaje notê copyrajtow±
#
use Image::Magick;
use Image::ExifTool;
use Getopt::Long;

my ($fontcolor, $fontsize, $pointsize);
my $text2 = "for more info see EXIF tags";
my $usercomment = "Original photo: http://www.flickr.com/photos/tprzechlewski/";
GetOptions(
    'help'        => \$print_help,
    'fontcolor=s' => \$fontcolor,
    'fontsize=i'  => \$fontsize,
    'nolicense'   => \$nolicense,
);

unless ($fontcolor) { $fontcolor = 'white'; }
if ($print_help || ($#ARGV < 0 )) { 
 print STDERR "$0 [-fontcolor=color | -fontsize=size | -nolicense ] pliki ...\n"
 }

## reszta to s± nazwy plików po oznakowania
foreach $argnum (0 .. $#ARGV) {
  my $in = "$ARGV[$argnum]";
  unless ( -f $in ) {   print STDERR "Nie ma pliku: $in\n";  }
  else { $tmp = process_photo($in); 
         if ($tmp < 0 ) { print STDERR "Problems with: $in image\n"; }
   }
}


## ================
sub process_photo {
  my $img_name =  shift;
  my $out_img_name = $img_name;

  $out_img_name =~ s/\.([^\.]+)$//g; ## usuñ rozszerzenie
  my $ext_img_name = $1;

  my $image = new Image::Magick;
  $image->Read("$img_name");

  my $width = $image->Get("width") || return -1;
  my $height = $image->Get("height");

  unless ($fontsize) { $pointsize = int ($height * 0.03); }
  else {$pointsize = $fontsize }

  print STDERR "Szeroko¶æ/wysoko¶æ: $width/$height px; Stopieñ/kolor pisma: $pointsize/$fontcolor.\n";

  my $exifTool = new Image::ExifTool;

  $exifTool->ExtractInfo($img_name);

  ## http://www.sno.phy.queensu.ca/~phil/exiftool/ExifTool.html#GetValue
  my $GPSLongitude;
  $GPSLatitude  = $exifTool->GetValue('GPSLatitude', 'ValueConv');

  if ($GPSLatitude) {##
    my $GPSLongitude = $exifTool->GetValue('GPSLongitude', 'ValueConv');

    $text = sprintf "lat/lon %8.6f/%8.6f", $GPSLatitude, $GPSLongitude;

    print STDERR "Lat/lon = $GPSLatitude : $GPSLongitude\n";
    ##$txt->Draw(stroke=>'green',primitive=>'rectangle',points=> '20,20 50,50');

    $image->Annotate(font=>'Helvetica', pointsize=>"$pointsize", fill=>$fontcolor, text=>$text,
    gravity=>'SouthWest' , x=>10, y=>4 );

    unless ($nolicense) {##
      $image->Annotate(font=>'Helvetica', pointsize=>"$pointsize", fill=>$fontcolor, text=>$text2,
		       gravity=>'SouthEast' , x=>10, y=>4 );
    }

    $image = $image->Write("${out_img_name}_a.$ext_img_name");

    #my $old_comment = $exifTool->GetValue('UserComment', 'ValueConv');
    #unless ($old_comment =~ /$usercomment/ ) {##
    #  $exifTool->SetNewValue(UserComment => "$old_comment [$usercomment]");
    #  $exifTool->WriteInfo("${out_img_name}_a.$ext_img_name");
    #  print STDERR "Dodano nowy komentarz: $usercomment\n";
    #}

  } else { print STDERR "No GPS coordinates found!\n"; }

} ## /end_of_sub

##
