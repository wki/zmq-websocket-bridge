package Plack::Middleware::WebSocket;
use AnyEvent::Handle;
use Protocol::WebSocket::Handshake::Server;
use Protocol::WebSocket::Frame;

use parent 'Plack::Middleware';

=head1 NAME

Plack::Middleware::WebSocket - a simple WebSocket Middleware

=head1 SYNOPSIS

    # in app.psgi
    use Plack::Builder;
    
    my $app = sub { ... }
    
    builder {
        enable 'Plack::Middleware::WebSocket';
        $app;
    }

=head1 DESCRIPTION

=head1 METHODS

=cut

=head2 call ( $env )

=cut

sub call {
    my ($self, $env) = @_;
    
    if (exists $env->{HTTP_UPGRADE} && $env->{HTTP_UPGRADE} eq 'websocket') {
        warn "[$$] Websocket: initiating WebSocket";
        
        my $fh = $env->{'psgix.io'} or return [500, [], []];

        my $hs = Protocol::WebSocket::Handshake::Server->new_from_psgi($env);
        $hs->parse($fh) or return [400, [], [$hs->error]];

        return sub {
            my $respond = shift;

            my $h = AnyEvent::Handle->new(fh => $fh);
            my $frame = Protocol::WebSocket::Frame->new;

            $h->push_write($hs->to_string);

            $h->on_read(
                sub {
                    warn "$h: on_read";
                    $frame->append($_[0]->rbuf);

                    while (my $message = $frame->next) {
                        warn "Reading: $message";
                        
                        $message = Protocol::WebSocket::Frame->new($message)->to_bytes;
                        
                        # after closing a WebSocket from the browser, we may
                        # die here... find out why.
                        $h->push_write($message);
                    }
                }
            );
        };
    } else {
        warn "[$$] Websocket: calling regular app";
        return $self->app->($env);
    }
}

1;

=head1 AUTHOR

Wolfgang Kinkeldei, E<lt>wolfgang@kinkeldei.deE<gt>

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
