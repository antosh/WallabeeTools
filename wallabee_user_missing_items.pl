#!/usr/bin/perl

#Show the items a user is missing by set.

use JSON -support_by_pp;
use Getopt::Long;
use strict;

our $APIKEY = "";
our %OPT = (
        user => undef(),
       );
our @allsets;
our @mymissing;

my $json = new JSON;

unless(GetOptions(\%OPT,"user=s") && (scalar(@ARGV) == 0)){
  exit(1);
}

#Make sure a name or id was provided
$OPT{user} or print "--user <name> or <id> not provided\n" and exit 1;

#get the users sets
my $wallabeesets = `curl -s -H X-WallaBee-API-Key:$APIKEY http://api.wallab.ee/users/$OPT{user}/sets`;
my $json_sets = $json->allow_nonref->utf8->relaxed->escape_slash->loose->allow_singlequote->allow_barekey->decode($wallabeesets);

#loop thru the sets and add the ID to an array.  Skip completed sets.
foreach my $sets(@{$json_sets->{sets}}){
  push @allsets, $sets->{id} unless $sets->{completed} eq "true";
}

#Loop thru each set and get the items skip the item if the user has one.
#Add the missing items to an array 
foreach my $usersets(@allsets){
  my $mysets = `curl -s -H X-WallaBee-API-Key:$APIKEY http://api.wallab.ee/users/$OPT{user}/sets/$usersets`;
  my $json_usersets = $json->allow_nonref->utf8->relaxed->escape_slash->loose->allow_singlequote->allow_barekey->decode($mysets);
  foreach my $items(@{$json_usersets->{items}}){
    next if $items->{item_id};
    push @mymissing, $items->{item_type_id}; 
  }
}

#loop thru the missing items and print the id, name and cost.
#If the item is created by mixing, show what items are needed to make it.
#List the categories the item is found at. 
foreach my $missitem(@mymissing){
  my $missitem = `curl -s -H X-WallaBee-API-Key:$APIKEY http://api.wallab.ee/itemtypes/$missitem`;
  my $json_miss = $json->allow_nonref->utf8->relaxed->escape_slash->loose->allow_singlequote->allow_barekey->decode($missitem);
  next if($json_miss->{name} eq "?");
  print "Missing: $json_miss->{item_type_id} $json_miss->{name} \$$json_miss->{store_cost}\n";
  foreach my $i (@{$json_miss->{mix}}){
    GetItem($i);
  }
  foreach my $i (@{$json_miss->{categories}}){
    GetCate($i);
  }
}

#Function to return categories
sub GetCate($){
  my $id = shift;
  my $misscate = `curl -s -H X-WallaBee-API-Key:$APIKEY http://api.wallab.ee/placecategories/$id`;
  my $json_miss = $json->allow_nonref->utf8->relaxed->escape_slash->loose->allow_singlequote->allow_barekey->decode($misscate);
  print "      Found At: $id $json_miss->{name}\n";
}

#Function to get item info used when an item is created by mixing.
#Also get the categories for the item.
sub GetItem($){
  my $id = shift;
  my $missitem = `curl -s -H X-WallaBee-API-Key:$APIKEY http://api.wallab.ee/itemtypes/$id`;
  my $json_miss = $json->allow_nonref->utf8->relaxed->escape_slash->loose->allow_singlequote->allow_barekey->decode($missitem);
  print "    Mix: $id $json_miss->{name} \$$json_miss->{store_cost}\n";
  foreach my $i (@{$json_miss->{categories}}){
    GetCate($i);
  } 
}
