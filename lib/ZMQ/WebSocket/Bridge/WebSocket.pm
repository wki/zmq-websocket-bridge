package ZMQ::WebSocket::Bridge::WebSocket;
use 5.010;
use Moose;
use Net::Async::WebSocket::Server;
use namespace::autoclean;

has parent => (
    is       => 'ro',
    isa      => 'Object',
    required => 1,
    weak_ref => 1,
);

has port => (
    is      => 'ro',
    isa     => 'Int',
    default => 4000,
);

has notifier => (
    is         => 'ro',
    isa        => 'IO::Async::Notifier',
    lazy_build => 1,
);

sub _build_notifier {
    my $self = shift;

    Net::Async::WebSocket::Server->new(
       on_client => sub {
          my ( undef, $client ) = @_;

          say "websocket connect from $client";
          
          ### TODO: depending on URL -- create a ZMQ Socket
          ###       
          
          $client->configure(
             on_frame => sub {
                my ( $self, $frame ) = @_;
                
                say "websocket receive: $frame";
                $self->send_frame( $frame );
             },
             
             on_closed => sub {
                say "websocket closed"; 
             },
          );
       }
    );
}

sub start {
    my $self = shift;
    
    $self->parent->add($self);

    $self->notifier->listen(
       service          => $self->port,

       on_listen_error  => sub { die "Cannot listen - $_[-1]" },
       on_resolve_error => sub { die "Cannot resolve - $_[-1]" },
    );
}

__PACKAGE__->meta->make_immutable;
1;
