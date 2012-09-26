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
            $msg .= ':' . ( $@->detail->{errorMessage} || q{} );
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
    my $self = shift;
    my $conn = $self->{connection};
    my @colls;
    eval {
        my $res = $conn->http_get(API_COLLECTION);
        @colls = map { ArangoDB::Collection->new( $conn, $_ ) } @{ $res->{collections} };
    };
    if ($@) {
        my $e = $@;
        if ( !ref($e) || ( $e->isa('ArangoDB::ServerException') && $e->code != 404 ) ) {
            die 'Failed to get collections';
        }
    }
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

sub truncate {
    my ( $self, $name ) = @_;
    my $coll = $self->collection($name);
    if ($coll) {
        $coll->truncate;
    }
}

1;
__END__

=head1 NAME

ArangoDB - ArangoDB client for Perl.

=head1 SYNOPSIS

  use ArangoDB;
  
  my $db = ArangoDB->new({
      host => 'localhost',
      port => 8529,
  });
  
  # Create new collection
  my $coll = $db->create('collection_a');
  
  # Create new document
  my $doc = $coll->save({ foo => 1 });
  

=head1 DESCRIPTION

ArangoDB is ArangoDB client for Perl.

=head1 SUPPORT API VERSION

This supports ArangoDB API implementation 1.0.

=head1 METHODS

=head2 new($options)

Constructor.
$options is HASH reference.The attributes of $options are:

=over 4

=item host

=item port

=back

=head2 create($name)

Create new collection.

=head2 collection($name)

Get exists connection.

=head2 collections()

Get all collections.

=head2 drop($name)

Drop collection.
Same as `$db->collection($name)->drop();`.

=head2 truncate($name)

Truncate collection.
Same as `$db->collection($name)->truncate();`.

=back

=head1 AUTHOR

Hideaki Ohno E<lt>hide.o.j55 {at} gmail.comE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
