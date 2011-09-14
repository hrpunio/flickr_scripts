#!/usr/bin/perl
use Flickr::API;
use XML::Simple;

## (c) T.Przechlewski, tprzechlewski@acm.org, 2006.
## One can distribute/modify it under the terms of the GNU General Public License.
## Replace tags; for all pictures taken form $my_flickr_name.ph database (see script  flickr_getphotolist.pl)
## replace tags defined in 'tags2rep.xml' file (see below).
## Useful to make some order in ones' tags.
## The script expects _no_ parameters, so usage is simple:
##    perl flickr_repTags.pl
##  but one have $my_flickr_name.ph and 'tags2rep.xml' files properly prepared.
##
## Errors, if any, are written to 'tags2rem.log' file.
## Links to photos along with changes made, in HTML format, are written to 'tags2rem.html', so you can
## easily check visually if changes are in sync with what are expected.
## -----------------------------------------------------------------------------------------------------------
## Tags 
## http://www.flickr.com/services/api/misc.tags.html
## A photo can have zero or more tags. Each tag has a bunch of fields returned for your use:
##
## <tag id="1234" author="12037949754@N01" raw="woo yay">wooyay</tag>
## raw	The 'raw' version of the tag - as entered by the user. This version can contain spaces and punctuation.
## id	The unique id for this tag on this photo. This can be used 
##      when deleting a single tags using the flickr.photos.removeTag method.
use bytes;

require 'login2flickr.rc';

open (LOGFILE, ">tags2rem.log");
open (TOCFILE, ">tags2rem.html");
print TOCFILE "<html>\n"; 

my @tgs =();
my %tags2rep;

my $photolist = "$FLICKRCFG/$my_flickr_name.ph";
require "$photolist";

get_tags_to_rep_base ("tags2rep.xml");
## for debug print:
##for $t (keys %tags2rep) { print "[", $t, "=>", $tags2rep{$t}, "] ";}

my $api = new Flickr::API({'key' => $api_key, 'secret' => $shared_secret } );

foreach $photo (@photos) {
    $pid = $photo->{id};
    print "-> $pid<--\n";
    print LOGFILE "-> $pid<--\n";

    print TOCFILE "<a href=\"http://www.flickr.com/photos/tprzechlewski/$pid\">$pid ";

    ## --get the tags, ie. pointer to list of hashes is returned--
    $tgs = flickr_get_tags($api, $pid, $my_flickr_id);

    foreach $tx (@{$tgs}) {
       ## debug:
       ## printf ("?? %s : %s : %s\n", $tx->{raw}, $tx->{id}, $tx->{content} );
       $rtx = $tx->{raw}; 

       for $ty (keys %tags2rep) {
        $ltt = lc($ty);

        if ( lc($rtx) eq $ltt ) { 
         printf ("?? Wymiana :: %s => %s\n", $rtx, $tags2rep{$ty});
         print TOCFILE "[$rtx->$tags2rep{$ty}]";

         ## -- remove tag `tx' --------------
         $status = flickr_rem_tag($api, $tx->{id}); ## api + id_taga
         if ($status ne "OK") { print "** Problem removing: $rtx na $tags2rep{$ty} [$status]!\n"; 
            print LOGFILE "** Problem removing: $rtx na $tags2rep{$ty} [$status]!\n";
          }
         ## -- insert tag `$tag2rep{$ty}' for photo which id is `$pid' --
         $status = flickr_set_tag($api, $pid, "\"$tags2rep{$ty}\"" );
         if ($status ne "OK") { print "** Problem setting: $tag2rep{$ty} [$status]!\n"; 
             print LOGFILE "** Problem setting: $tag2rep{$ty} [$status]!\n";
          }


        }
       }
    }

    $ii++; 

    print TOCFILE "</a></p>\n";

    # some debugging tests 
    # if ($ii >100) { last }
    if ($ii % 100 == 0 ) { print "*** $ii pictures processed ....\n" }

  }

print TOCFILE "</html>\n"; close(TOCFILE);
close(LOGFILE);

#==================================================================
sub flickr_set_tag {
   ## Add tags to a photo, 
   ## Usage: flickr_set_tag(flickr, photoid, tags)
   ## where `flickr' = pointer to flickr object created with new Flickr::API(...);
   ##  photoid = id of the photo to which add the tags;
   ##  tags = single tag;
   #
   my $flickr = shift; # pointer to flickr object created with new Flickr::API(...)
   my $photo_id = shift; # details of the photo (pointer to hash)
   my $tags = shift; # taglist zamieniæ na utf

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
# flickr.photos.removeTag
# Arguments: api_key (Required) + tag_id (Required)
sub flickr_rem_tag {
   my $flickr = shift; # pointer to flickr object created with new Flickr::API(...)
   my $tagid = shift; # id of the tag to remove

   ## http://www.flickr.com/services/api/flickr.photos.removeTag.html
   my $response = $flickr->execute_method('flickr.photos.removeTag',
   { auth_token  => $auth_token, tag_id => $tagid, });

   if ( !$response->{success} ) { #warn "Problem: $response->{error_message}\n"
      return "$response->{error_code}"; } # take care of the error in the main prog.
   else { return 'OK'}
}

#==================================================================
sub flickr_get_tags {
  ## return list of tags for given $photo_id, optional $who argument determines
  ## whose tags are returned
  #
  my $flickr = shift; # pointer to flickr object created with new Flickr::API(...)
  my $photo_id = shift; # id of the photo
  my $who = shift; # id of the photo owner
  my $t;
  my $xmlp = new XML::Simple ( );

  ## http://www.flickr.com/services/api/flickr.tags.getListPhoto
  my $response = $flickr->execute_method('flickr.tags.getListPhoto',
    { photo_id  => $photo_id, } );

  die "Problem: $response->{error_message}\n" if !$response->{success};

  my $xm = $xmlp->XMLin($response->{_content}, keyattr =>[], forcearray=>[tag]);

  my $tagList = $xm->{photo}->{tags}->{tag};

  ## debug
  ##foreach $t (@{$tagList}) { printf ("?? %s : %s : %s\n", $t->{raw}, $t->{id}, $t->{content} ); }
  return  $tagList ; # pointer to list of hashes  ##

}

#==================================================================

sub get_tags_to_rep_base {
   my $base_name = shift;
   my $base = new XML::Simple ( );
   my $bb = $base->XMLin($base_name, keyattr => {}, forcearray=>[]);

   my $tagList = $bb->{tag};
   # construct tags2rep (global) hash:
   foreach $t (@{$tagList}) { $tags2rep{$t->{bad}} = $t->{good};  }
}

#==================================================================
# -- end --
