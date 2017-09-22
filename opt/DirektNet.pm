package DirektNet;

use Data::Dumper;
use strict;
use warnings;
use HTML::Strip;
use Encode qw( decode encode );
use JSON::XS;
use File::Slurp;
use File::Basename;

use constant A_MONTH_IN_SECONDS => 30 * 24 * 60 * 60;

local $| = 1;

sub parse {
  my $re = {};
  my $html = shift;
  for my $category ("Need booking items", "Booked items", "Pending items") {
     _parse_category($re, $html, $category);
  }
  return $re;
}

sub show_new_ones_only {
   my $candidates= shift;
   my $have_seen = shift;
   
   my @re;
   for my $id (keys %$candidates){
      next if($have_seen->{$id});
	  
	  # this is a new one!
	  push @re, $candidates->{$id};
   }   
   
   return \@re;
}

sub mark_as_seen {
  my $new_transactions = shift;
  my $have_seen = shift;
  my $now = time;
  for my $tr (@$new_transactions) {
	  $have_seen->{$tr->{id}} = $now;
  }
}

sub remove_old_ones {
  my $have_seen= shift;
  my $now= time();
  for my $id (keys %$have_seen){
     my $d = $have_seen->{$id};
	 if($now - $d > A_MONTH_IN_SECONDS) {
	    delete $have_seen->{$id};
	 }
  }
}


sub _parse_category {
  my $re = shift;
  my $html = shift;
  my $category = shift;
  
  
  return if($html !~ /\Q<!-- $category -->\E(.+?)<!--/s);
  my $inner = trim($1);
  return if(!$inner);
  
  #print "$category: $inner\n";
  while($inner =~ m#<tr[^>]*>(.+?)</tr>#gs) {
     my $row = $1;
	 my @cells;
	 while($row =~ m#<td[^>]*>(.+?)</td>#gs){
	   push @cells, trim($1);
	 }
	 next if(!scalar @cells);
	 my $item = {category=>$category};
	 $item->{type} = $cells[0];
	 if($cells[1] !~ m#(\d{4})\.(\d\d)\.(\d\d)<br\s*/?>#) {
	    mylog("Cant parse date?:".$cells[1]);
	 }
	 $item->{date} = "$1-$2-$3";
	 my $amount_str = strip_html($cells[2]);
	 $item->{amount} = $amount_str;
	 $item->{amount} =~ s/,/./g;
	 $item->{amount} =~ s/[^\d\.]//g;
	 if($amount_str =~ /([A-Z]{3})$/) {
	    $item->{currency} = $1;
	 }
	 my @rs = split(/<br\s*\/?>/, $cells[3]);
	 if(scalar @rs == 2) {
	    $item->{'recipient_name'} = strip_html($rs[0]);
		$item->{'recipient_extra'} = trim($rs[1]);
	 } else {
	    mylog("Couldnt parse recipient info");
	 }
	 
	 $item->{'comment'} = [];
	 my @cs = split(/<br\s*\/>/, $cells[4]);
	 for(my $i = 0; $i < scalar @cs -1; $i++){
  	   push @{$item->{'comment'}}, trim($cs[$i]);
	 }	 
	 
	 if($cells[4] =~ m#<small class="grayText">([^<]+)</small>#){
	    $item->{id} = trim($1);
	 }
	 
	 if(!$item->{id}) {
	    $item->{id} = $item->{date}. " ".$item->{amount}. " ".$item->{currency}." ".$item->{recipient_name}." ".$item->{recipient_extra};
	 }
	 
	 #print Dumper($item, \@cells);
	 
	 $re->{$item->{id}} = $item;
  }
}

sub trim {
  my $s = shift;
  $s =~ s/^\s*//g;
  $s =~ s/\s*$//g;
  return $s;
}

sub mylog {
  my $msg = shift;
  my $now = localtime;
  print STDERR "[$now] $msg\n";
}

sub strip_html {
  my $in = shift;
  my $hs = HTML::Strip->new();
  return $hs->parse($in);
}

sub read_state_file{
  my $path = shift;
  my $dir = dirname($path);
  if(!-d $dir) {
     mylog("State directory does not exist: $dir");
	 return;
  }
  my $content = read_file($path, err_mode=>'carp');
  return {} if(!$content);
  return decode_json($content);
}

sub write_state_file{
  my $path = shift;
  my $object = shift;
  
  my $dir = dirname($path);
  if(!-d $dir) {
     if(!mkdir($dir)) {
		 mylog("State directory ($dir) does not exist and we were not able to create it: $!");
		 return;	 
	 }
  }
  
  my $content = encode_json($object);
  if(!write_file($path, {err_mode=>'carp'}, $content)) {
     mylog("Could not save state file to $path: $!");
  }
}

1;
