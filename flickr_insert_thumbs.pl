#!/usr/bin/perl -s 
#  
# Pobie¿ thumbnail dla zdjêæ o podanych tytu³ach (title) 
# w wierszu wywo³ania. Wypisz na wyj¶cie odpowiednie polecenia wget
# usage <file> title title ....

my $size ='t';
my @wget = ();

#$photolist = shift;
#
#die "flickr_insert_thumbs.pl <photolist_file> \n" if !$photolist;
#$photolist .= '.ph' if !($photolist =~ /\./);
require 'login2flickr.rc';
$photolist = "$FLICKRCFG/$my_flickr_name.ph";

require "$photolist";

print "<!-- $photolist :: @ARGV -->\n";

foreach $photo (@photos) {

  $title = $photo->{title};

  foreach $p (@ARGV) {
    #print "$title <> $p\n ";

    if ( $title eq $p ) {
      $server = $photo->{server} || "!!!";
      $secret = $photo->{secret} || "!!!";
      #$title = $photo->{title} || "!!!" ;
      $id = $photo->{id} || "!!!";

      $thumb = "${id}_${secret}_${size}.jpg";

      print "<a href=\"http://www.flickr.com/photos/tprzechlewski/${id}/\" title=\"Photo Sharing\">\n";
      print "<img longdesc=\"##$thumb\"\n";
      print "  src=\"http://gnu.univ.gda.pl/~tomasz/images/thumbs/$thumb\"\n";
      print "  width=\"100\" height=\"75\" alt=\"$title\" /></a>\n";

      push @wget, "wget http://static.flickr.com/$server/$thumb\n";
    }
  }
}


print "<!-- ;;; -->\n";

foreach $p (@wget) {  print $p; }
