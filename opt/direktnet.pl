#!/usr/bin/perl

use strict;
use warnings;
use FindBin qw($Bin);
use WWW::Mechanize;
use lib "$Bin";
use DirektNet;
use JSON::XS;
use LWP::UserAgent;

my $username = $ENV{DIREKTNET_USERNAME} or die "DIREKTNET_USERNAME missing";
my $password = $ENV{DIREKTNET_PASSWORD} or die "DIREKTNET_PASSWORD missing";
my $report_transactions_service_url = $ENV{DIREKTNET_REPORT_TRANSACTIONS_SERVICE_URL} or die ("Report service URL missing");
my $main_url = $ENV{DIREKTNET_MAIN_URL} || "https://direktnet.raiffeisen.hu";
my $state_file_path = $ENV{DIREKTNET_STATE_FILE_PATH} || "/tmp/raiffeisen/direktnet.json";

my $poll_interval = $ENV{DIREKTNET_POLL_INTERVAL} || 60;

my $account_no = $ENV{DIREKTNET_ACCOUNT_NO} || "";

my $mech = WWW::Mechanize->new();
$mech->timeout(30);

DirektNet::mylog("Fetching main page");
$mech->get("$main_url/cgi-bin/rai/direktnet/home.do");

if($ENV{DIREKTNET_DEBUG}){
  $mech->add_handler("request_send",  sub { shift->dump; return });
  $mech->add_handler("response_done", sub { shift->dump; return });
}

# note: the response html is broken, the module cant parse the title
die "Unexpected title in frontpage" if($mech->content !~ /<title>DirektNet Internet Banking -/);


die "Cant find session details" if($mech->content !~ /\?(BV_SessionID=([^&]+)&BV_EngineID=([^"]+))"/);
my $bv_str = $1;
my $bv_session_id = $2;
my $bv_engine_id = $3;

DirektNet::mylog("Got session details");

DirektNet::mylog("Logging in...");

$mech->submit_form(
	form_name => 'loginForm',
	fields    => { username  => $username, password => $password },
);

die "Login has probably failed" if($mech->content !~ "<title>Raiffeisen DirektNet");

DirektNet::mylog("Login was successful");

if(!$account_no){
   die "Cannot find account number" if($mech->content !~ /showAccountHistory\s*\('(\d+)'\)/);
   $account_no = $1;
   DirektNet::mylog("Found account number: $account_no");
}


my $have_seen_cache = DirektNet::read_state_file($state_file_path);

while(1){

		$mech->post("$main_url/cgi-bin/rai/direktnet/accounts/selectAccountDispatcher.do?$bv_str", {
			BV_SessionID=>$bv_session_id,
			BV_EngineID=>$bv_engine_id,
			accountDispatcherForward=>'accounthistorywithnumber',
			accountNumber=>$account_no,
			accountType=>'-1',
			currency=>'',
			capable=>'',
			incassoAccountDisabled=>'false',
			blockedAccountDisabled=>'false',
			inactiveAccountDisabled=>'false',
			lockedAccountDisabled=>'false',
		});
		
		die "Fetching transactions failed" if(!$mech->success());
		die "Unexpected response, portal has probably kicked us out" if($mech->title() ne "Raiffeisen DirektNet");
		
		my $transactions = DirektNet::parse($mech->content);
		my $new_transactions = DirektNet::show_new_ones_only($transactions, $have_seen_cache);
		DirektNet::remove_old_ones($have_seen_cache);
		
		my $all_c = scalar keys %$transactions;
		my $new_c = scalar @$new_transactions;

		DirektNet::mylog("Polling succeeded: $new_c/$all_c");

		if(($new_c) && (report($new_transactions))) {
		   DirektNet::mylog("Report succeeded, marking these transactions being succesful");
		   DirektNet::mark_as_seen($new_transactions, $have_seen_cache);
		   DirektNet::write_state_file($state_file_path, $have_seen_cache);
		}
		
		sleep($poll_interval);
}

sub report {
    my $tr = shift;
	
	DirektNet::mylog("Reporting transactions to remote site: $report_transactions_service_url");

    my $ua = LWP::UserAgent->new;
    $ua->timeout(30);
    $ua->env_proxy;

    my $payload = encode_json($tr);
	#DirektNet::mylog("payload is: $payload");
    my $res = $ua->post( $report_transactions_service_url, "Content-Type" => "application/json", Content => $payload );
	return $res->is_success;
}
