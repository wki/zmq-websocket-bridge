package ZMQ::WebSocket::Bridge::Webserver;
use 5.010;
use Moose;
use MooseX::NonMoose;
use Net::Async::HTTP::Server;
use HTTP::Response;
use namespace::autoclean;

has port => (
    is      => 'ro',
    isa     => 'Int',
    default => 8080,
);

has notifier => (
    is         => 'ro',
    isa        => 'IO::Async::Notifier',
    lazy_build => 1,
);

sub _build_notifier {
    my $self = shift;

    Net::Async::HTTP::Server->new(
        # FIXME: socket not listening at this moment!
        on_request => sub {
            my $self = shift;
            my ($req) = @_;
            
            say join ' ', $req->method, $req->path;
            
            my $res = HTTP::Response->new(200);
            $res->add_content("blabla\n");
            $res->content_type('text/plain');
            
            $req->respond($res);
            
            say 'Loop: ' . $self->loop;
            $self->loop->remove($self);
            
            $self->close_read;
            $self->close_write;
            
            # FIXME: socket is not closed!
            say 'request done';
        },
    );
}

sub start {
    my $self = shift;
    
    $self->notifier->listen(
        addr => {
            family   => 'inet',
            socktype => 'stream',
            port     => $self->port,
        },
        on_listen_error => sub {
            die "Cannot listen: $_[-1]"
        },
        on_closed => sub {
            say 'closed';
        },
    );
}

__PACKAGE__->meta->make_immutable;
1;
