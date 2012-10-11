package ArangoDB;
use strict;
use warnings;
use Carp qw(croak);
use ArangoDB::Connection;
use ArangoDB::Collection;
use ArangoDB::Statement;
use ArangoDB::Constants qw(:api);

our $VERSION = '0.01_01';
$VERSION = eval $VERSION;

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
        $self->_server_error_handler( $@, "Failed to create collection($name)" );
    }
    return $coll;
}

sub find {
    my ( $self, $name ) = @_;
    my $api = API_COLLECTION . '/' . $name;
    my $res = eval { $self->{connection}->http_get($api); };
    if ($@) {
        $self->_server_error_handler( $@, "Failed to get collection: $name", 1 );
    }
    return $res ? ArangoDB::Collection->new( $self->{connection}, $res ) : undef;
}

sub collection {
    my ( $self, $name ) = @_;
    return $self->find($name) || $self->create($name);
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
        $self->_server_error_handler( $@, 'Failed to get collections' );
    }
    return \@colls;
}

sub drop {
    my ( $self, $name ) = @_;
    my $api = API_COLLECTION . '/' . $name;
    eval { $self->{connection}->http_delete($api); };
    if ($@) {
        $self->_server_error_handler( $@, "Failed to drop collection($name)", 1 );
    }
}

sub truncate {
    my ( $self, $name ) = @_;
    my $coll = $self->collection($name);
    if ($coll) {
        $coll->truncate;
    }
}

sub query {
    my ( $self, $query ) = @_;
    return ArangoDB::Statement->new( $self->{connection}, $query );
}

sub _server_error_handler {
    my ( $self, $error, $message, $ignore_404 ) = @_;
    if ( ref($error) && $error->isa('ArangoDB::ServerException') ) {
        return if $ignore_404 && $error->code == 404;
        $message .= ':' . ( $error->detail->{errorMessage} || q{} );
    }
    croak $message;
}

sub AUTOLOAD {
    my $self = shift;
    my $name = our $AUTOLOAD;
    $name =~ s/.*:://o;
    return if $name eq 'DESTROY';
    return $self->collection($name);
}

BEGIN {
    *get_index  = \&ArangoDB::Collection::get_index;
    *drop_index = \&ArangoDB::Collection::drop_index;
}

1;
__END__

=head1 NAME

ArangoDB - ArangoDB client for Perl.

=head1 SYNOPSIS

  use ArangoDB;
  
  my $db = ArangoDB->new({
      host       => 'localhost',
      port       => 8529,
      keep_alive => 1,
  });
  
  # Find or create collection
  my $foo = $db->foo;
  
  # Create new document
  $foo->save({ x => 42, y => { a => 1, b => 2, } });
  $foo->save({ x => 1, y => { a => 1, b => 10, } });
  $foo->name('new_name'); # rename the collection
  
  # Create hash index.
  $foo->create_hash_index([qw/x y/]);
  
  # Simple query
  my $cursor = $db->new_name->by_example({ b => 2 });
  while( my $doc = $cursor->next ){
      # do something
  }
  
  # AQL
  my $cur = $db->query( 
      'FOR u IN users FILTER u.age > @age SORT u.name ASC RETURN u' 
  )->bind( { age => 19 } )->execute();

=head1 DESCRIPTION

ArangoDB is ArangoDB client for Perl.

=head1 SUPPORT API VERSION

This supports ArangoDB API implementation 1.01.

=head1 METHODS

=head2 new($options)

Constructor.
$options is HASH reference.The attributes of $options are:

=over 4

=item host

Hostname or IP address of ArangoDB server.
Default: localhost

=item port

Port number of ArangoDB server.
Default: 8529

=item timeout

Seconds of HTTP connection timeout.

=item auth_user

User name for authentication

=item auth_passwd

Password for authentication

=item auth_type

Authentication method.
Supporting "Basic" only.

=item keep_alive

If it is true, use HTTP Keep-Alive connection.
Default: false

=item proxy

HTTP proxy.

=back

=head2 create($name)

Create new collection.
Returns instance of L<ArangoDB::Collection>.

=head2 find($name)

Get a Collection based on $name.
Returns instance of L<ArangoDB::Collection>.
If the collection does not exist, returns C<undef>. 

=head2 collection($name)

Get or create a Collection based on $name.
If the Collection $name does not exist, Create it.

=head2 collections()

Get all collections.
Returns ARRAY reference.

=head2 drop($name)

Drop collection.
Same as `$db->collection($name)->drop();`.

=head2 truncate($name)

Truncate a collection.
Same as `$db->collection($name)->truncate();`.

=head2 get_index($index_id)

Returns instance of ArangoDB::Index::*.

=head2 drop_index($index_id)

Drop a index.

=head2 query($query)

Returns instance of L<ArangoDB::Statement>.

=head1 AUTHOR

Hideaki Ohno E<lt>hide.o.j55 {at} gmail.comE<gt>

=head1 SEE ALSO

ArangoDB websie L<http://www.arangodb.org/>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
