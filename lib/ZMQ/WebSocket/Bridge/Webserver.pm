package ZMQ::WebSocket::Bridge::Webserver;
use 5.010;
use Moose;
use Net::Async::HTTP::Server;
use HTTP::Response;
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
        on_request =>sub {
            my $dummy = shift;
            my ($req) = @_;
            
            say join ' ', 'http', $req->method, $req->path;
            
            my @lines;
            push @lines, map { ref($_) . ':' . $_->notifier_name } $self->parent->loop->notifiers;
            
            my $content = join "\n", @lines;
            
            my $res = HTTP::Response->new(200);
            $res->header('Content-Length' => length $content);
            $res->add_content($content);
            $res->content_type('text/plain');
            
            $req->respond($res);
            
            say 'http-request done';
        },
    );
}

sub start {
    my $self = shift;
    
    $self->parent->add($self);
    
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
