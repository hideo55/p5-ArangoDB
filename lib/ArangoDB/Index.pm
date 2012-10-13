package ArangoDB::Index;
use strict;
use warnings;
use Carp qw(croak);
use Scalar::Util qw(weaken);
use ArangoDB::Constants qw(:api);
use Class::Accessor::Lite ( ro => [qw/id collection_id type/] );

use overload
    q{""}    => sub { $_[0]->id },
    fallback => 1;

sub new {
    my ( $class, $conn, $params ) = @_;
    my $self = bless {%$params}, $class;
    $self->{connection} = $conn;
    weaken( $self->{connection} );
    $self->{collection_id} = ( split '/', $self->{id} )[0];
    return $self;
}

sub drop {
    my $self = shift;
    my $api  = API_INDEX . '/' . $self->{id};
    my $res  = eval { $self->{connection}->http_delete($api) };
    if ($@) {
        $self->_server_error_handler( $@, 'drop' );
    }
    return;
}

# Handling server error
sub _server_error_handler {
    my ( $self, $error, $action ) = @_;
    my $msg = sprintf( 'Failed to %s the index(%s)', $action, $self->{id} );
    if ( ref($error) && $error->isa('ArangoDB::ServerException') ) {
        $msg .= ':' . ( $error->detail->{errorMessage} || q{} );
    }
    croak $msg;
}

1;
__END__

=pod

=head1 NAME

ArangoDB::Index - Base class of ArangoDB indexes

=head1 DESCRIPTION

Base class of ArangoDB indexes.

=head1 METHODS

=head2 new()

Constructor.

=head2 id()

Returns identifier of index.

=head2 type()

Returns type of index.

=head2 collection_id()

Returns identifier of the index.

=head2 drop()

Drop the index.

=head1 AUTHOR

Hideaki Ohno E<lt>hide.o.j55 {at} gmail.comE<gt>

=cut
