#!/usr/bin/perl
#
# *** NO LONGER WORKS AS LOGIN PROCEDURE WAS CHANGEG at Flickr.com ***
# Get and store information on number of individual photo views at flickr.com
#
# usage: perl flick-store-views.pl
#
# This script login to www.flickr.com with $my_login/$my_passwd and downloads
# n photostream (main) pages from user's album, where each page URL follows
# the following pattern:
#
#     http://www.flickr.com/photos/<user_dir>/page<number>, <number> = 1,2,...n
#
# The pages are scanned for the information regarding page view counts (default
# photostream page layout is assumed). Next retrived information is put into
# the hash structured as follows:
#     $PhotoLog{date}{photoid}= views
# Next historic data on page views are retrived from $db_file (if it exists)
# and appended to '$PhotoLog'. Finally updated hash is stored into $db_file using
# store procedure from the Storable module.
# Read the comments below to get out how the scrip works and how (if needed)
# to adapt it.
#
# The scripts originates in http://coder.home.cosmic-cow.net/scripts/
# (copy can be found here: http://gnu.univ.gda.pl/~tomasz/prog/perl/scripts/mad-camel/)
# some more info on web scrapping:
# http://www.catonmat.net/blog/how-to-upload-youtube-videos-programmatically/
#
# (c) T.Przechlewski 11/2007 (tprzechlewski@acm.org)
# One can distribute/modify the file under the terms of the GNU General Public License.
#
# See also companion scripts: flick-report-views.pl and flick-graph-views.pl
# cf. http://gnu.univ.gda.pl/~tomasz/prog/perl/scripts/flickr/scripts/
#
use strict;

use HTTP::Request::Common;
use LWP::UserAgent;
use Storable;
#use LWP::Debug qw(+);
#
my $my_login="punio515"; # insert your login here (punio515 is mine)!
my $my_passwd ="M-W\@nda"; # insert your password here!
my $MyDir = 'http://www.flickr.com/photos/tprzechlewski' ;# main directory of your album
   # do not finish $MyDir with trailing slash, ie. 'http://www.flickr.com/photos/tprzechlewski'
   # _not_ 'http://www.flickr.com/photos/tprzechlewski/' (see. end of script to know why)
my $retry_after = 15 ; # wait 15 seconds before retry
my $MAX_PAGES = 999; # hard bound upper limit for downloads
   # maybe changed via command line arg--useful for testing (see below)
my $db_file = 'flick-views.log'; # filename to store data to
my $log_file = "flick-store-views.log" ; 
my $verbose = 1 ; # change to 0 to supress warnings
my $debug = 0 ; # change to 1 to enable extra output

my ($ua, $res, $challenge_, $u_, $done_, $pd_ );

my $max_pages = $ARGV[0] || $MAX_PAGES ;

my %Photos ;

# Create user agent, make it look like FireFox and store cookies
$ua = LWP::UserAgent->new;
$ua->agent("Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.7.12) Gecko/20051213 Firefox/1.0.7");
$ua->cookie_jar ( {} );

if ($my_passwd =~ /\?\?\?/) { die("*** ERROR: suspicious password ($my_passwd)!" )}
if ($debug) { print "*** Login/password *** $my_login $my_passwd\n" ; }

## Starting page URL
my $start_url = 'https://edit.europe.yahoo.com/config/login?.intl=us&.partner=&.last=&.src=flickr&.pd=c=E0.GahOp2e4MjkX.5l2HgAoLkpmyPvccpVM-&pkg=&stepid=i&&.done=https%3a//login.yahoo.com/config/validate%3f.src=flickr%26.pc=5134%26.scrumb=0%26.pd=c%253DE0.GahOp2e4MjkX.5l2HgAoLkpmyPvccpVM-%26.intl=us%26.done=http%253A%252F%252Fwww.flickr.com%252Fsignin%252Fyahoo%252F';

# Request login page
$res = $ua->request(GET "$start_url");
# Print beginning of $start_url on error
die("*** ERROR: GET " . substr($start_url, 0, 11)) unless ($res->is_success);

#
# Parse some values out of the login page. They are tricky.
# Perhaps some modifications are neccessary in the future: 
$challenge_ = $1 if ($res->content =~ /\.challenge\" value=\"(.+?)\"/);
$u_ = $1 if ($res->content =~ /\.u\" value=\"(.+?)\"/);
$done_ = $1 if ($res->content =~ /\.done\" value=\"(.+?)\"/);
$pd_ = $1 if ($res->content =~ /\.pd\" value=\"(.+?)\"/);

die("ERROR: No challenge\n") unless $challenge_;
die("ERROR: No U\n") unless $u_;
die("ERROR: No Done\n") unless $done_;
die("ERROR: No Pd\n") unless $pd_;

if ($debug) { print "*** $challenge_\n*** $u_\n*** $done_\n*** $pd_\n"; }

# Now we login with our user/pass, challenge and u (what is u anyway?)
# Whew their login process is verbose.
$res = $ua->request(
	POST "https://edit.europe.yahoo.com/config/login?",
	Referer => "$start_url",
	Content_Type => "application/x-www-form-urlencoded",
	Content => [ 
		'.tries'	=> "1",
		'.src'		=> "flickr",
		'.md5'		=> "",
		'.hash'		=> "",
		'.js'		=> "",
		'.last'		=> "",
		'promo'		=> "",
		'.intl'		=> "us",
		'.bypass'	=> "",
		'.partner'	=> "",
		'.u'		=> $u_,
		'.v'		=> "0",
		'.challenge'	=> $challenge_,
		'.yplus'	=> "",
		'.emailCode'	=> "",
		'pkg'		=> "",
		'stepid'	=> "",
		'.ev'		=> "",
		'hasMsgr'	=> "0",
		'chkP'		=> "Y",
		'.done'		=> "$done_",
		'.pd'		=> "$pd_",
		'login'		=> "$my_login",
		'passwd'	=> "$my_passwd",
                '.persistent'   => 'y',
		'.save'		=> "Sign+In"
	]
	);

if ($res->is_redirect()) { if ($debug) { print "**** Redirection ****" } }
else { die("ERROR: Login Failed\n") }

$res = $ua->request( GET $res->header("Location"),
       Referer => "$start_url",
      );

if ($debug) { print $res->content; }

my $next_href_ = $1 if ($res->content =~ /href=\"([^"]+?)\"/);
if ($debug) {  print $next_href_, "\n"; }

##
$res = $ua->request( GET "$next_href_",);
## $res = $ua->request( GET "$next_href_",);

## We should be log-in now, but an extra check maybe performed
## to download private photo--if suceed we are 110% sure:
## $res = $ua->request( GET "$MyDir/2030937511/" );# this is id of my private photo
## if ( $res->is_success ) { print $res->content ; }
## else { die " *** Problems logging to $my_login with $my_passwd *** " }
##

## Now scan all the photostream pages:
my $download_date = get_date();
my $MyDir = "$MyDir/page" ;
my ($i, $try );

## Testing mode:
## if ($max_pages < $MAX_PAGES) { warn "** Download max $max_pages ** " } ;

open (LOG, ">$log_file" ) || die " ** cannot open $log_file **";
print LOG "$download_date\n";

my $total_photos = 0; my $photostream_views = 0;

LAST:
for ($i = 1; $i<= $max_pages; $i++ ) {

   if ($verbose) { warn "$MyDir$i" ; }

   print LOG "$MyDir$i\n";

   for ($try = 0; $try < 3 ; $try++ ) {# try 3 times
     # http://www.perlmonks.org/?node_id=380264
     # LWP automatic redirect
     $ua->requests_redirectable( [GET] );
     # *** Termination condition ***
     # if redirect we pass through the last page (at least i hope it works)
     # it is vulnerable to modifications at flickr.com; 
     # perhaps better will be to add some funny and unique sentence to the 
     # last page and parse page's content
     $res = $ua->request( HEAD $MyDir . $i );
     if ($res->is_redirect()) { warn "** redirect: end of photostream **"; last LAST }

     $res = $ua->request( GET $MyDir . $i );

     if ( $res->is_success ) { last ; }
     else { 
       if ($try < 2 ) { sleep $retry_after; }
       else { die " ** problems downloading $MyDir$i, exit *** " ; }
     }

   }

   $total_photos += get_views( $res->content );

   if ($i == 1) {# looking for a photostream count:
     my $tmp_page = $res->content ;
     $tmp_page =~ m/<small>([0-9,]+)[ \t]+photos[ \t]+\/[ \t]+([0-9,]+)[ \t]+views<\/small>/;
     $photostream_views = $2;
   }
}

if ($verbose) { warn "$MyDir$i" ; }

print LOG "$photostream_views pagestream views\n";
print LOG "$total_photos photos downloaded\n";

close(LOG);

if ( $debug ) { for (keys %Photos) {  print " $_ = $Photos{$_} \n"; }}

# if $max_pages < $MAX_PAGES, test mode is assumed, 
# so exit before modyfying $db_file:
if ($max_pages < $MAX_PAGES) { exit ; }

##
## all info is collected, now read the log file, update, and write updated
## information back to disc file:

my %PhotoLog ;

if (-f "$db_file") { my $PhotoLogRef ;
   $PhotoLogRef = retrieve("$db_file") || die " *** ERROR: unable to retrieve from $db_file *** ";
   %PhotoLog = %{ $PhotoLogRef } ; 
   if ($debug ) { print " >> $db_file OK!\n"; }
} else { %PhotoLog = () ; }

$PhotoLog{$download_date} = \%Photos;

# write to disc:

store \%PhotoLog, "$db_file";

# to test scan the whole structure and print relevant info:
# test_print(\%PhotoLog);

if ($verbose) { warn "OK! Done..." ; }

## //////////////////////////////////////////////////////////////////////////////////////

## Extract info on view counts:
## ---------------------------
sub get_views {
   my $string = shift;
   my ($status, $photo, $views, $url, $pnum);
   my @Lines = split "\n", $string;
   my $line = 0 ;

   while ( $line <= $#Lines ) {

      $_ = $Lines[$line];

      if (/This photo is <b>([a-z]+)<\/b>/) { $status = $1 ; }

      if (/<p class="Activity">/) { # up to next 2 lines contains usage stats

         $photo = $Lines [ ++$line ] ; ## get next line

         if ($photo =~ /<b>([0-9]+)<\/b>[ \t]+view/ ) {# photo were viewed 
	   $views = $1;

	   $photo = $Lines [ ++$line ] ; ## get next line which contains comments and photo id
	   if ( $photo =~ m/href="([^"]+)"/ ) { $url = "$1"; } 
	   else { die (" *** ERROR : very strange: $photo *** "); }

         } else {# photos never viewed no need to read extra line 
	   if ( $photo =~ m/href="([^"]+)"/ ) { $url = "$1"; }
           else { die ("*** ERROR : very strange: $photo *** "); }

	   $views = 0;
         }

         ## only stats of public photos are aggregated:
         $url =~ /.*\/([^\/]+)/; $url = $1;

         if ($status eq "public") { $Photos{$url } = $views ; $pnum++ }
         else { #push @NPhotos, $url;
             # non-public photos are not counted -- you can change that
             ;
         }
      }

      $line++;

    }
   return $pnum; # no of photos found
}

## Get current date/time:
## ---------------------
sub get_date {# return date as: yyyymmddhhmm string
   my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime time;
   $year += 1900 ; $mon += 1;
   return ( sprintf "%4.4d%2.2d%2.2d%2.2d%2.2d", $year, $mon, $mday, $hour, $min );
}

## Iterate over whole data:
## -----------------------
sub test_print {
  my $PhotoLogRf = shift ; # reference to hash
   my ($date, $id );

  for $date (keys %{$PhotoLogRf} ) { print "-> $date \n";
    for $id ( keys %{$PhotoLog{$date}} ) {
       print "--->", $id, "->", ${$PhotoLog{$date}}{$id}, "\n";
    }
  }
}


## -- end --
