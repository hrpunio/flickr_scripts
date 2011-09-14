#!/usr/bin/perl
#
# Usage:
# perl flickr_xload.pl [options] file
#
# Uwaga: opisy zbiorów (sets) nie powinny zawieraæ polskich znaków (na razie) trzeba poprawiæ
# parsowanie/zapis pliku konfiguracyjnego
#
# Extended flickr_upload, see: http://search.cpan.org/~cpb/Flickr-Upload/ 
# for the original version
#
#eval 'exec /usr/bin/perl  -S $0 ${1+"$@"}'
#    if 0; # not running under some shell

##use strict;   # te wpisy sa w konflikcie
##use warnings; # z require
use Flickr::Upload;
use Flickr::API; ## --tp--
use Image::ExifTool; ## --tp--
use Geo::Coordinates::DecimalDegrees; ## --tp--
#use Text::Iconv; ## --tp--
use Getopt::Long;
use Pod::Usage;
#use Image::Magick; # --tp--
use Data::Dumper;
##use XML::Simple;
##
##

my $credentials = "Tomasz Przechlewski";
my $license_stmt = "Licence: CC Attribution";
my $flickr_base = "http://www.flickr.com/photos/tprzechlewski";

my ($location, $longitude, $latitude, $accuracy);
#my $api_key ; # nie mozna bo nie dziala (our !)
#my $shared_secret ; # require
my $geotagged;

my %args;
my @tags = ();
my $help = 0;
my $man = 0;
my $auth = 0;

# Utils/Authentication:
require 'flickr_utils.rc';
require 'login2flickr.rc';

my $not_so_secret = $shared_secret ; # zasz³o¶æ

$args{'auth_token'}=$auth_token;
$args{'api_key'}=$api_key;
$args{'shared_secret'}=$shared_secret;

GetOptions(
    'help|?' => \$help,
    'man' => \$man,
    'tag=s' => \@tags, # @ means, multiple -tag tag are allowed --tp--
    'uri=s' => sub { $args{$_[0]} = $_[1] },
    'auth_token=s' => sub { $args{$_[0]} = $_[1] },
    'public=i' => sub { $args{is_public} = $_[1] },
    'friend=i' => sub { $args{is_friend} = $_[1] },
    'family=i' => sub { $args{is_family} = $_[1] },
    'title=s' => sub { $args{$_[0]} = $_[1] },
    'description=s' => sub { $args{$_[0]} = $_[1] },
    'key=s' => \$api_key,
    'secret=s' => \$not_so_secret,
    'auth' => \$auth,
    'gt=s' => \$geotagged, ## -- tp --
    'preserve-geo' => \$preservegeo, # do not update geoTags
    'set=s' => \$setids,    ## -- set ids, comma separated --
    'pool=s' => \$poolids,   ## -- pool ids, comma separated --
    'rotate=i' => \$rotate,  ## -- rotation --
    'credentials=s' => \$credentials,
    'license=s' => \$license_stmt,
) or pod2usage(2);

pod2usage(1) if $help;
pod2usage(-exitstatus => 0, -verbose => 2) if $man;

my $version = qw($Revision: 1.9 $)[1];

my $ua = Flickr::Upload->new( {'key' => $api_key, 'secret' => $not_so_secret} );

$ua->agent( "flickr_upload/$version" );

## 
my $api = new Flickr::API({'key' => $api_key, 'secret' => $shared_secret } );

if( $auth ) {
  # The user wants to authenticate. There's really no nice way to handle this.
  # So we have to split out a URL, then hang around or something until
  # the user hits enter, then exchange the frob for a token, then tell the user what
  # the token is and hope they care enough to stick it into .flickrrc so they
  # only have to go through this crap once.

  # 1. get a frob
  my $frob = getFrob( $ua );

  # 2. get a url for the frob
  my $url = $ua->request_auth_url('write', $frob);

  # 3. tell the user what to do with it
  print "1. Enter the following URL into your browser\n\n",
    "$url\n\n",
      "2. Follow the instructions on the web page\n",
			"3. Hit <Enter> when finished.\n\n";
  # 4. wait for enter.
  <STDIN>;

  # 5. Get the token from the frob
  my $auth_token = getToken( $ua, $frob );
  die "Failed to get authentication token!" unless defined $auth_token;

  # 6. Tell the user what they won.
  print "You authentication token for this application is\n\t\t", $auth_token, "\n";
  exit 0;
}

pod2usage(1) unless exists $args{'auth_token'};
pod2usage(1) unless @ARGV;

$args{'tags'} = join( " ", @tags ) if @tags;

my $exifTool = new Image::ExifTool; ## //tp//

# pipeline things by uploading first, waiting for photo ids second.

$args{'async'} = 1;

my %tickets;
my %user_comments;

$| = 1;

## This loop is unnecessary now:
while( my $photo = shift @ARGV ) {
  ## Problems with rotation 
  if ( $rotate )    { hard_rotate_photo($photo, $rotate ); }

  print "** Uploading $photo...\n";
  #http://tadek.pietraszek.org/blog/2005/11/01/\
  #   on-image-geotagging-or-why-i-love-imageexiftools-hate-gpsgarmin-and-am-indifferent-to-garmin-transfer-protocol/
  $exifTool->ExtractInfo($photo);
  my @taglist = $exifTool->GetFoundTags('File'); ## Hmm ????

  #my $photo_info = $exifTool->ImageInfo($photo);
  #my $gcrds = $exifTool->GetValue('GPSLatitude'); # is already geotagged

  if ( $geotagged ) {
    ## location maybe empty if `naked' coordinates given or photo has appriopriate
    ## Exif tags defined:
    ($latitude, $longitude, $location, $accuracy) = split (/:/, $geotagged);
    if ( $preservegeo ) { print "** [$photo] already geotagged ...\n"; }
    else  { print "** Adding [$latitude $longitude $location] to [$photo]...\n";
	    set_gps_exif($exifTool, $latitude, $longitude, $location); }
  } 
  else { print "** Geocoordinates for [$photo] not provided ...\n"; }

  # add more Exif tags:
  add_more_exif($exifTool, $photo);

  # rewrite Photo to update Exif:
  $exifTool->WriteInfo($photo);

  # $rc to jest tzw. Ticket ID
  # Prawdziwe ID jest pobierane przez $ua->check_upload (patrz ni¿ej):
  # http://articles.techrepublic.com.com/5100-10878_11-5363190.html
  my $rc = $ua->upload( 'photo' => $photo, %args );

  # let the caller know how many images weren't uploaded
  exit (1+@ARGV) unless defined $rc;

  # check those later
  $tickets{$rc} = $photo;

  print "\n";

}


# =====
# check
# =====

open LOG, ">>upload.log";
print LOG "<log date='", get_date(), "'>\n";

print "** Waiting for upload results (ctrl-C if you don't care)\n";

do {
  sleep 1;

  my $ori_photo_name; ## //tp//
  my @checked = $ua->check_upload( keys %tickets );

  for( @checked ) {
    if( $_->{complete} == 0 ) {# not done yet, don't do anythig
    } elsif( $_->{complete} == 1 ) {
      # uploaded, got photoid
      $ori_photo_name =  $tickets{ $_->{id} }; ## dodane //tp//
      delete $tickets{$_->{id}};

      my $pid = $_->{photoid} ;
      # tp extensions: print to log ---
      print LOG "<file name=\"$ori_photo_name\" id=\"$pid\"";

      if ( $geotagged ) { add_geo_tags($pid, $latitude, $longitude, $accuracy, $location) }
      if ( $setids )    { add_set_ids($pid, $setids);  }
      if ( $poolids )   { add_pool_ids($pid, $poolids); }

      #if ( $rotate )    { rotate_photo( $pid, $rotate ); }

      print LOG "/>\n"; # zamknij znacznik <file...

      ## Plik jest ju¿ za³adowany. Do lokalnej kopii dodajemy Flickr ID
      ## Do pola ImageUniqueID oraz UserComment (ni¿ej)
      $exifTool->SetNewValue(ImageUniqueID => "$flickr_base/$pid/");

      $exifTool->ImageInfo($ori_photo_name); ##

      ## Tu jest problem w jakim kodowaniu jest UserComment je¿eli robimy to przez odczyt i dopisanie
      #my $old_comment_text = $exifTool->GetValue('UserComment');
      #print STDERR "Old comment found: $old_comment_text\n";
      ###
      #$old_comment_text =~ s/[ ]*\[$flickr_base\/[0-9]+\/\]//; ## ** je¿eli ju¿ jest ID flickra usuñ **
      #$old_comment_text .= "[$flickr_base/$pid/]"; ## dodaj ID flickra
      #$old_comment_text =~ s/^[ ]+//; $old_comment_text =~ s/[ ]+$//; # usuñ niepotrzebne odstêpy
      #$exifTool->SetNewValue(UserComment => "$old_comment_text");
      #
      # Dlatego wpisujemy wszystko raz jeszcze:
      $exifTool->SetNewValue(UserComment => "$user_comments{$ori_photo_name} [$flickr_base/$pid/]");

      $exifTool->WriteInfo($ori_photo_name);
      print STDERR "Write Flickr ID to $ori_photo_name ($pid)\n";

    } else {
      # fail to upload photos
      print LOG "<failed name=\"$tickets{$_->{id}}\"/>\n";
      delete $tickets{$_->{id}};
    }
  }
} while( %tickets );


print LOG "</log>\n";
close (LOG);

exit 0;

# //////////////////////////////////////////////////////////////////////

sub response_tag {
  my $t = shift;
  my $name = shift;
  my $tag = shift;

  return undef unless defined $t and exists $t->{'children'};

  for my $n ( @{$t->{'children'}} ) {
    next unless $n->{'name'} eq $name;
    next unless exists $n->{'children'};

    for my $m (@{$n->{'children'}} ) {

      next unless exists $m->{'name'}
	and $m->{'name'} eq $tag
	  and exists $m->{'children'};

      return $m->{'children'}->[0]->{'content'};
    }
  }
  return undef;
}

# /////////
sub getFrob {
  my $ua = shift;

  my $res = $ua->execute_method("flickr.auth.getFrob");
  return undef unless defined $res and $res->{success};

  # FIXME: error checking, please. At least look for the node named 'frob'.
  return $res->{tree}->{children}->[1]->{children}->[0]->{content};
}

# //////////
sub getToken {
  my $ua = shift;
  my $frob = shift;

  my $res = $ua->execute_method("flickr.auth.getToken",
		{ 'frob' => $frob } );
  return undef unless defined $res and $res->{success};

  # FIXME: error checking, please.
  return $res->{tree}->{children}->[1]->{children}->[1]->{children}->[0]->{content};
}

# //////////////////////////////////////////////////////////////////////
# ///////////////
sub set_gps_exif {
  my $eT = shift @_;
  my $lat = shift @_;
  my $lon = shift @_;
  my $loc = shift @_;

  # $eT->ExtractInfo($file);
  # my @taglist = $eT->GetFoundTags('File');

  my ($degrees, $minutes, $seconds) = decimal2dms($lat);

  $eT->SetNewValue(GPSLatitudeRef => ($lat > 0)?'N':'S', Group=>'GPS');
  $eT->SetNewValue(GPSLongitudeRef => ($lon > 0)?'E':"W", Group=>'GPS');
  $eT->SetNewValue(GPSLatitude => abs($lat), Group=>'GPS');

  ($degrees, $minutes, $seconds) = decimal2dms($lon);
  $eT->SetNewValue(GPSLongitude => abs($lon), Group=>'GPS');

  if ($loc) {# sometimes $loc can be empty
      $eT->SetNewValue(GPSAreaInformation => "$loc", Group=>'GPS'); }

  return ;

}

# ///////////////
## http://www.flickr.com/services/api/flickr.photos.geo.setLocation.html
sub add_geo_tags {
  my $pid = shift @_ ;

  my $lat = shift @_ ;
  my $lon = shift @_ ;
  my $acc = shift @_ ;

  my $loc = shift @_ ;

  my $response = $api->execute_method('flickr.photos.geo.setLocation',
     { auth_token => $auth_token,
       photo_id => $pid,
       lat => $lat,
       lon => $lon,
       accuracy => $acc,
     });

  # print result:
  if ( $response->{success} ) {
    print "** Geocoordinates: [$lat $lon $loc $acc] set to $pid ...\n"; }
  else { print "** Error: geocoordinates not set [errcode = $response->{error_code}]\n"; }

  print LOG " geo=\"y\"";
  return ;
}

## /////////////
sub add_set_ids {
  my $pid = shift @_ ;
  my $setids = shift @_ ;

  ## Uwaga: opisy zbiorów nie powinny zawieraæ polskich znaków ** co¶ nie dzia³a 
  ## konwersja ISO-UTF ** trzeba poprawiæ
  my %available_sets = get_sets_ids();
  my @set_pool_lid = split (/,/, $setids);
  my @set_pool =  map { $available_sets{$_} } @set_pool_lid ;

  print "** Adding $pid to sets...\n";

  for $set_id_ (@set_pool) { #flickr.photosets.addPhoto
    my $response = $api->execute_method('flickr.photosets.addPhoto',
	{ auth_token => $auth_token,
	  photo_id   => $pid,
	  photoset_id => $set_id_,
	});

    if ( $response->{success} ) { print "** $pid added to set $set_id_ **\n"; }
    else { print "** failed to add $pid to set $set_id_ **\n";  }
  }
}

## //////////////
sub add_pool_ids {
  my $pid = shift @_ ;
  my $poolids =  shift @_ ;

  my %available_pools = get_pools_ids();

  my @pool_pool_lid = split (/,/, $poolids);
  my @pool_pool =  map { $available_pools{$_} } @pool_pool_lid ;

  print "** Adding $pid to pools...\n";

  for $pool_id_ (@pool_pool) { #flickr.groups.pools.add
    my $response = $api->execute_method('flickr.groups.pools.add',
       { auth_token => $auth_token,
         photo_id => $pid,
         group_id => $pool_id_,
       });

    if ( $response->{success} ) {#--tp--
      print "** $pid added to pool $pool_id_\n"; }
    else { print "** $failed to add pid to pool $pool_id_\n";  }
  }
}

## /////////////
## http://vomperbach.com/tiki-index.php?page=Exiftool-Skript&PHPSESSID=c493e4f4741e8414fa06fecf66a9142a
## Add copyright/image decription tags:
sub add_more_exif {
  my $eT = shift @_;
  my $photo_file = shift @_;

  if ($verbose ) { print STDERR "*** Setting Creator/License...\n"; }

  ## Pole `ImageUniqueID' musi byæ puste, bo nie znamy Flickr ID ³aduj±c plik na flickr, gdyby co¶ tam
  ## by³o (np. bo plik by³ ju¿ ³adowany trzeba to usun±æ)
  ## http://www.sno.phy.queensu.ca/~phil/exiftool/ExifTool.html#SetNewValue
  $eT->SetNewValue(ImageUniqueID); # ** bez podanie warto¶ci usuwa **
  $eT->SetNewValue(Artist => "Creator: $credentials");
  $eT->SetNewValue(Author => "Creator: $credentials");

  $eT->SetNewValue(Copyright => "$license_stmt");

  if ( $description ) { 
    $eT->SetNewValue(ImageDescription => "$description"); }

  if ( @tags ) { # remove tags containing `:' (machine tags)
      ## @tags contains multiple tags "tag1" "tag2": 
      my @xtags = split ( /[ \t]+/, join( " ", @tags ));
      my $usercomment = join (" ", grep ( !/:/, @xtags ));

      ## separate tags with comma:
      $usercomment =~ s/"[ \t]+"/, /g;
      $usercomment =~ s/\"//g; # remove leading/trailing

      $eT->SetNewValue(UserComment => "$usercomment");

      # skopiowanie na potrzeby dodania do lokalnego pliku
      $user_comments{$photo_file} = "$usercomment"; # skopiuj
  }
}

## /////////////
sub hard_rotate_photo {
  my $photo = shift @_ ;
  my $rot = shift @_ ;

  print "** Rotating $photo _file_ in-place with $rot\n";

  if ( system("cp", "$photo", "${photo}_orig") == 0 ) {
     system("jpegtran", "-rotate", "$rot", "-copy", "all", "-outfile", "$photo", "${photo}_orig" ) == 0
        or die "** system command jpegtran failed: $? **";
     # clear rotation/orientation so that some viewers (e.g. Eye
     # of GNOME) won't be fooled
     system("jhead", "-norot", "$photo") == 0
        or die "** system command jhead failed: $? **";
  } else { print "** Rotating $photo with $rot failed\n"; }
}

## /////////////
sub rotate_photo {
  my $pid = shift @_ ;
  my $rot = shift @_ ;

  print "** Rotating $pid with $rot using FlickrAPI\n";

  ## Co¶ nie dzia³a ; nie wiem czemu!!!
  ## Problem; flickr nie obraca zdjêæ:
  ##my $rotapi = new Flickr::API({'key' => $api_key,
  ##           'secret' => $shared_secret } );

  my $response = $api->execute_method('flickr.photos.transform.rotate',
     { auth_token => $auth_token,
       photo_id => $pid,
       degrees => $rot,
      });

   # *** print result: ***
   unless ( $response->{success} ) { print "** Error: rotating photo $pid with $rot **\n"; }
   #print Dumper ($response);

}

sub get_date {# return date as: yyyymmddhhmm string
   my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime time;
   $year += 1900 ; $mon += 1;
   return ( sprintf "%4.4d%2.2d%2.2d%2.2d%2.2d", $year, $mon, $mday, $hour, $min );

}

# //////////////////////////////////////////////////////////////////////

__END__

=head1 NAME

flickr_upload - Upload photos to C<flickr.com>

=head1 SYNOPSIS

flickr_upload [--auth] --auth_token <auth_token> [--title <title>]
	[--description description] [--public <0|1>] [--friend <0|1>]
	[--family <0|1>] [--tag <tag>] <photos...>

=head1 DESCRIPTION

Uploads images to the L<Flickr.com> service.

=head1 OPTIONS

=over 4

=item --auth

The C<--auth> flag will cause L<flickr_upload> to generate an authentication token
against it's API key and secret (or, if you want, your own specific key and secret).
This process requires the caller to have a browser handy so they can cut and paste a
url. The resulting token should be kept somewhere like C<~/.flickrrc> since it's
necessary for actually uploading images.

=item --auth_token <auth_token>

Authentication token. Required.

=item --title <title>

Title to use on all the images. Optional.

=item --description <description>

Description to use on all the images. Optional.

=item --public <0|1>

Override the default C<is_public> access control. Optional.

=item --friend <0|1>

Override the default C<is_friend> access control. Optional.

=item --family <0|1>

Override the default C<is_friend> access control. Optional.

=item --tag <tag>

Images are tagged with C<tag>. Multiple C<--tag> options can be given, or
you can just put them all into a single space-separated list.

=item --key <api_key>

=item --secret <secret>

Your own API key and secret. This is useful if you want to use L<flickr_upload> in
auth mode as a token generator. You need both C<key> and C<secret>. Both C<key> and
C<secret> can be placed in C<~/.flickrrc>, allowing you to mix L<flickr_upload> with
your own scripts using a single API key and authentication token.

=item <photos...>

List of photos to upload. Uploading stops as soon as a failure is detected
during the upload. The script exit code will indicate the number of images
on the command line that were not uploaded. For each uploaded image, a Flickr URL
will be generated. L<flickr_upload> uses asynchronous uploading so while the image is
usually transferred fairly quickly, it might take a while before it's actually
available to users. L<flickr_upload> will wait around for that to complete, but be
aware that delays of upwards of thirty minutes have (rarely) be know to occur.

=head1 CONFIGURATION

To avoid having to remember authentication tokens and such (or have them show up
in the process table listings), default values will
be read from C<$HOME/.flickrrc> if it exists. Any field defined there can, of
course, be overridden on the command line. For example:

	# my config at $HOME/.flickrrc
	auth_token=334455
	is_public=0
	is_friend=1
	is_family=1

=head1 BUGS

Error handling could be better.

=head1 AUTHOR

Christophe Beauregard, L<cpb@cpan.org>.

=head1 SEE ALSO

L<flickr.com>

L<Flickr::Upload>

=cut
