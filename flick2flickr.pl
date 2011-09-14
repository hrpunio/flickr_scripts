#!/usr/bin/perl
print "#!/bin/bash\n";

while ( <> ) {
 if (/^[ \t]*#/) { next } # skip comments
 s/^/flickr_upld -f /;
 s/=>//;
 print $_;
}
