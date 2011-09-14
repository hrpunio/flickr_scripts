#!/usr/bin/perl
#
# *** NO LONGER WORKS AS LOGIN PROCEDURE WAS CHANGEG at Flickr.com ***
#
# This script login to www.flickr.com with $my_login/$my_passwd and downloads
# n pages from user's album, where each page URL follows the following pattern:
#
#     http://www.flickr.com/photos/<user_dir>/page<number>, <number> = 1,2,...n
#
# Each page contains photos thumbnails, number of views, comments etc...
#
# [Example usage] Obtaining information on view counts of individual photos (it is
# impossible to extract this information via flickr API, at least as of Nov. 2007):
#
#   perl flick-total-views.pl > _log-file_
#
# In result _log-file_ will contain all (main) HTML pages from flickr.  The companion scripts 
# flick-aggr-totals.pl or flick-xaggr-totals.pl can be used to aggregate information concerning 
# the photo _views_. Another script flick-zaggr-totals.pl stores photos views statistics
# in disc file using compact format (with Storable).
#
# The scripts originates in http://coder.home.cosmic-cow.net/scripts/
# (copy can be found here: http://gnu.univ.gda.pl/~tomasz/prog/perl/scripts/mad-camel/)
# some more info on web scrapping:
# http://www.catonmat.net/blog/how-to-upload-youtube-videos-programmatically/
#
# (c) T.Przechlewski 11/2007 (tprzechlewski@acm.org)
# One can distribute/modify the file under the terms of the GNU General Public License.
#
# cf. http://gnu.univ.gda.pl/~tomasz/prog/perl/scripts/flickr/scripts/
#
use strict;

use HTTP::Request::Common;
use LWP::UserAgent;
#use LWP::Debug qw(+);

my $my_login="punio515"; # insert your login here (punio515 is mine)!
my $my_passwd ="????????"; # insert your password here!
my $MyDir = 'http://www.flickr.com/photos/tprzechlewski' ;# main directory of your album
   # do not finish $MyDir with trailing slash, ie. 'http://www.flickr.com/photos/tprzechlewski'
   # _not_ 'http://www.flickr.com/photos/tprzechlewski/' (see. end of script to know why)
my $retry_after = 15 ; # wait 15 seconds before retry
#
my $max_pages = 999; # hard bound upper limit for downloads 

my ($ua, $res, $challenge_, $u_, $done_, $pd_, $debug );

# Create user agent, make it look like FireFox and store cookies
$ua = LWP::UserAgent->new;
$ua->agent("Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.7.12) Gecko/20051213 Firefox/1.0.7");
$ua->cookie_jar ( {} );

if ($my_passwd =~ /\?\?\?/) { die("*** ERROR: suspicious password ($my_passwd)!" )}
if ($debug) { print "*** Login/password *** $my_login $my_passwd\n" ; }

my $start_url = 'https://edit.europe.yahoo.com/config/login?.intl=us&.partner=&.last=&.src=flickr&.pd=c=E0.GahOp2e4MjkX.5l2HgAoLkpmyPvccpVM-&pkg=&stepid=i&&.done=https%3a//login.yahoo.com/config/validate%3f.src=flickr%26.pc=5134%26.scrumb=0%26.pd=c%253DE0.GahOp2e4MjkX.5l2HgAoLkpmyPvccpVM-%26.intl=us%26.done=http%253A%252F%252Fwww.flickr.com%252Fsignin%252Fyahoo%252F';

# Request login page
$res = $ua->request(GET "$start_url");
# Print beginning of $start_url on error
die("*** ERROR: GET " . substr($start_url, 0, 11)) unless ($res->is_success);

#
# Parse some values out of the login page. They are tricky.
# Perhaps some modifications are neccessary 
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
# Whew their login process is verbose. That "chkP" var makes me wonder..
# if it were set to N would it let me login to any account without
# a password? Yikes.
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

$res = $ua->request( GET "$next_href_",);

$res = $ua->request( GET "$next_href_",);

## Now scan all my pages:
my $MyDir = "$MyDir/page" ;
my ($i, $try);

##$max_pages = 164;

LAST: 
for ($i = 1; $i<= $max_pages; $i++ ) {
   warn $MyDir . $i ;

   for ($try = 0; $try < 3 ; $try++ ) {# try 3 times
     # http://www.perlmonks.org/?node_id=380264
     # LWP automatic redirect
     $ua->requests_redirectable( [GET] );
     $res = $ua->request( HEAD $MyDir . $i );
     # if redirect we pass through the last page (at least i hope it works)
     if ($res->is_redirect()) { warn "** redirect **"; last LAST }

     $res = $ua->request( GET $MyDir . $i );

     if ( $res->is_success ) { warn "OK!"; last ; }
     else { sleep $retry_after; }
   }

   print "<!-- $MyDir$i -->\n";   
   print $res->content;
}

my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime time;
$year += 1900 ; $mon += 1;
my $today = sprintf "%4.4d%2.2d%2.2d%2.2d%2.2d", $year, $mon, $mday, $hour, $min;

print "\n<!-- [[DOWNLOADATE: $today ]] -->\n";

## -- end --
