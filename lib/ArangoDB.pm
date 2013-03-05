package ArangoDB;
use strict;
use warnings;
use utf8;
use 5.010000;
use Carp qw(croak);
use Module::Load ();
use ArangoDB::Connection;
use ArangoDB::Collection;
use ArangoDB::Statement;
use ArangoDB::Constants qw(:api :collection_type);
use constant {
    _COLLECTION_CLASS => q{},
    _DOCUMENT_CLASS   => q{},
    _EDGE_CLASS       => q{},
};
use overload '&{}' => sub {
    my $self = shift;
    return sub { $self->collection( $_[0] ) };
    },
    fallback => 1;

our $VERSION = '0.08';
$VERSION = eval $VERSION;

our $DEFAULT_API_VERSION = '1.0';
my %CLASS = (
    '1.0' => 'ArangoDB::API::V1_0',
    '1.1' => 'ArangoDB::API::V1_1',
    '1.2' => 'ArangoDB::API::V1_2',
);

sub new {
    my ( $class, $options ) = @_;
    my $connection = ArangoDB::Connection->new($options);
    my $api = $options->{api} || $DEFAULT_API_VERSION;
    croak "'api' must be 1.0, 1.1 or 1.2" if !exists $CLASS{$api};
    Module::Load::load( $CLASS{$api} );
    my $instance_class = $CLASS{$api};
    my $self = bless { connection => $connection, }, $instance_class;
    return $self;
}

sub collection {
    my ( $self, $name ) = @_;
    return $self->find($name) || $self->create($name);
}

sub create {
    my ( $self, $name, $_options ) = @_;
    my $params = { ( waitForSync => 0, isSystem => 0, ), %{ $_options || {} } };
    $params->{name} = $name;
    my $coll;
    eval {
        my $res = $self->{connection}->http_post( API_COLLECTION, $params );
        $coll = $self->_COLLECTION_CLASS->new( $self, $res );
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
        $self->_COLLECTION_CLASS->new( $self, $res );
    };
    if ($@) {
        $self->_server_error_handler( $@, "Failed to get collection: $name", 1 );
    }
    return $collection;
}

sub collections {
    my $self = shift;
    my @colls;
    eval {
        my $res = $self->{connection}->http_get(API_COLLECTION);
        @colls = map { $self->_COLLECTION_CLASS->new( $self, $_ ) } @{ $res->{collections} };
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

sub document {
    my ( $self, $doc ) = @_;
    $doc = $doc || q{};
    my $api = API_DOCUMENT . '/' . $doc;
    my $res = eval { $self->{connection}->http_get($api) };
    if ($@) {
        $self->_server_error_handler( $@, "Failed to get the document($doc) in the collection(%s)" );
    }
    return $self->_DOCUMENT_CLASS->new( $self->{connection}, $res );
}

sub edge {
    my ( $self, $edge ) = @_;
    $edge = $edge || q{};
    my $api = API_EDGE . '/' . $edge;
    my $res = eval { $self->{connection}->http_get($api) };
    if ($@) {
        $self->_server_error_handler( $@, "Failed to get the edge($edge) in the collection(%s)" );
    }
    return $self->_EDGE_CLASS->new( $self->{connection}, $res );
}

sub index {
    my ( $self, $index_id ) = @_;
    $index_id = defined $index_id ? $index_id : q{};
    my $api   = API_INDEX . '/' . $index_id;
    my $index = eval {
        my $res  = $self->{connection}->http_get($api);
        my $code = $self->_COLLECTION_CLASS->can('_get_index_instance');
        $self->$code($res);
    };
    if ($@) {
        $self->_server_error_handler( $@, "Failed to get the index($index_id)" );
    }
    return $index;
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

ArangoDB - ArangoDB client for Perl

=head1 SYNOPSIS

  use ArangoDB;
  
  my $db = ArangoDB->new(
      host       => 'localhost',
      port       => 8529,
      keep_alive => 1,
      api        => '1.2'
  );
  
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

This module is an ArangoDB's REST API client for Perl.

ArangoDB is a universal open-source database with a flexible data model for documents, graphs, and key-values.

More information: L<http://www.arangodb.org/>

=head1 SUPPORT API VERSION

This module supports ArangoDB API implementation 1.0, 1.1 and 1.2.

=head1 METHODS

=head2 new($options)

Constructor.

$options is HASH reference.The attributes of $options are:

=over 4

=item api

ArangoDB API version.
Now, supports '1.0', '1.1' and '1.2'.

Default: 1.0

=item host

Hostname or IP address of ArangoDB server. 

Default: localhost

=item port

Port number of ArangoDB server.

Default: 8529

=item timeout

Seconds of HTTP connection timeout.

Default: 300

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

=item inet_aton

A callback function to customize name resolution. Takes two arguments: ($hostname, $timeout_in_seconds).

See L<Furl::HTTP>.

=back

=head2 collection($name)

Get or create a collection based on $name. Returns instance of L<ArangoDB::Collection>.

If the Collection $name does not exist, Create it.

There is shorthand method for get collection instance.

    my $collection = $db->('collection-name');

=head2 create($name,$options)

Create new collection. Returns instance of L<ArangoDB::Collection>.

$options is HASH reference.The attributes of $options are:

=over 4

=item waitForSync

If true then the data is synchronised to disk before returning from a create or update of an document.

Default: false

=item journalSize

The maximal size of a journal or datafile.

=item isSystem

If true, create a system collection. In this case collection-name should start with an underscore.

Default: false

=item type

[API 1.1 or later]

Collection type. ArangoDB::DOCUMENT_COLLECTION or ArangoDB::EDGE_COLLECTION is avaiable.

Default: ArangoDB::DOCUMENT_COLLECTION 

=item isVolatile

[API 1.2 or later]

If true then the collection data is kept in-memory only and not made persistent. 

Default: false

=back

=head2 create_document_collection($name,$options)

Create new document collection. instance of L<ArangoDB::Collection>.
$options is same as create().

=head2 create_edge_collection($name,$options)

Create new edge collection. instance of L<ArangoDB::Collection>.
$options is same as create().

=head2 find($name)

Get a Collection based on $name. Returns instance of L<ArangoDB::Collection>.

If the collection does not exist, returns C<undef>. 

=head2 collections()

Get all collections. Returns ARRAY reference.

=head2 query($query)

Get AQL statement handler. Returns instance of L<ArangoDB::Statement>.

    my $sth = $db->query('FOR u IN users FILTER u.age > @age SORT u.name ASC RETURN u');

=head2 document($doc)

Get documnet in the collection based on $doc. Returns instance of L<ArangoDB::Document>.

=head2 edge($edge)

Get edge in the collection. Returns instance of L<ArangoDB::Edge>.

=head2 index($index_id)

Returns index object.(ArangoDB::Index::*)

See:

=over 4

=item * L<ArangoDB::Index::Primary>

=item * L<ArangoDB::Index::Hash>

=item * L<ArangoDB::Index::SkipList>

=item * L<ArangoDB::Index::Geo>

=item * L<ArangoDB::Index::CapConstraint>

=back

=head1 SEE ALSO

ArangoDB websie L<http://www.arangodb.org/>

=head1 DEVELOPMENT

=head2 Repository

L<https://github.com/hideo55/p5-ArangoDB>

=head1 AUTHOR

Hideaki Ohno E<lt>hide.o.j55 {at} gmail.comE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
