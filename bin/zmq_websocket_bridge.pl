#!/usr/bin/env perl
use FindBin;
use lib "$FindBin::Bin/../lib", "$FindBin::Bin/../../ZMQ-Simple/lib";
use ZMQ::WebSocket::Bridge;

ZMQ::WebSocket::Bridge->new_with_options->run;
