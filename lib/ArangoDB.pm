package ArangoDB;
use strict;
use warnings;
use utf8;
use 5.008001;
use Carp qw(croak);
use ArangoDB::Connection;
use ArangoDB::Collection;
use ArangoDB::Document;
use ArangoDB::Statement;
use ArangoDB::Constants qw(:api);

use overload '&{}' => sub {
    my $self = shift;
    return sub { $self->collection( $_[0] ) };
    },
    fallback => 1;

our $VERSION = '0.03';
$VERSION = eval $VERSION;

sub new {
    my ( $class, $options ) = @_;
    my $self = bless { connection => ArangoDB::Connection->new($options), }, $class;
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
    my $api        = API_COLLECTION . '/' . $name;
    my $collection = eval {
        my $res = $self->{connection}->http_get($api);
        ArangoDB::Collection->new( $self->{connection}, $res );
    };
    if ($@) {
        $self->_server_error_handler( $@, "Failed to get collection: $name", 1 );
    }
    return $collection;
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
  my $foo = $db->('foo');
  
  # Create new document
  $foo->save({ x => 42, y => { a => 1, b => 2, } });
  $foo->save({ x => 1, y => { a => 1, b => 10, } });
  $foo->name('new_name'); # rename the collection
  
  # Create hash index.
  $foo->ensure_hash_index([qw/x y/]);
  
  # Simple query
  my $cursor = $db->('new_name')->by_example({ b => 2 });
  while( my $doc = $cursor->next ){
      # do something
  }
  
  # AQL
  my $cursor2 = $db->query( 
      'FOR u IN users FILTER u.age > @age SORT u.name ASC RETURN u' 
  )->bind( { age => 19 } )->execute();
  my $docs = $cursor2->all;

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

=item keep_alive

If it is true, use HTTP Keep-Alive connection.

Default: false

=item auth_type

Authentication method. Supporting "Basic" only.

=item auth_user

User name for authentication

=item auth_passwd

Password for authentication

=item proxy

Proxy url for HTTP connection.

=back

=head2 create($name)

Create new collection. Returns instance of L<ArangoDB::Collection>.

=head2 find($name)

Get a Collection based on $name. Returns instance of L<ArangoDB::Collection>.

If the collection does not exist, returns C<undef>. 

=head2 collection($name)

Get or create a Collection based on $name.

If the Collection $name does not exist, Create it.

There is shorthand method for get collection instance.

    my $collection = $db->('collection-name');

=head2 collections()

Get all collections. Returns ARRAY reference.

=head2 query($query)

Get AQL statement handler. Returns instance of L<ArangoDB::Statement>.

=head1 AUTHOR

Hideaki Ohno E<lt>hide.o.j55 {at} gmail.comE<gt>

=head1 SEE ALSO

ArangoDB websie L<http://www.arangodb.org/>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
