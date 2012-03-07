#!/usr/bin/perl

#$Id: wallabee_mix.pl,v 1.6 2012/03/07 04:00:23 antosh Exp $
#$Author: antosh $

use strict;
use JSON -support_by_pp;

#Enter your API key here
our $APIKEY = "";

my $json = new JSON;

our (@allsets, %itemhash, %catehash);

#Get all the sets
my $wallabeesets = `curl -s -H X-WallaBee-API-Key:$APIKEY http://api.wallab.ee/sets`;
my $json_sets = $json->allow_nonref->utf8->relaxed->escape_slash->loose->allow_singlequote->allow_barekey->decode($wallabeesets);

#Build an array of the set ids
foreach my $sets(@{$json_sets->{sets}}){
  push @allsets, $sets->{id};
}

#Query each set id.  Print the name of the set.
#Loop through each item and print it's name.  I skip items named ?
#If the item is created by mixing, loop though each mix item id and get that items name.
foreach my $setid(@allsets){
  my $thisset = `curl -s -H X-WallaBee-API-Key:$APIKEY http://api.wallab.ee/sets/$setid`;
  my $json_thisset = $json->allow_nonref->utf8->relaxed->escape_slash->loose->allow_singlequote->allow_barekey->decode($thisset);
  print "Set: $json_thisset->{name}\n";
  foreach my $items(@{$json_thisset->{items}}){
    next if $items->{name} eq "?";
    if ($items->{store_cost}){
      print "  Item: $items->{name}, Price: \$$items->{store_cost}\n";
    }else{
      print "  Item: $items->{name}\n";
    }
    foreach my $cate (@{$items->{categories}}){
      print "   Place: ", GetCate($cate), "\n";
    }
    foreach my $i (@{$items->{mix}}){
      print "    Mix: ", GetItem($i), "\n";
    }
  }
}

#Look up an item given it's ID.
#Add the id and name to a hash so we only look up each item once.
#Return the item name.
sub GetItem($){
  my $id = shift;
  return ($itemhash{$id}) if $itemhash{$id};
  my $mixitem = `curl -s -H X-WallaBee-API-Key:$APIKEY http://api.wallab.ee/itemtypes/$id`;
  my $json_mix = $json->allow_nonref->utf8->relaxed->escape_slash->loose->allow_singlequote->allow_barekey->decode($mixitem);
  $itemhash{$id} = $json_mix->{name};
  return($json_mix->{name});
}

#Get the Categories given the ID.
#Add the id and name to a hash so we only look up each one once.
#Return the name.
sub GetCate($){
  my $id = shift;
  return ($catehash{$id}) if $catehash{$id};
  #sleep 1;
  my $misscate = `curl -s -H X-WallaBee-API-Key:$APIKEY http://api.wallab.ee/placecategories/$id`;
  my $json_cate = $json->allow_nonref->utf8->relaxed->escape_slash->loose->allow_singlequote->allow_barekey->decode($misscate);
  $catehash{$id} = $json_cate->{name};
  return($json_cate->{name});
}
