package ZMQ::WebSocket::Bridge;
use 5.010;
use Moose;
use IO::Async::Loop;
# use ZMQ::Simple;
use ZMQ::WebSocket::Bridge::Webserver;
use ZMQ::WebSocket::Bridge::WebSocket;
use Data::Dumper;
use namespace::autoclean;

with 'MooseX::Getopt::Strict';

=head1 NAME

ZMQ::WebSocket::Bridge - the server side for a Websocket ZMQ Bridge

=head1 SYNOPSIS

=head1 DESCRIPTION

 * read a config file
 * handshake: find matching config entry
 * zmq poll

=head1 ATTRIBUTES

=cut

has config => (
    is         => 'rw',
    isa        => 'ArrayRef',
    lazy_build => 1,
);

sub _build_config {
    return [
        {
            host    => '*',
            path    => 'info',
            address => 'tcp://127.0.0.1:9000',
        },
        {
            host    => '*',
            path    => 'news',
            address => 'tcp://127.0.0.1:9001',
        },
    ];
}

=head2 webserver

The web server is meant as a simple status page for the entire bridge

=cut

has webserver => (
    is         => 'ro',
    isa        => 'ZMQ::WebSocket::Bridge::Webserver',
    lazy_build => 1,
);

sub _build_webserver {
    my $self = shift;
    
    ZMQ::WebSocket::Bridge::Webserver->new(
        parent => $self,
        port   => 8080,
    );
    
    ### TODO: find a way to map URLs to actions
}

=head2 websocket

A Websocket listening service

=cut

has websocket => (
    is => 'ro',
    isa => 'ZMQ::WebSocket::Bridge::WebSocket',
    lazy_build => 1,
);

sub _build_websocket {
    my $self = shift;
    
    ZMQ::WebSocket::Bridge::WebSocket->new(
        parent => $self,
        port   => 4000,
    );
}

=head1 METHODS

=cut

=head2 loop

returns the (singleton) event loop instance

Maybe, we can move loop into a regular attribute, we will see :-)

=cut

sub loop {
    state $loop = IO::Async::Loop->new;
    
    return $loop;
}

=head2 add ( $notifier )

add a notifier to a loop

=cut

sub add {
    my ($self, $thing) = @_;
    
    $self->loop->add($thing->notifier);
}

=head2 run

start the server

=cut

sub run {
    my $self = shift;
    
    # force to use the Poll loop, because it has a nice hook
    local $IO::Async::Loop::LOOP = 'Poll';
    
    ### TODO: add a statistics object containing all relevant things
    
    $self->webserver->start;
    $self->websocket->start;
    
    say 'running loop...';
    
    # $self->loop->run;
    
    my $loop = $self->loop;
    while (1) {
        $loop->loop_once(0.5);
        say Dumper $loop->{iowatches};
    }
}

__PACKAGE__->meta->make_immutable;
1;

=head1 AUTHOR

Wolfgang Kinkeldei, E<lt>wolfgang@kinkeldei.deE<gt>

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
