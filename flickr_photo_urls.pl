#!/usr/bin/perl -w
# hr.icio.ph contains database of my public photos produced with flickr_getphotolist.pl script
# Wypisuje ró¿ne urle na podstawie tytu³u lub id zdjêcia 
#
use Getopt::Long;
my ($picturetitle, $pageurl, $pictureurl, $pictureid, $id_and_urls);
our @photos ; # photos is required from hr.icio.ph (see below)
my $picturesize='t'; ## thumbnail

GetOptions( 't'  =>  \$picturetitle,
            'u'  =>  \$pageurl,
            'p'  =>  \$pictureurl,
	    'i'  =>  \$pictureid,
            's=s' => \$picturesize,
	    'a'  =>  \$id_and_urls, ) ;

require "$ENV{HOME}/.flickr/hr.icio.ph" ;

$photo_title = shift || die "*** Usage: flickr_get_URLs [options] photo_title/photo_id";

my $found = 0;

for (@photos) {

  if ($photo_title eq $_->{title} || $photo_title eq $_->{id} ) {

      if ($picturetitle || $id_and_urls ) { print "$photo_title "; }
      if ($pageurl || $id_and_urls ) { print "http://www.flickr.com/tprzechlewski/$_->{id}/ "; }
      if ($pictureurl || $id_and_urls ) { print "http://static.flickr.com/$_->{server}/$_->{id}_$_->{secret}_$picturesize.jpg "; }
      if ($pictureid || $id_and_urls ) { print "$_->{id} "; }
      print "\n";
      $found=1;
  }
}

unless ($found ) { print STDERR "*** $photo_title not found !\n";  exit 1 ; }
