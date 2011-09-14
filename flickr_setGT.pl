#!/usr/bin/perl -s 
use Flickr::API;
use XML::Simple;
use Data::Dumper;
use Encode;
use Getopt::Long;

#http://search.cpan.org/~JHI/perl-5.8.0/pod/perluniintro.pod#Legacy_Encodings

use encoding 'latin2'; # ISO 8859-2

#$konwerter = Text::Iconv->new("iso-8859-2", "utf-8");

# Have big pain in the ass due to Byte->Unicode coopertion; I an still not
# devoted to unicode.
#
# Wide character in %s (W utf8) Perl met a wide character (>255) when it wasn't expecting
# one.  This warning is by default on for I/O (like print).  The
# easiest way to quiet this warning is simply to add the ":utf8" layer
# to the output, e.g. "binmode STDOUT, ':utf8'". 
# http://groups.google.pl/group/perl.beginners/browse_frm/thread/3c8277e9f7faff1/e97ab93b65f745e2?lnk=st&q=Wide+character+in+print+perl&rnum=5&hl=pl#e97ab93b65f745e2

binmode STDOUT, ':utf8';

$photolist = shift;

require 'login2flickr.rc';
$photolist .= '.ph' if !($photolist =~ /\./); 
require "$photolist";

my @tgs =();

#print "Tag list:\n";

my %latitudes=();
my %longitudes=();

my $p_ltagged=0;
my $p_gtagged=0;
my $p_ntagged=0;

my $locs_base = './knows/where.flk';
my $locs = get_mylocation_base($locs_base);
print "Fetched $locs locations from: $locs_base\n";

## experimental fragment
## add geo stuff to the photos marked with the following tags:
my $magic_words='Lublin|Zamo¶æ|KazimierzDolny|Kraków|Wieliczka|O¶wiêcim|Kraków|Xanthi';

%magictags = ('Grêzowo' => "Sopot-Grêzowo",
	      #'Rugby' => 'Sopot#StadionRugby',
	      'Grodzisko' => 'Sopot#Grodzisko',
	      'Bachotek' => 'Bachotek#O¶rodekUMK',
	      'M³yñska' => 'Sopot#M³yñska',
	      #'Swelina' => 'Sopot#DolinaSweliny',
	      'Molo' => 'Sopot#Molo-pocz±tek',
	      'Pier' => 'Sopot#Molo-pocz±tek',
              'Xanthi' => 'Xanthi',
              'Avdira' => 'Avdira',
              'PortoLagos' => 'PortoLagos',
	      #'KazimierzDolny' => 'KazimierzDolny',
	      #'Lublin' => 'Lublin',
	      'Zamo¶æ' => 'Zamo¶æ',
              'Osowa' => 'Gdañsk-Osowa#Rondo',
              'PolanicaZdrój' => 'PolanicaZdrój#PensjonatBeata',
              'RejaS³owackiego' => 'Sopot#RejaS³owackiego',
              'catalpatree' => 'Sopot#MickiewiczaBelwederek',
              'Wieliczka' => 'Wieliczka',
              'O¶wiêcim' => 'O¶wiêcim',
              'Kraków' => 'Kraków',
              'K³osowo' => 'K³osowo',
              'BrodnicaDolna'=>'BrodnicaDolna#domek79'
	     );

# check if all works
for $mt (keys %magictags ) {
   if ((! $magictags{$mt}) or (! $latitudes{$magictags{$mt}}) or
       (! $longitudes{$magictags{$mt}} )) {
   die "Wrong data! correct: $mt/$magictags{$mt}";
 } else { 
   #print "$magictags{$mt}/$latitudes{$magictags{$mt}}/$longitudes{$magictags{$mt}}\n"
 }
 }
print "Data seems OK!\n";
print "Start processing...\n\n";

##########
no encoding;
##exit;

##
my $api = new Flickr::API({'key' => $api_key,
              'secret' => $shared_secret } );

foreach $photo (@photos) {
    $pid = $photo->{id};

    ## get the tags
    @tgs = flickr_get_tags($api, $pid, $my_flickr_id);
    print "$pid: @tgs;\n";

    my $current_gid="NULL"; ##
    my $current_gid_tagged = 'NO';

    for $tt (keys %magictags) {
        $ltt =lc($tt);
        if ( grep( { lc($_) =~ /$ltt/} @tgs )) { 
           $current_gid = $magictags{$tt};
           last; }
    }
    ## Do not tag already geotagged stuff:
    if ( grep( { lc($_) =~ /geotagged/ } @tgs )) {
       $current_gid_tagged ="YES";
    }

    print "---> GID: $current_gid [ @tgs ] \n\n";

    if ($current_gid ne 'NULL' ) {
         if ($current_gid =~ /^($magic_words)$/) {
             $loc_accr = 11 } else { $loc_accr = 16 }
         my $gc = { latitude => $latitudes{$current_gid}, 
               longitude => $longitudes{$current_gid}, 
	       accuracy=> $loc_accr,
               location => $current_gid, };

         print ">> [$current_gid] $gc->{latitude}, $gc->{longitude}, $gc->{accuracy}\n";

     #if ($current_gid_tagged eq 'NO') {##
       $res1 = flickr_set_tag($api, $pid, "geo:loc=$gc->{location} " .
    	  "geo:lat=$gc->{latitude} " . "geo:lon=$gc->{longitude} " .
    	  "geotagged");

       $res2 = flickr_set_location($api, $pid, $gc );

       print "setting tags and coordinates...\n";
       print "[results] tags: $res1, coords: $res2.\n\n";
       $p_gtagged++;
       }
    #elsif ($current_gid ne 'NULL' and $current_gid_tagged eq 'YES' ) {
    #       $res1 = flickr_set_tag($api, $pid, "geo:loc=$current_gid");
    #       print "setting tags...\n";
    #       print "result: $res1.\n\n";
    #       $p_ltagged++;
    #}
    else {
       print "skipped...\n\n";
       $p_ntagged++;
    }

    $pnum++;

    #if ($pnum > 99) { last; }
  }

print "Geotagged: $p_gtagged x Loctagged: $p_ltagged x Notagged: $p_ntagged \n";

#
#
#==================================================================
sub get_mylocation_base {
   my $locations_base = shift;
   my $locations=0;

   my $lbase = new XML::Simple ( );
   my $lb = $lbase->XMLin($locations_base,
     keyattr => { wpt => 'identifier' },
     forcearray=>['wpt']);

   my $wptList = $lb->{wpt};

   foreach $l (keys %{$wptList}) {
     my $loc = $wptList->{$l};
     #print $l, " => ", $loc->{lat}, " x ", $loc->{lon}, "\n";
     $latitudes{ $l } = $loc->{lat};
     $longitudes{ $l } = $loc->{lon};
     $locations++;
   }
   return $locations;
}


#==================================================================
sub flickr_set_location {
## Set the geo data (latitude, longitude and accuracy level). Before users
## may assign location data to a photo they must define who, by default, may view
## that information. Users can edit this preferences at
## http://www.flickr.com/account.geo/privacy. If not set, the API method will
## return an error (see more at API doc page, address below).
## Usage: flickr_set_location(flickr, photoid, geocoords);
##  where `flickr' = pointer to flickr object created with new Flickr::API(...);
##  `photoid' = id of the photo to which add the tags;
##  `gc' = pointer to hash containing geo data:
##      { latitude =>, longitude =>, accuracy=> }
#
   my $flickr = shift; # pointer to flickr object created with new Flickr::API(...)
   my $photo_id = shift; # details of the photo (pointer to hash)
   my $gc = shift; # see above
   my $debugmode = 0;

   my $acc = $gc->{accuracy} || '16'; # Accuracy: 1..16

   print ">> $gc->{latitude}, $gc->{longitude}, $gc->{accuracy}\n" if $debugmode;

   #  http://www.flickr.com/services/api/flickr.photos.geo.setLocation
   my $response = $flickr->execute_method('flickr.photos.geo.setLocation',
   { auth_token  => $auth_token,
      photo_id   => $photo_id,
      lat        => $gc->{latitude},
      lon        => $gc->{longitude},
      accuracy   => $acc,
   });

   if ( !$response->{success} ) { #warn "Problem: $response->{error_message}\n"
      return "$response->{error_code}"; } # take care of the error in the main prog.
   else { return 'OK'}
}

#==================================================================
sub flickr_set_tag {
## Add tags to a photo, 
## Usage: flickr_set_tag(flickr, photoid, tags)
## where `flickr' = pointer to flickr object created with new Flickr::API(...);
##  photoid = id of the photo to which add the tags;
##  tags = string of space-separated tags (use \"word1 word2\" for multi-word tags)
#
   my $flickr = shift; # pointer to flickr object created with new Flickr::API(...)
   my $photo_id = shift; # details of the photo (pointer to hash)
   my $tags = shift; # taglist zamieniæ na utf

   ## convert to UTF:
   ##$tags = $konwerter->convert($tags);
   $tags = Encode::encode("utf-8", $tags);

   ## http://www.flickr.com/services/api/flickr.photos.addTags
   my $response = $flickr->execute_method('flickr.photos.addTags',
   { auth_token  => $auth_token,
      photo_id   => $photo_id,
      tags       => $tags, });

   if ( !$response->{success} ) { #warn "Problem: $response->{error_message}\n"
      return "$response->{error_code}"; } # take care of the error in the main prog.
   else { return 'OK'}

}

#==================================================================
sub flickr_get_tags {
## return list of tags for given $photo_id, optional $who argument determines
## whose tags are returned: if valid user_id is passed, only tags defined by this user
## will be returned, precede user_id with minus sign to get all tags defined not
## by this particular user, if $who is not set all tags will be returned (default)
#
  my $flickr = shift; # pointer to flickr object created with new Flickr::API(...)
  my $photo_id = shift; # id of the photo
  my $who = shift; # id of the photo owner (optional)

  my $debugmode = 0; # change to 1 to see extra output
  my @list_of_tags = ();
  my $mode; #
  my $t;

  # set the mode to: '*', '-', or 'm'
  if (! $who ) {# $who not set, get all tags
     $mode = '*'; }
  elsif ($who =~ /^\-/) {# $who set to some ID with preceding '-'
     $mode = '-'; $who =~ s/^\-//;
  } else { $mode = 'm'; }

  print ("?? who: $who; mode: $mode; photo: $photo_id;\n") if $debugmode;

  my $xmlp = new XML::Simple ( );

  ## http://www.flickr.com/services/api/flickr.tags.getListPhoto
  my $response = $flickr->execute_method('flickr.tags.getListPhoto',
    { photo_id  => $photo_id, } );

  die "Problem: $response->{error_message}\n" if !$response->{success};

  my $xm = $xmlp->XMLin($response->{_content}, forcearray=>['tag']);

  my $tagList = $xm->{photo}->{tags}->{tag};

  foreach $t (keys %{$tagList}) {
     my $tag = $tagList->{$t};
     print ("?? ", $t, " : ", $tag->{raw}, " : ", 
                $tag->{author}, "\n") if $debugmode;

     if ($mode eq 'm') {
        if ($tag->{author} eq $who ) {
           push @list_of_tags, $tag->{raw}; } 
     } elsif ( $mode eq '-') {
        print "?? tagauthor: $tag->{author} autor: $who\n" if $debugmode;
        if ( $tag->{author} ne $who ) {
           push @list_of_tags, $tag->{raw}; } 
     }
     else {
        push @list_of_tags, $tag->{raw}; } 
  }

  return @list_of_tags;

}

#====================================================
sub utf2ascii {
 my $text = shift;
 $text = encode("iso-8859-2", $text);
 return $text;
}
