#!/usr/bin/perl
use JSON -support_by_pp;

my $json = new JSON;
my $APIKEY = "";
$storeitems = `curl -s -H X-WallaBee-API-Key:$APIKEY http://api.wallab.ee/storeitems`;
my $json_store = $json->allow_nonref->utf8->relaxed->escape_slash->loose->allow_singlequote->allow_barekey->decode($storeitems);
foreach my $store(@{$json_store->{items}}){
  print "$store->{store_timings}{end} $store->{name} \$$store->{store_cost}\n";
} 
