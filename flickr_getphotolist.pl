#!/usr/bin/perl -s 
# 
# Adapted Hack #33 (chapter 5) from Flickr Hacks, by Paul Bausch, Jim Bumgardner 
# O'Reilly, ISBN: 0-596-10245-3.
# Get list of public photos with 'flickr.people.getPublicPhotos
# As method's name suggests: _only public photos are returned_
# 
# $verbose = 1;

use Flickr::API;
use XML::Simple;
use Data::Dumper;
$Data::Dumper::Terse = 1;  # avoids $VAR1 = * ; in dumper output 
$Data::Dumper::Indent = $verbose? 1 : 0;  # more concise output 

use Compress::Zlib ;

require 'login2flickr.rc';

print "verbose = $verbose\n" if $verbose; 

$syntax = <<EOT; 
Get photo descriptions from flickr, store them in a file <tag>.ph
  getPhotoList.pl [options] <tags> [<tags...>] 
  getPhotoList.pl [options] -g group_id [<tag>]
  getPhotoList.pl [options] -u username [<tags>] 
Options: 
  -all       Photos must match all tags (tag search only) 
  -recent=X  Only provide photos posted within the last X days (tag searches only) 
  -limit=X   Provide no more than X photos 
  -license=X Provide photos with license X 
EOT

die $syntax if @ARGV == 0; 
my $api = new Flickr::API({'key' => $api_key, secret => $sharedsecret}); 

# determine method to use 
$method = 'flickr.photos.search'; 

if ($g) { 
  $group_id = shift;
  $tags = shift;
  $method = 'flickr.groups.pools.getPhotos';
  print "Searching for photos in group $group_id\n"; 
  # determine output filename 
  $ofname = $group_id . '.ph'; 
} 
elsif ($u) { 
  $username = shift; 
  $tags = join ',', @ARGV; 
  $method = 'flickr.people.getPublicPhotos' if !$tags; 
  print "Searching for photos by user $username using $method\n"; 
  # determine output filename 
  $ofname = "$FLICKRCFG/" . $username; ## --tp-zmienil--
  $ofname .= '_' . $tags if $tags; 
  $ofname =~ s/,\s*/_/g; 
  $ofname .= '.ph'; 
} 
else { 
  $tags = join ',', @ARGV; 
  print "Searching for photos with tags=$tags ...\n"; 
  # determine output filename 
  $ofname = $tags . '.ph'; 
  $ofname =~ s/,\s*/_/g; 
} 

$nbrPages = 0; 
$photoIdx = 0; 
$limit = 5000 if $limit; 

print STDERR "Writing to $ofname\n";

open (OFILE, ">$ofname"); 
print OFILE "## created with flickr_getphotolist.pl\n";
print OFILE "\@photos = (\n"; 
$user_id = ''; 
$min_taken_date = ''; 
$max_taken_date = ''; 

$xmlp = new XML::Simple ( ); 

if ($recent)  
{ 
  die "-recent option only valid for tag search\n" if $method ne 'flickr.photos.search'; 
  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = 
        gmtime(time - $recent*24*60*60); 
  $min_taken_date = sprintf "%04d-%02d-%02d 00:00:00",1900+$year,$mon+1,$mday; 
  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = 
        gmtime(time); 
  $max_taken_date = sprintf "%04d-%02d-%02d 00:00:00",1900+$year,$mon+1,$mday; 
} 

if ($username) {
  # look up user ID if a username was provided 
  # 
  my $response = $api->execute_method('flickr.people.findByUsername', { username => $username } );
  die "Problem determining user_id: $response->{error_message}\n" if !$response->{success};

  print Dumper($response) if $verbose;  # explore results of call using -verbose 
  ## to co ponizej jest `q&d' hack zakladajacy ze czasami _content jest plain txt a czasami jest gziped
  ## print STDERR "** A >>> **" . $response->{_headers}->{content-encoding} . "\n";
  ## 2011/08/15
  my $content_encoding = $response->{_headers}->{'content-encoding'} ;

  ## print STDERR "Content encoding: $content_encoding\n";

  ##print STDERR "** A >>> **" . Compress::Zlib::memGunzip( $response->{_content}) . "\n";
  my $plain_content;
  if ($content_encoding =~ /gzip/ ) {##
    $plain_content = Compress::Zlib::memGunzip( $response->{_content}); 
  } else { $plain_content = $response->{_content};  }

  $xm = $xmlp->XMLin($plain_content);

  $user_id = $xm->{user}->{id};
  print "Userid: $user_id\n";
}

do
{ 
  my $params = {  per_page => 500, 
                  page => $nbrPages+1}; 
  $params->{tags} = $tags if $tags; 
  $params->{user_id} = $user_id if $user_id; 
  $params->{group_id} = $group_id if $group_id; 
  $params->{min_taken_date} = $min_taken_date if $min_taken_date; 
  $params->{max_taken_date} = $max_taken_date if $max_taken_date; 
  $params->{license} = $license if $license; 
  $params->{extras} = $extras if $extras; 
  $params->{tag_mode} = 'all' if $all; 

  my $response = $api->execute_method($method, $params ); 
  
  die "Problem: $response->{error_message}\n" if !$response->{success}; 
  print Dumper($response) if $verbose;  # explore results of call using -verbose 

  ## sprawdz czy _content nie jest gzipniety, jezeli to rozpakuj:
  my $content_encoding = $response->{_headers}->{'content-encoding'} ;
  my $plain_content ;
  if ($content_encoding =~ /gzip/ ) {##
    $plain_content = Compress::Zlib::memGunzip( $response->{_content}); 
  } else { $plain_content = $response->{_content};  }

  #my $xm = $xmlp->XMLin($response->{_content},forcearray=>['photo']); 
  my $xm = $xmlp->XMLin($plain_content, forcearray=>['photo']); 

  $photos = $xm->{photos}; 
  print "Page $photos->{page} of $photos->{pages}\n"; 

  # loop thru photos 
  $photoList = $xm->{photos}->{photo}; 

  foreach $id (keys %{$photoList}) 
  { 
    my $photo = $photoList->{$id}; 

    $photo->{id} = $id; 

    print OFILE ($photoIdx++? ",\n" : "") . Dumper($photo); 
  } 

  ++$nbrPages; 

} while ($photos->{page} < $photos->{pages} && (!$limit || $photoIdx < $limit)); 

print OFILE "\n);\n1;\n"; 
close OFILE; 
print "$photoIdx photos found matching tags $tags written to $ofname\n";
