package ArangoDB;
use strict;
use warnings;
use ArangoDB::Connection;
use ArangoDB::Collection;
use ArangoDB::Constants qw(:api);

our $VERSION = '0.01';

sub new {
    my ( $class, $options ) = @_;
    my $self = bless {}, $class;
    $self->{connection} = ArangoDB::Connection->new($options);
    return $self;
}

sub create {
    my ( $self, $name, $_options ) = @_;
    my $params = { ( waitForSync => 0, isSystem => 0 ), %{ $_options || {} } };
    $params->{name} = $name;
    my $coll;
    eval {
        my $res = $self->{connection}->http_post( API_COLLECTION, $params );
        $coll = ArangoDB::Collection->new( $self->{connection}, $res );
    };
    if ($@) {
        my $msg = "Failed to create collection($name)";
        if ( ref($@) && $@->isa('ArangoDB::ServerException') ) {
            $msg .= ':' . $@->detail->{errorMessage};
        }
        die $msg;
    }
    return $coll;
}

sub collection {
    my ( $self, $name ) = @_;
    my $api = API_COLLECTION . '/' . $name;
    my $res = undef;
    eval { $res = $self->{connection}->http_get($api); };
    if ($@) {
        my $e = $@;
        if ( !ref($e) || ( $e->isa('ArangoDB::ServerException') && $e->code != 404 ) ) {
            die "Failed to get collection: $name";
        }
    }
    return $res ? ArangoDB::Collection->new( $self->{connection}, $res ) : undef;
}

sub collections {
    my $self  = shift;
    my $conn  = $self->{connection};
    my $res   = $conn->http_get(API_COLLECTION);
    my @colls = map { ArangoDB::Collection->new( $conn, $_ ) } @{ $res->{collections} };
    return \@colls;
}

sub drop {
    my ( $self, $name ) = @_;
    my $api = API_COLLECTION . '/' . $name;
    eval { $self->{connection}->http_delete($api); };
    if ($@) {
        my $e = $@;
        if ( !ref($e) || ( $e->isa('ArangoDB::ServerException') && $e->code != 404 ) ) {
            die "Failed to drop collection: $name";
        }
    }
}

sub trancete {
    my ( $self, $name ) = @_;
    my $coll = $self->collection($name);
    if ($coll) {
        $coll->truncate;
    }
    else {
        die "Collection($name) not found.";
    }
}

1;
__END__

=head1 NAME

ArangoDB -

=head1 SYNOPSIS

  use ArangoDB;

=head1 DESCRIPTION

ArangoDB is

=head1 AUTHOR

Hideaki Ohno E<lt>hide.o.j55 {at} gmail.comE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
