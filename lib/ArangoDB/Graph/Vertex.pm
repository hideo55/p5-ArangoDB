package ArangoDB::Graph::Vertex;
use strict;
use warnings;
use utf8;
use 5.010000;
use parent 'ArangoDB::Graph::Element';
use ArangoDB::Constants qw(:api);

our $VERSION = '0.08';

sub _api_path {
    my $self = shift;
    return API_GRAPH . '/' . $self->{_graph} . '/vertex/' . $self->name;
}

# Handling server error
sub _server_error_handler {
    my ( $self, $error, $action ) = @_;
    my $msg = sprintf( 'Failed to %s the vertex(%s)', $action, $self );
    if ( ref($error) && $error->isa('ArangoDB::ServerException') ) {
        $msg .= ':' . ( $error->detail->{errorMessage} || q{} );
    }
    croak $msg;
}

1;
__END__

=pod

=head1 NAME

ArangoDB::Graph::Vertex - An ArangoDB vertex

=head1 DESCRIPTION

Instance of ArangoDB vertex(vertex of graph).

=head1 METHODS

=head2 new($raw_vertex)

Constructor.

=head2 id()

Returns identifer of the vertex.

=head2 revision()

Returns revision of the vertex.

=head2 name()

Returns vertex name.

=head2 fetch()

Fetch the vertex data from database.

=head2 save()

Save the changes of vertex to database.

head2 partial_update($value[,$keep_null])

Partially updates the vertex.

=head2 delete()

Delete the vertex from database.

=head1 AUTHOR

Hideaki Ohno E<lt>hide.o.j55 {at} gmail.comE<gt>

=cut
