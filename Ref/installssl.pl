#!/usr/local/cpanel/3rdparty/bin/perl

use strict;
use LWP::UserAgent;
use LWP::Protocol::https;
use MIME::Base64;
use IO::Socket::SSL;
use URI::Escape;

my $user = "root";
my $pass = "rootpass";

my $auth = "Basic " . MIME::Base64::encode( $user . ":" . $pass );

my $ua = LWP::UserAgent->new(
    ssl_opts   => { verify_hostname => 0, SSL_verify_mode => 'SSL_VERIFY_NONE', SSL_use_cert => 0 },
);

my $folder = $ARGV[0];
my $dom = $ARGV[1];

my $certfile = "/etc/letsencrypt/live/$folder/cert.pem";
my $keyfile = "/etc/letsencrypt/live/$folder/privkey.pem";
my $cafile =  "/etc/letsencrypt/live/$folder/chain.pem";

my $certdata;
my $keydata;
my $cadata;

open(my $certfh, '<', $certfile) or die "cannot open file $certfile";
    {
        local $/;
        $certdata = <$certfh>;
    }
    close($certfh);

open(my $keyfh, '<', $keyfile) or die "cannot open file $keyfile";
    {
        local $/;
        $keydata = <$keyfh>;
    }
    close($keyfh);

open(my $cafh, '<', $cafile) or die "cannot open file $cafile";
    {
        local $/;
        $cadata = <$cafh>;
    }
    close($cafh);

my $cert = uri_escape($certdata);
my $key = uri_escape($keydata);
my $ca = uri_escape($cadata);

system("whmapi1 installssl domain=${dom} crt=${cert} cabundle=${ca} key=${key}");

#chmod +x fixsslfromlogs.sh
#chmod +x installssl.sh
#chmod +x installssl.pl
#then launch fixsslfromlogs.sh
