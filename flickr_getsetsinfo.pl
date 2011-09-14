#!/usr/bin/perl -s 
#
# Get info on photosets stored locally
use XML::Simple;
use Data::Dumper;
$Data::Dumper::Terse = 1;  # avoids $VAR1 = * ; in dumper output 
$Data::Dumper::Indent = $verbose? 1 : 0;  # more concise output

require 'login2flickr.rc';

$sets_info="$ENV{HOME}/.flickr/$my_flickr_name.sets"; # my flickr directory

$xmlp = new XML::Simple ();

my $xm = $xmlp->XMLin($sets_info, keyattr =>[]);
my $psl = $xm->{photoset};

foreach $s (@{$psl}) {
    print "Set # $s->{local_id} id: $s->{id} title: $s->{title} [$s->{photos}]\n";
    $set_id{$s->{local_id}}=$s->{id};
}

# other data concerning photosets
# photos => '',
# primary => '',
# title => '',
# secret => '',
# id => '',
# server => '',
# description => ''
