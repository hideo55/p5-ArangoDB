package ArangoDB::Cursor;
use strict;
use warnings;
use Carp qw(croak);
use ArangoDB::Document;
use ArangoDB::Constants qw(:api);
use Class::Accessor::Lite ( ro => [qw/id length/], );

sub new {
    my ( $class, $conn, $cursor ) = @_;
    my $self = bless {
        connection => $conn,
        id         => $cursor->{id},
        length     => $cursor->{count} || scalar( @{ $cursor->{result} } ),
        has_more   => $cursor->{hasMore},
        position   => 0,
        result     => $cursor->{result} || [],
    }, $class;
    return $self;
}

sub next {
    my $self = shift;
    if ( $self->{position} < $self->{length} || $self->_get_next_batch() ) {
        return ArangoDB::Document->new( $self->{result}->[ $self->{position}++ ] );
    }
    return;
}

sub _get_next_batch {
    my $self = shift;
    return unless $self->{has_more};
    eval {
        my $res = $self->{connection}->http_put( API_CURSOR . '/' . $self->id, {} );
        $self->{id}       = $res->{id};
        $self->{has_more} = $res->{hasMore};
        $self->{length}   = scalar( @{ $res->{result} } );
        $self->{result}   = $res->{result};
        $self->{position} = 0;
    };
    if ($@) {
        $self->_server_error_handler( $@, 'Failed to get next batch cursor(%d)' );
    }
    return 1;
}

sub delete {
    my $self = shift;
    my $api  = API_CURSOR . '/' . $self->id;
    eval { $self->{connection}->http_delete($api) };
    if ($@) {
        $self->_server_error_handler( $@, 'Failed to delete cursor(%d)' );
    }
}

sub _server_error_handler {
    my ( $self, $error, $message ) = @_;
    my $msg = sprintf( $message, $self->id );
    if ( ref($error) && $error->isa('ArangoDB::ServerException') ) {
        $msg .= ':' . ( $error->detail->{errorMessage} || q{} );
    }
    croak $msg;
}

1;
__END__


=pod

=head1 NAME

ArangoDB::Cursor

==head1 DESCRIPTION

=head1 METHODS

=head2 new()

Constructor.

=head2 next()

Returns next document.

=head2 delete()

Delete cursor.

=head1 AUTHOR

Hideaki Ohno E<lt>hide.o.j55 {at} gmail.comE<gt>

=head1 SEE ALSO

ArangoDB websie L<http://www.arangodb.org/>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
