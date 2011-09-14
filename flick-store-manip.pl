#!/usr/bin/perl
use strict;
use Getopt::Long;
use Storable;
#
# Check database
#
my ($download_date, $status, $photo, $views, $url, $raw_file, 
   $xml2bin, $bin2xml, $removedate, $listdates ) ;
my %PhotoLog;
my $log_file = "flick-views.log" ;
my $xml_file = "flick-views.xml" ;

GetOptions( 'xml2bin'  => \$xml2bin,
            'bin2xml'  => \$bin2xml,
	    'remove=s' => \$removedate,
	    'list'     => \$listdates, ) ;

print "Usage: flick-store-manip.pl [ --xml2bin | --bin2xml --remove=date | --list]\n";


if ( $xml2bin ) { xml2hash()  }
else {
  open_log_file();

  if ( $listdates ) { list_dates(\%PhotoLog); }
  elsif ($removedate ) { remove_date(\%PhotoLog, $removedate); }
  elsif ($bin2xml ) { hash2xml(\%PhotoLog); }
}

### -------------------------------------------

sub list_dates {
  my $PhotoLogRf = shift ; # reference to hash

  my @pp ; print "Date +++++++ => #Photos\n";

  my @Dates = reverse (sort (keys %{$PhotoLogRf} ));

   for (@Dates) { @pp = keys %{$PhotoLog{$_}} ;

     print "$_ => ", $#pp + 1, "\n";
   ; }
}

### -------------------------------------------

sub remove_date {
  my $PhotoLogRf = shift ; # reference to hash
  my $remdate = shift ;
  my $date ;

  my @Dates = reverse (sort (keys %{$PhotoLogRf} ));

  for $date (@Dates) { 
    #http://www.cs.mcgill.ca/~abatko/computers/programming/perl/howto/hash/
    if ($date =~ /$remdate/) {
      delete $PhotoLogRf->{$date};
      warn " *** Deleting $remdate *** ";
    }
  }
  store \%PhotoLog, "$log_file" || die " ** Problem storing ** ";

}

### -------------------------------------------

sub hash2xml {
  my $PhotoLogRf = shift ; # reference to hash
  my ($date, $id );
  my %ids ;

  open XML, ">$xml_file" || die "*** Cannot open $xml_file";

  print XML "<?xml version='1.0' ?>\n";

  print XML "<album>\n";
  for $date (sort keys %{$PhotoLogRf} ) {
    print XML "<date ='$date'>\n";
    for $id ( keys %{$PhotoLog{$date}} ) {
      print XML "<photo id='$id' v='${$PhotoLog{$date}}{$id}'/>\n";
       $ids{$id} = 1;
    }
    print XML "</date>";
  }

  print XML "</album>\n";

  my @pp = keys %ids ; my $qq = $#pp +1 ;

  warn "** $qq photos stored in $xml_file ** ";

}

### -------------------------------------------

sub xml2hash {
  my %PhotoLog ; # reference to hash
  my ($date, $id, $v, $tph);

  open XML, "$xml_file" || die "*** Cannot open $xml_file";

  # it is very simple XML so all we need are regexps to parse it:
  for (<XML>) {
    if (/date ='([^']+)'/) { $date = $1; }
    elsif (/photo id='([^']+)' v='([^']+)'/) { $id =$1 ; $v = $2 ; $tph++ }
    else { next }

    $PhotoLog{$date}{$id} = $v ;
  }

  store \%PhotoLog, "$log_file" || die " ** Problem storing $log_file ** ";
  warn "** $tph photos stored in $log_file ** ";

}

## ------------------------------------------------

sub open_log_file {

  if (-f "$log_file") { 
    my $PhotoLogRef ;
    $PhotoLogRef = retrieve("$log_file") || die " *** ERROR: unable to retrieve from $log_file *** ";
    %PhotoLog = %{ $PhotoLogRef } ;
  } else { %PhotoLog = () ; }

}
