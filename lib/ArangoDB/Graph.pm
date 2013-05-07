package ArangoDB::Graph;
use strict;
use warnings;
use utf8;
use 5.010000;
use ArangoDB::Constants qw(:api);
use ArangoDB::Graph::Vertex;
use ArangoDB::Graph::Edge;
use overload
    q{""}    => sub { shift->name },
    fallback => 1;

our $VERSION = '0.08';

sub new {
    my ( $class, $conn, $graph ) = @_;
    die "Invalid argument for $class : undef" unless defined $graph;
    my $self = bless { connection => $conn, }, $class;
    weaken( $self->{connection} );
    for my $key (qw{_id _rev _key vertices edges}) {
        $self->{$key} = $graph->{$key};
    }
    return $self;
}

sub id {
    $_[0]->{_id};
}

sub revision {
    $_[0]->{_rev};
}

sub name {
    $_[0]->{_key};
}

sub vertices {
    $_[0]->{vertices};
}

sub edges {
    $_[0]->{edges};
}

sub fetch {
    my $self = shift;
    my $res = eval { $self->{connection}->http_get( $self->_api_path ) };
    if ($@) {
        $self->_server_error_handler( $@, 'fetch' );
    }
    if ( defined $res && ref($res) eq 'HASH' ) {
        my $gr = $res->{graph};
        for my $key (qw{_id _rev _key vertices edges}) {
            $self->{$key} = $gr->{$key};
        }
    }
    return $self;
}

sub delete {
    my $self = shift;
    eval { $self->{connection}->http_delete( $self->_api_path ) };
    if ($@) {
        $self->_server_error_handler( $@, 'delete' );
    }
    return $self;
}

sub get_vertex {
    my ( $self, $name ) = @_;
    my $api = $self->_api_path . '/vertex/' . $name;
    my $vertex;
    eval {
        my $res = $self->{connection}->http_get($api);
        $vertex = ArangoDB::Graph::Vertex->new( $self->{connection}, $res->{vertex} );
    };
    if ($@) {
        $self->_vertex_error_handler( $@, 'get' );
    }
    return $vertex;
}

sub save_vertex {
    my ( $self, $name, $optional ) = @_;
    my $api = $self->_api_path . '/vertex';
    my $vertex;
    eval {
        my $res = $self->{connection}->http_post( $api, { _key => $name, %{ $optional || {} } } );
        $vertex = ArangoDB::Graph::Vertex->new( $self->{connection}, $res->{vertex} );
    };
    if ($@) {
        $self->_vertex_error_handler( $@, 'save' );
    }
    return $vertex;
}

sub get_neighbor_vertices {
    my ( $self, $name ) = @_;
    my $api = $self->_api_path . '/vertices/' . $name;
    my $res = eval { $self->{connection}->http_post($api) };
    if ($@) {
        $self->_server_error_handler( $@, 'Failed to execute query' );
    }
    return ArangoDB::Cursor->new( $self->{connection}, $res, 'ArangoDB::Graph::Vertex' );
}

sub get_edge {
    my ( $self, $name ) = @_;
    my $api = $self->_api_path . '/edge/' . $name;
    my $edge;
    eval {
        my $res = $self->{connection}->http_get($api);
        $edge = ArangoDB::Graph::Edge->new( $self->{connection}, $res->{edge} );
    };
    if ($@) {
        $self->_edge_error_handler( $@, 'get' );
    }
    return $edge;
}

sub save_edge {
    my ( $self, $name, $from, $to, $label, $optional ) = @_;
    my $api = $self->_api_path . '/edge';
    my $edge;
    my $params = { _key => $name, _from => $from, _to => $to, %{ $optional || {} } };
    if ($label) {
        $params->{'$label'} = $label;
    }
    eval {
        my $res = $self->{connection}->http_post( $api, $params );
        $edge = ArangoDB::Graph::Edge->new( $self->{connection}, $res->{edge} );
    };
    if ($@) {
        $self->_edge_error_handler( $@, 'save' );
    }
    return $edge;
}

sub get_connected_edges {
    my ( $self, $vertex_name ) = @_;
    my $api = $self->_api_path . '/edges/' . $vertex_name;
    my $res = eval { $self->{connection}->http_post($api) };
    if ($@) {
        $self->_server_error_handler( $@, 'Failed to execute query' );
    }
    return ArangoDB::Cursor->new( $self->{connection}, $res, 'ArangoDB::Graph::Edge' );
}

sub _api_path {
    my $self = shift;
    return API_GRAPH . '/' . $self;
}

# Handling server error
sub _graph_error_handler {
    my ( $self, $error, $action ) = @_;
    my $msg = sprintf( 'Failed to %s the graph(%s)', $action, $self );
    if ( ref($error) && $error->isa('ArangoDB::ServerException') ) {
        $msg .= ':' . ( $error->detail->{errorMessage} || q{} );
    }
    croak $msg;
}

sub _vertex_error_handler {
    my ( $self, $error, $action ) = @_;
    my $msg = sprintf( 'Failed to %s the vertex(%s)', $action, $self );
    if ( ref($error) && $error->isa('ArangoDB::ServerException') ) {
        $msg .= ':' . ( $error->detail->{errorMessage} || q{} );
    }
    croak $msg;
}

sub _edge_error_handler {
    my ( $self, $error, $action ) = @_;
    my $msg = sprintf( 'Failed to %s the edge(%s)', $action, $self );
    if ( ref($error) && $error->isa('ArangoDB::ServerException') ) {
        $msg .= ':' . ( $error->detail->{errorMessage} || q{} );
    }
    croak $msg;
}

1;
__END__

=pod

=head1 NAME

ArangoDB::Graph - An ArangoDB graph

=head1 DESCRIPTION

Instance of ArangoDB graph.

=head1 METHODS

=head2 new($raw_graph)

Constructor.

=head2 id()

Returns identifer of the graph.

=head2 revision()

Returns revision of the graph.

=head2 name()

Returns graph name.

=head2 fetch()

Fetch the graph data from database.

=head2 delete()

Delete the graph from database.

=head2 vertices()

Get the name of the vertices(documents) collection.

=head2 edges()

Get the name of the edges collection,

=head2 get_vertex()

=head2 save_vertex()

=head2 get_neighbor_vertices()

=head2 get_edge()

=head2 save_edge()

=head2 get_connected_edges()

=head1 AUTHOR

Hideaki Ohno E<lt>hide.o.j55 {at} gmail.comE<gt>

=cut
