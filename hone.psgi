#!/usr/bin/env perl

use strict;
use warnings;

use AnyMQ::RawSocket;
use Web::Hippie::App::JSFiles;
use Web::Hippie::PubSub;
use Plack::Builder;
use Plack::Request;
use Carp qw/croak cluck/;

# run using Feersum::Runner or Plack::Handler::Feersum
# development: plackup -s Feersum --port 4000 -I../lib -E development -r hone.psgi
# deployment:  plackup -s Feersum --port 4000 -I../lib -E deployment hone.psgi

my $bus = AnyMQ->new_with_traits(
    traits  => [ 'RawSocket' ],
    address => '0.0.0.0:7100',
);

# print stack trace
sub fatal {
    my ($err) = @_;
    cluck "Fatal error when handling request: $err\n";
}

my $app = sub {
    my $env = shift;
    my $req = Plack::Request->new($env);
    my $res = $req->new_response(200);
    
    $res->content_type('text/html; charset=utf-8');
    
    if ($req->path eq '/') {
        # index
        $res->redirect('/static/vis.html');
    } else {
        # unknown path
        $res->content("Unknown path " . $req->path);
        $res->code(404);
    }

    $res->finalize;
};

builder {
    # static files
    mount '/static' =>
	    Plack::App::Cascade->new(
            apps => [
                Web::Hippie::App::JSFiles->new->to_app,
                Plack::App::File->new( root => 'static' )->to_app,
            ],
        );

    # anymq hippie server
    mount '/_hippie' => builder {
        enable "+Web::Hippie::PubSub",
            keep_alive => 5,
            bus        => $bus;
        sub {
            my ($env) = @_;

            my $req = Plack::Request->new($env);
            my $path = $req->path;
            my $channel = $env->{'hippie.args'};

            if ($path eq '/new_listener') {
                warn "Got new listener on channel $channel\n";
            } elsif ($path eq '/message') {
                my $msg = $env->{'hippie.message'};
                warn "Posting message to channel $channel\n";
            } elsif ($path eq '/error') {
                # client disconnected
            } else {
                warn "Unknown hippie event: $path\n";
            }

            return;
        };
    };

    mount '/' => $app;
};
