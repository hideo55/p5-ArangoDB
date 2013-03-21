package ArangoDB::Vertex;
use strict;
use warnings;
use utf8;
use 5.010000;
use parent 'ArangoDB::AbstractDocument';
use ArangoDB::Constants qw(:api);
use overload
    q{""}    => sub { shift->name },
    fallback => 1;

sub name {
    $_[0]->{_key};
}

sub fetch {
    my $self = shift;
    my $res = eval { $self->{connection}->http_get( $self->_api_path ) };
    if ($@) {
        $self->_server_error_handler( $@, 'fetch' );
    }
    if ( defined $res && ref($res) eq 'HASH' ) {
        my $v = $res->{vertex};
        for my $key (qw{_id _rev _key vertices edges}) {
            $self->{_rev} = CORE::delete $v->{_rev};
            $self->{document} = { map { $_ => $v->{$_} } grep { $_ !~ /^_/ } keys %$v };
        }
    }
    return $self;
}

sub _api_path {
    my $self = shift;
    return API_GRAPH . '/vertex/' . $self;
}

# Handling server error
sub _server_error_handler {
    my ( $self, $error, $action ) = @_;
    my $msg = sprintf( 'Failed to %s the graph(%s)', $action, $self );
    if ( ref($error) && $error->isa('ArangoDB::ServerException') ) {
        $msg .= ':' . ( $error->detail->{errorMessage} || q{} );
    }
    croak $msg;
}

1;
__END__

=pod

=head1 NAME

ArangoDB::Vertex - An ArangoDB vertex

=head1 DESCRIPTION

Instance of ArangoDB vertex.

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

=head2 delete()

Delete the vertex from database.

=head1 AUTHOR

Hideaki Ohno E<lt>hide.o.j55 {at} gmail.comE<gt>

=cut
