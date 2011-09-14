#!/usr/bin/perl
# kopiowanie pliku KML z usuni�ciem element�w Placemark, zawieraj�cych zdj�cia kt�rych nie ma na flickr.com
# zdj�cia s� identyfikowane przez nazw� pliku ze zdj�ciem (tytu� zdj�cia na flickr.com jest r�wny nazwie lokalnej)
# skrypt dzia�a je�eli tytu�y s� unikatowe
#
use XML::LibXML;

my $file = shift || die "Podaj nazw� pliku GPX";
my ($file_name, $file_extension) = split /\./, $file;
my $wpts_file_name = "$file_name.wpts";
my $all_photos=0;
my $missing_photos=0;
my $flickr_update_kb = 'flickr_update_kb'; # program do od�wie�ania bazy lokalniej

my $parser = XML::LibXML->new;

open my $fh, $file || die "problems...";

$doc = $parser->parse_fh($fh);

## http://www.perlmonks.org/?node_id=249394
## for my $dead ($d->findnodes(q{/opt/node[val = "2"]})) {
##   $dead->unbindNode; }
## print $d->toString;

## http://search.cpan.org/dist/XML-LibXML/lib/XML/LibXML/Node.pod

## Nie dzia�a:
#my $xpc = XML::LibXML::XPathContext->new;
#$xpc->registerNs('gpx', 'http://www.topografix.com/GPX/1/0');

for $n ( $doc->getElementsByLocalName('Placemark' ) ) {
  # Nie tylko zdj�cia s� wewn�trz 'Placemark'
  if ( $lookAt = $n->getChildrenByTagName('LookAt')->[0] ) { # Zdj�cia zawieraj� element LookAt
    $all_photos++;

    $lon = $lookAt->getChildrenByTagName('longitude')->[0]; ## $lon = $lookAt->findvalue('longitude'); 
    $lat = $lookAt->getChildrenByTagName('latitude')->[0];
    if ( $name = $n->getChildrenByTagName('name')->[0] ) {
      $picture_name = $name->textContent();
      printf "znalaz�em %s w %f %f\n", $picture_name, $lon->textContent(), $lat->textContent();

      ($pic_title, $pic_extension) = split /\./, $picture_name;

      $urls = `flickr_photo_urls $pic_title -a -s=m`; # sprawdzenie czy jest zdj�cie, -s=m okre�la rozmiar

      if ($? > 0 ) { ## `flickr_photo` zako�czy�o si� b��dem - nie ma zdj�cia
	$n->unbindNode(); ## usu� bo nie ma
	$missing_photos++;
      } else {
	# `flickr_photo` zwraca trzy elementy: nazwe URL-do-strony URL-do-miniaturki
        # potrzebne s� dwa ostatnie, pierwszy pomijamy:
      	($gobble, $url1, $url2) = split (/[ \t]+/, $urls);

	#print ">>> $url1 $url2\n"; ## debug

	push (@Wpts, [ $picture_name, $lon->textContent(), $lat->textContent(), $url1, $url2 ] ); # zapami�taj

	if ( $dscr = $n->getChildrenByTagName('description')->[0] ) {
	  $new_dscr = XML::LibXML::Element->new('description');
	  $new_dscr_content = XML::LibXML::CDATASection->new( "<a href=\"$url1\"><img src=\"$url2\" width=\"200\" /></a><br><a href=\"$url1\">full size</a>" );
	  $new_dscr->addChild($new_dscr_content);

	  # ew. mo�e by� $n->replaceChild($new_dscr, $dscr); # uwaga zamiana $new_dscr i $dscr
          #   daje w wyniku SegFault cf. http://osdir.com/ml/lang.perl.xml/2002-11/msg00093.html
	  $dscr->replaceNode($new_dscr);

	}
      }
    }
  }
}

my ($kml_file_name, $kml_file_extension) = split /\./, $file;
open OUT, ">${kml_file_name}_ok.$kml_file_extension"; ## nazwa poprawionego pliku KML

print OUT $doc->toString();

## to samo ale w formacie GPX ####
open WPS, ">$wpts_file_name" || die "Nie mog� otworzy� $wpts_file_name ";

for $w (@Wpts) {
   $pic_name = $w->[0]; $pic_lon = $w->[1]; $pic_lat = $w->[2]; $pic_url1 = $w->[3]; $pic_url2 = $w->[4];
   print WPS "<wpt lat='$pic_lat' lon='$pic_lon'><ele/><name>$pic_name</name>\n" .
    "<extensions><html><![CDATA[<a href='$pic_url1' target='_blank'><img src='$pic_url2' /></a>]]>" .
      "</html></extensions></wpt>\n";
}

printf "*** Znaleziono na flickr.com %d z %d zdj��\n", $all_photos - $missing_photos, $all_photos;

if ($missing_photos > 0) { print "*** By� mo�e nale�y wykona� $flickr_update_kb\n" }

### koniec
