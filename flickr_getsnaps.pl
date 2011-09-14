#!/usr/bin/perl -s 
#
# Hack #34: grab tagged photos and put small thumbnails into a named folder 
# getSnaps.pl - Jim Bumgardner 
#  
# use -med option for medium-sized photos 
use LWP::Simple; 
$photolist = shift; 
$dirname = shift; 
$dir_prefix="$ENV{HOME}/.flickr"; # my flickr directory

die "getSnaps.pl [-big] <photolist_file> [dirname]\n" if !$photolist; 

$dirname = $photolist if !$dirname; 
$dirname =~ s/\.ph// if $dirname =~ /\.ph$/; 
$dirname = "$dir_prefix/$dirname"; # --tp--

$photolist .= '.ph' if !($photolist =~ /\./); 

require "$photolist"; 

$nbrAdded = 0; 
if (!(-e $dirname)) 
{ 
    print "Making directory $dirname\n"; 
    `mkdir $dirname`; 
} 

$suffix = $big? '' : '_t'; 

foreach $photo (@photos) 
{ 
    $purlt = sprintf "http://static.flickr.com/%d/%d_%s%s.jpg",  
                $photo->{server},$photo->{id}, $photo->{secret}, $suffix; 
    $fnam = "$dirname/$photo->{id}$suffix.jpg"; 
    $hasSmall = 0; 
    print "Checking $fnam...\n" if $verbose; 
    # printf "Checking $fnam...\n"; 
    if (!(-e $fnam))  
    { 
      print "Adding $fnam...\n"; 
        foreach (0..5) 
        { 
            $pimg = get $purlt; 
            last if $pimg; 
            print "Retry...\n"; 
            sleep 1; 
        } 
        die "Couldn't get image $purlt\n" if !$pimg; 
        open (OFILE, ">$fnam") || die ("can't open $fnam\n"); 
        binmode OFILE; 
        print OFILE $pimg; 
        close OFILE; 
        print "$nbrAdded...\n" if ++$nbrAdded % 50 == 0; 
    } 
} 

print "$nbrAdded added\n";
