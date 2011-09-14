#!/usr/bin/perl
## skrypt zamieniajacy baze w formacie XML na odpowiednie listy Emacsa (zeby bylo szybciej)
##
use XML::Simple;
## W pierwszej wersji dokonywana byla konwersja na iso88592. Od 20110815: konwersje zapewni Emacs
## use Text::Iconv;
use Getopt::Long;
use Data::Dumper;
binmode DATA, ":utf8";
### zmiana 06/2008

my $USAGE = "\n";
my ($idno, $i);

my $tags_base = "$ENV{HOME}/.flickr/hr.icio.tags";
my $sets_base = "$ENV{HOME}/.flickr/hr.icio.sets";
my $groups_base = "$ENV{HOME}/.flickr/hr.icio.groups";
my $geo_base = "$ENV{HOME}/.flickr/knows/where.flk";

##$conv = Text::Iconv->new("iso-8859-2", "UTF-8");
##$vnoc = Text::Iconv->new("UTF-8", "iso-8859-2");

print ";; -*- coding: utf-8 -*-\n";
print ";; generated file :: do not edit!\n";

# Geocorrdinates
# Nazwy geograficzne
my %gc = get_geonames(); $idno = 0;
print "(setq glist '(\n";
for $i (keys %gc ) { print '("', $i, "\" $idno)\n"; $idno++ }
print "))\n\n";

# Nazwy zbiorów (bez konwersji)
print "(setq slist '(\n";
my %sc = get_setsids(); $idno = 0;
for $i (sort keys %sc ) { print '("', $i, "\" $idno)\n"; $idno++ }
print "))\n\n";

# Nazwy tagow (konieczna konwersja utf->iso
print "(setq tlist '(\n";
my %tc = get_tags(); $idno = 0;
for $i (keys %tc ) { print '("', $i, "\" $idno)\n"; $idno++ }
print "))\n\n";

# Nazwy puli (pools, bez konwersji)
print "(setq plist '(\n";
my %pc = get_groups(); $idno = 0;
for $i (sort keys %pc ) { print '("', $i, "\" $idno)\n"; $idno++ }
print "))\n\n";

###########################################################################
sub xconvert {
  my $string = shift;
  return ( $string ); ## za¶lepka
}

sub get_groups {
   my %grp_ids;
   $xmlp = new XML::Simple ();
   my $xm = $xmlp->XMLin($groups_base, keyattr =>[]);
   my $psl = $xm->{group};

   foreach $s (@{$psl}) {
    $grp_ids{lc($s->{name}) . "@" . $s->{local_id} } = $s->{id};
   }
   return %grp_ids;
}

###
sub get_setsids {
   my %set_ids;
   $xmlp = new XML::Simple ();
   my $xm = $xmlp->XMLin($sets_base, keyattr =>[]);
   my $psl = $xm->{photoset};

   foreach $s (@{$psl}) {
    #print "Set # $s->{local_id} id: $s->{id} title: $s->{title} [$s->{photos}]\n";
    $set_ids{lc($s->{title}) . "@" . $s->{local_id} } = $s->{id};
   }
   return %set_ids;
}
###
sub get_tags {
   my %tags;

   my $tbase = new XML::Simple ( );

   my $tb = $tbase->XMLin($tags_base, keyattr => 'tags');
   ##print Dumper($tb);

   my $List = $tb->{tag};
   my $t;
   foreach $t ( @{$List} ) { unless ($t =~ /^HASH/ ) { $tags{ $t } = 1; ; }}
   return %tags ;
}

###
sub get_geonames {
   my $lbase = new XML::Simple ( );

   my $lb = $lbase->XMLin($geo_base,
     keyattr => { wpt => 'identifier' }, forcearray=>['wpt']);

   my $wptList = $lb->{wpt};

   foreach $l (keys %{$wptList}) {
     my $loc = $wptList->{$l};
     if (! $loc->{acc} ) { $loc->{acc} = -1 }
     ##print $l, " => ", $loc->{lat}, " x ", $loc->{lon}, "\n"; ##
     $gc{ $l } = [$loc->{lat}, $loc->{lon}, $loc->{acc} ];
   }
   return %gc ;
}


