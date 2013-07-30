package ZMQ::WebSocket::Bridge;
use 5.010;
use Moose;
use ZMQ::Simple;
use Net::WebSocket::Server;
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

=head1 METHODS

=cut

=head2 run

start the server

=cut

sub run {
    my $self = shift;
    
    say 'starting server.';
    
    Net::WebSocket::Server->new(
        listen => 8080,
        on_connect => sub {
            my ($serv, $conn) = @_;
            $conn->on(
                handshake => sub { $self->_handshake(@_) },
                utf8 => sub {
                    my ($conn, $msg) = @_;
                    warn "utf8: ($conn) $msg";
                    $_->send_utf8($msg) for $conn->server->connections;
                },
                binary => sub {
                    my ($conn, $msg) = @_;
                    warn "binary: $msg";
                    $_->send_binary($msg) for $conn->server->connections;
                },
            );
        },
    )->start;
}

sub _handshake {
    my ($self, $conn, $handshake) = @_;
    warn sprintf 'handshake - origin: "%s", resource: "%s" ', 
        $handshake->req->origin, 
        $handshake->req->resource_name;
    
    
    # $conn->disconnect() unless $handshake->req->origin eq $origin;
}

__PACKAGE__->meta->make_immutable;
1;

=head1 AUTHOR

Wolfgang Kinkeldei, E<lt>wolfgang@kinkeldei.deE<gt>

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
