#!perl
use strict;
use warnings;
use Plack::Builder;

my $app = sub {
    [200, ['Content-Type' => 'text/plain'], ['Hello World']]
};

builder {
    enable 'Plack::Middleware::WebSocket';
    $app;
    # $psgi_app;
};
