#!/usr/bin/perl 
#
use strict;

use XML::LibXML;
use LWP::Simple;
use Data::Dumper;

require 'login2flickr.rc';

our $api_key;
my $numc = 0;
my $verbose = 0 ;

my $xml;
my $photo_id = '';
my $owner_id = '';
my $photo_title = '';
my ($n, $t);
my $method = '';
my $flickr_url = '';
my $resp;

my $infile = $ARGV[0];

## Construct a node with text `Probably deleted!':
my $deleted_text = XML::LibXML::Text->new( 'Probably deleted!' );
my $ele_deleted = XML::LibXML::Element->new('TP_deleted');
$ele_deleted->addChild($deleted_text);

## ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
## input file contains <photo elemens
##
my $parser = XML::LibXML->new;

my $doc = $parser->parse_string($xml);

my @elems = $doc->getElementsByTagName('photo' ) ;

if ($verbose > -1 ) { print STDERR "$infile :: $#elems\n"; }

for $n ( @elems ) {

      $photo_id = $n->getAttribute( 'id' );
      $owner_id = $n->getAttribute( 'owner' );
      $photo_title = $n->getAttribute( 'title' );

      if ($verbose > -1 ) { print STDERR " $infile :: $numc/$#elems :: ID : $photo_id ; Own : $owner_id ; Title : $photo_title\n"; }

      ## Get tags ::
      $method = 'flickr.tags.getListPhoto';
      $resp = query_flickr( "method=$method&api_key=$api_key&photo_id=$photo_id" );

      ## check if photo is not deleted _in the_ meantime
      unless (check_flickr_resp($resp) eq 'ok') { 
	$ele_deleted = $n->appendChild( $ele_deleted );
	if ($verbose > -1 ) { print STDERR "   ID = $photo_id probably deleted...\n"; }
	next ; ## photo probably deleted do not process further!!!
      }

      my $doc = $parser->parse_string($resp);
      if ( my @tags = $doc->getElementsByTagName('tags' ) ) {
	for $t (@tags ) { $t = $n->appendChild( $t ); }
      }

      ## Get Pools and sets :: ;;;;;;;;;;;
      $method = 'flickr.photos.getAllContexts';
      $resp = query_flickr( "method=$method&api_key=$api_key&photo_id=$photo_id" );
      my $doc = $parser->parse_string($resp);

      if ( my @pools = $doc->getElementsByTagName('pool' ) ) {
	my $new_pools = XML::LibXML::Element->new('pools');
	$new_pools = $n->appendChild( $new_pools );
	for $t (@pools ) { $t = $new_pools->appendChild( $t ); }
      }

      if ( my @sets = $doc->getElementsByTagName('set' ) ) {
	my $new_sets = XML::LibXML::Element->new('sets');
	$new_sets = $n->appendChild( $new_sets );
	for $t (@sets ) { $t = $new_sets->appendChild( $t ); }
      }

      ## Get Geo locations :: ;;;;;;;;;
      $method = 'flickr.photos.geo.getLocation';
      $resp = query_flickr( "method=$method&api_key=$api_key&photo_id=$photo_id" );
      my $doc = $parser->parse_string($resp);
      if (my @locations = $doc->getElementsByTagName('location' ) ) {
	for $t (@locations ) { $t = $n->appendChild( $t ); }
      }

      ##if ($numc > 3 ) { last }; ## one iteration
      ##
      $numc++;
      print STDERR ".";

   }



##  ======================================================================================================
sub query_flickr {
  my $url =  shift ; ## np.  "http://www.flickr.com/services/rest/?method=$method&api_key=$api_key&photo_id=$photo_id";
  return ( get ( "http://www.flickr.com/services/rest/?" . $url ) ); ## resp is an XML file
}

sub check_flickr_resp {
  my $resp = shift ;
  my $doc = $parser->parse_string($resp);
  if ( my $root = $doc->getElementsByTagName('rsp' )->[0] ) {
    return ( $root->getAttribute( 'stat' ) ); }
}

###
#<?xml version="1.0" encoding="utf-8" ?>
#<rsp stat="fail">
#        <err code="1" msg="Photo not found" />
#</rsp>
