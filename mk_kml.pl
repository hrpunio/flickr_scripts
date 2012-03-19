#!/usr/bin/perl
#
# Skrypt tworzący plik KML z LOGa programu 	flickr_xload.pl (ładującego zdjęcia na flickr.com)
# oraz pliku ze śladem GPX. 
# Plik wynikowy jest gotowy do załadowania na google MyMaps.
#
use LWP::Simple;
use XML::DOM;
use Getopt::Long;

my $TargetLabel ='Small';

my $USAGE = "mk_kml -log log-file -gpx gpx-file, gdzie: log-file to LOG programu 	flickr_xload.pl a gpx-file to  plik ze śladem GPX\n";

### ### ### ###
my $gpxfile = ''; my $logfile = '';

GetOptions( "gpx=s"  => \$gpxfile,
	    "log=s"  => \$logfile,
            "help|?" => \$showhelp,
);

if ( $showhelp ) { die $USAGE  ;  }
if ( ! $logfile ) {  $logfile = "upload.log" ; }; ##
print STDERR "*** Zadeklarowano $logfile jako plik LOG ***\n";

print STDERR "*** Zadeklarowano $gpxfile jako plik GPX ***\n";
if ( ! $gpxfile )  { die "*** Nie podano pliku GPX ***"; }

### ### ### ###

require 'login2flickr.rc';

my $parser = XML::DOM::Parser->new();

## wczytanie pliku (za jednym zamachem) do napisu $uploaded_list
my $uploaded_list = do {
    local $/ = undef;
    open my $fh, "<", "$logfile"
        or die "could not open $file: $!";
    <$fh>;
};

unless ( $uploaded_list =~ /<uploaded>/) { $uploaded_list = "<uploaded>$uploaded_list</uploaded>"  }

my $log = $parser->parsestring($uploaded_list);

my $PlaceMarks ;

for $f ( $log->getElementsByTagName('file') ) {
  my $photo_lat = -999 ; my $photo_lon = -999;

  my $photo_geo = $f->getAttributeNode ("geo")->getValue() ;

  if ($photo_geo eq 'y') {
    my $photo_id = $f->getAttributeNode ("id")->getValue() ;
    my $photo_name = $f->getAttributeNode ("name")->getValue() ;

    if ( $f->getAttributeNode ("lat") ) { $photo_lat = $f->getAttributeNode ("lat")->getValue() };
    if ( $f->getAttributeNode ("lon") ) { $photo_lon = $f->getAttributeNode ("lon")->getValue() };

    ($photo_src, $photo_url)  = get_photo_urls($photo_id);

    print STDERR "*** photo_id = $photo_id ** $photo_url ***\n";

    $PlaceMarks .= "<Placemark><name>$photo_name</name><description>" .
      "<![CDATA[<a href='http://www.flickr.com/tprzechlewski/$photo_id/' target='_blank'>" .
      "<img src='$photo_src' />$photo_name</a>]]></description><Point><coordinates>$photo_lon,$photo_lat</coordinates></Point></Placemark>\n";

  }

}

### ### ### ###

my $Track ;

my $log = $parser->parsefile("$gpxfile");

for $f ( $log->getElementsByTagName('trkpt') ) {
  my $gpx_ele = -1;

  my $gpx_lat = $f->getAttributeNode ("lat")->getValue() ;
  my $gpx_lon = $f->getAttributeNode ("lon")->getValue() ;
  my @eles = $f->getElementsByTagName("ele");  if (@eles > 0) {
    ## Nie jestem pewien jak działa XML:DOM w przypadku gdy element zawiera tylko tekst
    ## czy zwraca jeden węzeł tekstowy czy więcej (na wszelki wypadek zakładam że więcej):
    $gpx_ele = ''; ## 
    #$gpx_ele = $eles[0]->toString() 
    my @tmp__ = $eles[0]->getChildNodes;
    foreach my $node ( @tmp__ ) { $gpx_ele .= $node->getNodeValue }
  }

  if ($ele < 0 ) { $Track .=  "$gpx_lon,$gpx_lat "}
  else { $Track .=  "$gpx_lon,$gpx_lat,$gpx_ele " }

}

### ### ### ###

print "<?xml version='1.0' encoding='UTF-8'?>\n";
print "<kml xmlns='http://www.opengis.net/kml/2.2' xmlns:gx='http://www.google.com/kml/ext/2.2'>\n<Document>\n";
print "$PlaceMarks";

print "<Placemark><name>Path1</name><LineString><tessellate>1</tessellate><coordinates>\n";

print "$Track";

print "</coordinates></LineString></Placemark>\n";

print "</Document></kml>\n";

### ### ### ###

sub get_photo_urls {
  my $pid = shift;

  $xml = get ("http://www.flickr.com/services/rest/?method=flickr.photos.getSizes&api_key=$api_key&photo_id=$pid");

  my $doc = $parser->parsestring($xml);

  for $s ( $doc->getElementsByTagName('size') ) {

    my $label = $s->getAttributeNode ("label")->getValue() ;

    if ($label eq $TargetLabel ) {
      my $source = $s->getAttributeNode ("source")->getValue() ;
      my $url = $s->getAttributeNode ("url")->getValue() ;
      return ("$source", "$url");
    }
  }
  return ('', '');
}

### koniec ###
