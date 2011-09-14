#!/usr/bin/perl -s 
# 
# getPhotoList.pl - Jim Bumgardner 
# Hack #33 (chapter 5)
# ** Uwaga: ten skrypt pobiera tylko zdjêcia o statusie Public**
use Flickr::API; 
use XML::Simple; 
use Data::Dumper; 
$Data::Dumper::Terse = 1;  # avoids $VAR1 = * ; in dumper output 
$Data::Dumper::Indent = $verbose? 1 : 0;  # more concise output 

# You will need to create this file... 
# it supplies the authentication-related vars  
# $api_key and $sharedsecret 
# [[it is required from the current dir, which maybe cumbersome]]
#require 'apikey.ph'; 
# [[thats why we add home dir to @INC]]

use lib "$ENV{HOME}";
#require '.flickrrc'; 
#przeczytaj plik i pobierz co trzeba:
if( open CONFIG, "< $ENV{HOME}/.flickrrc" ) {
    while( <CONFIG> ) {
       chomp;
       s/#.*$//;       # strip comments

       next unless m/^\s*([a-z_]+)=(.+)\s*$/io;

       if( $1 eq "api_key" ) { $api_key = $2; }
       elsif( $1 eq "shared_secret" ) { $shared_secret = $2; }
     }
     close CONFIG;
}

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
  $ofname = $username; 
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

open (OFILE, ">$ofname"); 
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

if ($username) 
{ 
  # look up user ID if a username was provided 
  # 
  my $response = $api->execute_method('flickr.people.findByUsername', { 
                    username => $username} ); 
  die "Problem determining user_id: $response->{error_message}\n" if !$response->{success}; 
  print Dumper($response) if $verbose;  # explore results of call using -verbose 
  my $xm = $xmlp->XMLin($response->{_content});  
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

  my $xm = $xmlp->XMLin($response->{_content},forcearray=>['photo']); 

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
