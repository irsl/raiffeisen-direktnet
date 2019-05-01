#!/usr/bin/perl

use strict;
use warnings;
use FindBin qw($Bin);
use Data::Dumper;
use lib "$Bin";
use DirektNet;

my $html = "";
while(<STDIN>){
  $html .= $_;
}
print Dumper(DirektNet::parse($html));
