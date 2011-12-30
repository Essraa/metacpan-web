package MetaCPAN::Web::Controller::Module;

use Moose;
use namespace::autoclean;
use HTML::Restrict;

BEGIN { extends 'MetaCPAN::Web::Controller' }

with qw(
    MetaCPAN::Web::Role::ReleaseInfo
);

sub index : PathPart('module') : Chained('/') : Args {
    my ( $self, $c, $id, @module ) = @_;

    # force consistent casing in URLs
    if ( @module != 0 and $id ne uc($id) ) {
        $c->res->redirect('/module/' . join('/', uc($id), @module), 301);
        $c->detach();
    }

    @module = ($id, @module);
    my $data
        = @module == 1
        ? $c->model('API::Module')->find(@module)->recv
        : $c->model('API::Module')->get(@module)->recv;

    $c->detach('/not_found') unless ( $data->{name} );

    my $reqs = $self->api_requests($c, {
            pod     => $c->model('API')->request( '/pod/' . join( '/', @module ) ),
            release => $c->model('API::Release')->get( @{$data}{qw(author release)} ),
        },
        $data,
    );
    $reqs = $self->recv_all($reqs);
    $self->stash_api_results($c, $reqs, $data);

    my $hr = HTML::Restrict->new;
    $hr->set_rules(
        {   a       => [qw( href target )],
            b       => [],
            br      => [],
            caption => [],
            center  => [],
            code    => [],
            dd      => ['id'],
            div     => [qw(style)],
            dl      => ['id'],
            dt      => ['id'],
            em      => [],
            h1      => ['id'],
            h2      => ['id'],
            h3      => ['id'],
            h4      => ['id'],
            h5      => ['id'],
            h6      => ['id'],
            i       => [],
            img     => [qw( alt border height width src style / )],
            li      => ['id'],
            ol      => [],
            p       => [qw(style)],
            pre     => [qw(id class)],
            span    => [qw(style)],
            strong  => [],
            sub     => [],
            sup     => [],
            table   => [qw( style class border cellspacing cellpadding align )],
            tbody   => [],
            td      => [ qw(style class) ],
            tr      => [ qw(style class) ],
            u       => [],
            ul      => ['id'],
        }
    );

    $c->stash(
        {   module  => $data,
            pod     => $hr->process( $reqs->{pod}->{raw} ),
            release => $reqs->{release}->{hits}->{hits}->[0]->{_source},
            template => 'module.html',
        }
    );
}

1;
