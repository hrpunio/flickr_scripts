#!/usr/bin/perl
# Get tags from flickr for single photo, print them using ISO-8859-2
#
# Usage: flickr_getTags [-u userid] -p photoid [-a]
#   -u userid = specifies photo owner (default: use $my_flickr_id)
#   -a        = print all tags (default: only tags defined by its owner)
#   -p        = photo id [mandatory argument]
#
# Example: perl flickr_getTags.pl -p 251361861 gets tags for 251361861
#
use Flickr::API;
use XML::Simple;
use Data::Dumper;
use Encode;
use Getopt::Long;

GetOptions("reversemode" => \$reversemode,
	   "help=s" => \$show_help,
	   "photo=s" => \$photo_id,
           "user=s" =>  \$user_id);
# je¿eli jest user_ID nadpisz domy¶lny
# ustal ID u¿ytkownika i tryb pracy (niedokoñczone)
if ($user_id) { $my_flickr_id = $user_id; $current_mode='m'; }

if (! $photo_id) { print $usage ; die;   }
if ( $reversemode ) { $current_mode = '-'; } 

$xmlp = new XML::Simple ( );

# login2flickr.rc contains authentication stuff, namely it
# defines appropriate values to: $api_key, $shared_secret, $auth_token
# and $my_flickr_id:
require 'login2flickr.rc';

my $api = new Flickr::API({'key' => $api_key,
              'secret' => $shared_secret } );


my @myTags = ();
my @otherTags = ();

@myTags= gettags ($api, $photo_id, $my_flickr_id);
@otherTags= gettags ($api, $photo_id, "-$my_flickr_id");

print "My tags: @myTags\n";
print "Theirs tags: @otherTags\n";


#====================================================
sub gettags {
  # return list of tags for given $photo_id, optional $who argument determines
  # whose tags are returned: if valid user_id is passed, only tags defined by this user
  # will be returned, precede user_id with minus sign to get all tags defined not
  # by this particular user, if $who is not set all tags will be returned (default)
  #
  my $flickr = shift; # pointer to flickr object created with new Flickr::API(...)
  my $photo_id = shift; # id of the photo
  my $who = shift; # id of the photo owner (optional)

  my $debugmode = 0;
  my @list_of_tags = ();
  my $mode; # 
  my $t;

  # set the mode to: '*', '-', or 'm'
  if (! $who ) {# $who not set, get all tags
     $mode = '*'; }
  elsif ($who =~ /^\-/) {# $who set to some ID with preceding '-'
     $mode = '-'; $who =~ s/^\-//;
  } else { $mode = 'm'; }

  print ("who: $who; mode: $mode; photo: $photo_id;\n") if $debugmode;

  ## http://www.flickr.com/services/api/flickr.tags.getListPhoto
  my $response = $flickr->execute_method('flickr.tags.getListPhoto',
    { photo_id  => $photo_id, } );

  die "Problem: $response->{error_message}\n" if !$response->{success};

  my $xm = $xmlp->XMLin($response->{_content}, forcearray=>['tag']);

  my $tagList = $xm->{photo}->{tags}->{tag};

  foreach $t (keys %{$tagList}) {
     my $tag = $tagList->{$t};
     print ($t, " : ", $tag->{raw}, " : ", $tag->{author}, "\n") if $debugmode;

     if ($mode eq 'm') {
        if ($tag->{author} eq $who ) {
           push @list_of_tags, utf2ascii($tag->{raw}); } 
     } elsif ( $mode eq '-') {
        if (! $tag->{author} eq $who ) {
           push @list_of_tags, utf2ascii($tag->{raw}); } 
     }
     else { push @list_of_tags, utf2ascii($tag->{raw}); } 
  }

  return @list_of_tags;

}


#====================================================
sub utf2ascii {
 my $text = shift;
 $text = encode("iso-8859-2", $text);
 return $text;
}
