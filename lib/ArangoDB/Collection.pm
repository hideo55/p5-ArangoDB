package ArangoDB::Collection;
use strict;
use warnings;
use JSON;
use Carp qw(croak);
use Scalar::Util qw(weaken);
use Data::Util ();
use Class::Accessor::Lite ( ro => [qw/id status/], );
use ArangoDB::Constants qw(:api :status);
use ArangoDB::Document;

=pod

=head1 NAME

ArangoDB::Collection

=head1 DESCRIPTION

A instance of ArangoDB collection.

=head1 METHODS

=over 4

=head2 new($connection, $collection_info)

Constructor.

=cut

sub new {
    my ( $class, $conn, $raw_collection ) = @_;
    my $self = bless {}, $class;
    $self->{connection} = $conn;
    weaken( $self->{connection} );
    map { $self->{$_} = $raw_collection->{$_} } qw(id name status);
    return $self;
}

=pod

=head2 is_newborn()

Return true if status of the collection is 'new born'.

=cut

sub is_newborn {
    $_[0]->{status} == NEWBORN;
}

=pod

=head2 is_unloaded()

Return true if status of the collection is 'unloaded'.

=cut

sub is_unloaded {
    $_[0]->{status} == UNLOADED;
}

=pod

=head2 is_loaded()

Return true if status of the collection is 'loaded'.

=cut

sub is_loaded {
    $_[0]->{status} == LOADED;
}

=pod

=head2 is_being_unloaded()

Return true if status of the collection is 'being unloaded'.

=cut

sub is_being_unloaded {
    return $_[0]->{status} == BEING_UNLOADED;
}

=pod

=head2 is_deleted()

Return true if status of the collection is 'deleted'.

=cut

sub is_deleted {
    my $self = shift;
    return $_[0]->{status} == DELETED;
}

=pod

=head2 is_corruped()

Return true if status of the collection is invalid.

=cut

sub is_corrupted {
    my $self = shift;
    return $_[0]->{status} >= CORRUPTED;
}

=pod

=head2 name()

Returns name of collection.

=cut

sub name {
    my ( $self, $_name ) = @_;
    if ($_name) {    #rename
        $self->_put_to_this( 'rename', { name => $_name } );
        $self->{name} = $_name;
    }
    return $self->{name};
}

=pod

=head2 count()

Returns number of documents in the collection.

=cut

sub count {
    my $self = shift;
    my $res  = $self->_get_from_this('count');
    return $res->{count};
}

=pod

=head2 figure($type)

Returns number of documents and additional statistical information about the collection.

$type is key name of figures.The key names are: 

=over 4

=item count

The number of documents inside the collection.

=item alive-count

The number of living documents.

=item alive-size

 The total size in bytes used by all living documents.

=item dead-count

The number of dead documents.

=item dead-size

The total size in bytes used by all dead documents.

=item dead-deletion

The total number of deletion markers.

=item datafiles-count

The number of active datafiles.

=item datafiles-fileSize

The total filesize of datafiles.

=item journals-count

The number of journal files.

=item journals-fileSize

The total filesize of journal files.

=item journalSize

 The maximal size of the journal in bytes.

=back

=cut

sub figure {
    my ( $self, $type ) = @_;
    my $res = $self->_get_from_this('figures');
    if ( defined $type ) {
        return $res->{count} if $type eq 'count';
        return $res->{journalSize} if $type eq 'journalSize';
        my ( $area, $name ) = split( '-', $type );
        return $res->{figures}{$area}{$name} if defined $area && defined $name;
    }
    else {
        return $res->{figures};
    }
    return;
}

=pod

=head2 wait_for_sync($boolean)

Set or get the property 'wait_for_sync' of the collection.

=cut

sub wait_for_sync {
    my $self = shift;
    if ( @_ > 0 ) {
        my $val = $_[0] ? JSON::true : JSON::false;
        my $res = $self->_put_to_this( 'properties', { waitForSync => $val } );
    }
    else {
        my $res = $self->_get_from_this('properties');
        my $ret = $res->{waitForSync} eq 'true' ? 1 : 0;
        return $ret;
    }
}

=pod

=head2 drop()

Drop the collection.

=cut

sub drop {
    my $self = shift;
    my $api  = API_COLLECTION . '/' . $self->{id};
    eval { $self->{connection}->http_delete($api); };
    if ($@) {
        $self->_server_error_handler( $@, 'Failed to drop the collection(%s)' );
    }
}

=pod

=head2 truncate()

Truncate the collection.

=cut

sub truncate {
    my $self = shift;
    eval {
        my $res = $self->_put_to_this('truncate');
        $self->{status} = $res->{status};
    };
    if ($@) {
        $self->_server_error_handler( $@, 'Failed to truncate the collection(%s)' );
    }
}

=pod

=head2 load()

Load the collection.

=cut

sub load {
    my $self = shift;
    my $res  = $self->_put_to_this('load');
    $self->{status} = $res->{status};
}

=pod

=head2 unload()

Unload the collection.

=cut

sub unload {
    my $self = shift;
    my $res  = $self->_put_to_this('unload');
    $self->{status} = $res->{status};
}

=pod

=head2 all($options)
 
Send 'all' simple query. 
Returns all documents of in the collection.

$options is query option(HASH reference).The attributes of $options are:

=over 4

=item limit

The maximal amount of documents to return. (optional)

=item skip

The documents to skip in the query. (optional)

=back 

=cut

sub all {
    my ( $self, $options ) = @_;
    $options ||= {};
    my $data = { collection => $self->{name} };
    map { $data->{$_} = $options->{$_} } grep { exists $options->{$_} } qw(limit skip);
    my $res = eval { $self->{connection}->http_put( API_SIMPLE_ALL, $data ) };
    if ($@) {
        $self->_server_error_handler( $@, 'Failed to call Simple API(all) for the collection(%s)' );
    }
    return $self->_documents_from_response( $res->{result} );
}

=pod

=item by_example($example,$options)

Send 'by_example' simple query. 
This will find all documents matching a given example.

$example is the exmaple.
$options is query option(HASH reference).The attributes of $options are:

=over 4

=item limit

The maximal amount of documents to return. (optional)

=item skip

The documents to skip in the query. (optional)

=back 

=cut

sub by_example {
    my ( $self, $example, $options ) = @_;
    $options ||= {};
    my $data = { collection => $self->{name}, example => $example };
    map { $data->{$_} = $options->{$_} } grep { exists $options->{$_} } qw(limit skip);
    my $res = eval { $self->{connection}->http_put( API_SIMPLE_EXAMPLE, $data ) };
    if ($@) {
        $self->_server_error_handler( $@, 'Failed to call Simple API(by_example) for the collection(%s)' );
    }
    return $self->_documents_from_response( $res->{result} );
}

=pod

=head2 first_example($example)

Send 'first_example' simple query. 
This will return the first document matching a given example.

$example is the exmaple.

=cut

sub first_example {
    my ( $self, $example ) = @_;
    my $data = { collection => $self->{name}, example => $example };
    my $res = eval { $self->{connection}->http_put( API_SIMPLE_FIRST, $data ) };
    if ($@) {
        $self->_server_error_handler( $@, 'Failed to call Simple API(first_example) for the collection(%s)' );
    }
    return $self->_documents_from_response( $res->{result} );
}

=pod

=head2 range($attr,$lower,$upper,$options)

Send 'range' simple query. 
It looks for documents in the collection with attribute between two values.

$attr is the attribute path to check.
$lower is the lower bound.
$upper is the upper bound.
$options is query option(HASH reference).The attributes of $options are:

=over 4

=item closed

If true, use intervall including left and right, otherwise exclude right, but include left

=item limit

The maximal amount of documents to return. (optional)

=item skip

The documents to skip in the query. (optional)

=back 

=cut

sub range {
    my ( $self, $attr, $lower, $upper, $options ) = @_;
    $options ||= {};
    my $data = { collection => $self->{name}, attribute => $attr, left => $lower, right => $upper, };
    map { $data->{$_} = $options->{$_} } grep { exists $options->{$_} } qw(closed limit skip);
    if ( exists $data->{closed} ) {
        $data->{closed} = $data->{closed} ? JSON::true : JSON::false;
    }
    my $res = eval { $self->{connection}->http_put( API_SIMPLE_RANGE, $data ) };
    if ($@) {
        $self->_server_error_handler( $@, 'Failed to call Simple API(range) for the collection(%s)' );
    }
    return $self->_documents_from_response( $res->{result} );
}

=pod

=head2 near($latitude,$longitude,$options)

Send 'near' simple query. 
The default will find at most 100 documents near a given coordinate. 
The returned list is sorted according to the distance, with the nearest document coming first.

$latitude is the latitude of the coordinate.
$longitude is longitude of the coordinate.
$options is query option(HASH reference).The attributes of $options are:

=over 4

=item distance

If given, the attribute key used to store the distance. (optional)

=item limit

The maximal amount of documents to return. (optional)

=item skip

The documents to skip in the query. (optional)

=item geo

If given, the identifier of the geo-index to use. (optional)

=back 

=cut

sub near {
    my ( $self, $latitude, $longitude, $options ) = @_;
    $options ||= {};
    my $data = { collection => $self->{name}, latitude => $latitude, longitude => $longitude, };
    map { $data->{$_} = $options->{$_} } grep { exists $options->{$_} } qw(distance limit skip geo);
    my $res = eval { $self->{connection}->http_put( API_SIMPLE_NEAR, $data ) };
    if ($@) {
        $self->_server_error_handler( $@, 'Failed to call Simple API(near) for the collection(%s)' );
    }
    return $self->_documents_from_response( $res->{result} );
}

=pod

=head2 within($latitude,$longitude,$radius,$options)

Send 'within' simple query. 
This will find all documents with in a given radius around the coordinate (latitude, longitude).
The returned list is sorted by distance.

$latitude is the latitude of the coordinate.
$longitude is longitude of the coordinate.
$radius is the maximal radius.
$options is query option(HASH reference).The attributes of $options are:

=over 4

=item distance

If given, the attribute key used to store the distance. (optional)

=item limit

The maximal amount of documents to return. (optional)

=item skip

The documents to skip in the query. (optional)

=item geo

If given, the identifier of the geo-index to use. (optional)

=cut

sub within {
    my ( $self, $latitude, $longitude, $radius, $options ) = @_;
    $options ||= {};
    my $data = { collection => $self->{name}, latitude => $latitude, longitude => $longitude, radius => $radius, };
    map { $data->{$_} = $options->{$_} }
        grep { exists $options->{$_} } qw(distance limit skip geo);
    my $res = eval { $self->{connection}->http_put( API_SIMPLE_WITHIN, $data ) };
    if ($@) {
        $self->_server_error_handler( $@, 'Failed to call Simple API(within) for the collection(%s)' );
    }
    return $self->_documents_from_response( $res->{result} );
}

=pod

=head2 document($doc_id)

Get documnet in the collection.

=cut

sub document {
    my ( $self, $doc_id ) = @_;
    $doc_id = defined $doc_id ? $doc_id : q{};
    my $api = API_DOCUMENT . '/' . $doc_id;
    my $res = eval { $self->{connection}->http_get($api) };
    if ($@) {
        $self->_server_error_handler( $@, "Failed to get the document($doc_id) in the collection(%s)" );
    }
    return ArangoDB::Document->new($res);
}

=pod

=head2 save($data)

Save document to the collection.

=cut

sub save {
    my ( $self, $data ) = @_;
    my $api = API_DOCUMENT . '?collection=' . $self->{id};
    my $doc = eval {
        my $res = $self->{connection}->http_post( $api, $data );
        $self->document( $res->{_id} );
    };
    if ($@) {
        $self->_server_error_handler( $@, 'Failed to save the new document to the collection(%s)' );
    }
    return $doc;
}

=pod

=head2 replace($doc_id,$data)

Replace document in the collection.

=cut

sub replace {
    my ( $self, $doc_id, $data ) = @_;
    $doc_id = defined $doc_id ? $doc_id : q{};
    my $api = API_DOCUMENT . '/' . $doc_id . '?policy=last';
    eval { $self->{connection}->http_put( $api, $data ); };
    if ($@) {
        $self->_server_error_handler( $@, "Failed to replace the document($doc_id) in the collection(%s)" );
    }
    return $self->document($doc_id);
}

=pod

=head2 remove($doc_id)

Remove document in the collection.

=cut

sub remove {
    my ( $self, $doc_id ) = @_;
    $doc_id = defined $doc_id ? $doc_id : q{};
    my $api = API_DOCUMENT . '/' . $doc_id;
    my $res = eval { $self->{connection}->http_delete($api) };
    if ($@) {
        $self->_server_error_handler( $@, "Failed to remove the document($doc_id) in the collection(%s)" );
    }
    return;
}

=pod

=head2 any_edges()

=head2 in_edges()

=head2 out_edges()

=cut

for my $direction (qw/any in out/) {
    my $sub = sub {
        my ( $self, $vertex ) = @_;
        return $self->_get_edges( $vertex, $direction );
    };
    Data::Util::install_subroutine( __PACKAGE__, "${direction}_edges " => $sub );
}

=pod

=head2 edge($edge_id)

Get edge in the collection.

=cut

sub edge {
    my ( $self, $edge_id ) = @_;
    $edge_id = defined $edge_id ? $edge_id : q{};
    my $api = API_EDGE . '/' . $edge_id;
    my $res = eval { $self->{connection}->http_get($api) };
    if ($@) {
        $self->_server_error_handler( $@, "Failed to get the edge($edge_id) in the collection(%s)" );
    }
    return ArangoDB::Edge->new($res);
}

=pod

=head2 save_edge($from,$to,$data)

Save edge to the collection.

=cut

sub save_edge {
    my ( $self, $from, $to, $data ) = @_;
    my $api = API_EDGE . '?collection=' . $self->{id} . '&from=' . $from . '&to=' . $to;
    my $res = eval { $self->{connection}->http_post( $api, $data ) };
    if ($@) {
        $self->_server_error_handler( $@, "Failed to save the new edge to the collection(%s)" );
    }
    return $self->edge( $res->{_id} );
}

=pod

=head2 replace_edge($edge_id)

Replace edge in the collection.

=cut

sub replace_edge {
    my ( $self, $edge_id ) = @_;
    $edge_id = defined $edge_id ? $edge_id : q{};
    my $api = API_EDGE . '/' . $edge_id;
    my $res = eval { $self->{connection}->http_get($api) };
    if ($@) {
        $self->_server_error_handler( $@, "Failed to replace the edge($edge_id) in the collection(%s)" );
    }
    return $self->edge($edge_id);
}

=pod

=head2 remove_edge($edge_id)

Remove edge in the collection.

=cut

sub remove_edge {
    my ( $self, $edge_id ) = @_;
    $edge_id = defined $edge_id ? $edge_id : q{};
    my $api = API_EDGE . '/' . $edge_id;
    my $res = eval { $self->{connection}->http_delete($api) };
    if ($@) {
        $self->_server_error_handler( $@, "Failed to delete the edge($edge_id) in the collection(%s)" );
    }
}

sub _get_from_this {
    my ( $self, $path ) = @_;
    my $api = API_COLLECTION . '/' . $self->{id} . '/' . $path;
    my $res = eval { $self->{connection}->http_get($api) };
    if ($@) {
        $self->_server_error_handler( $@, "Failed to get the property($path) of the collection(%s)" );
    }
    return $res;
}

sub _put_to_this {
    my ( $self, $path, $params ) = @_;
    my $api = API_COLLECTION . '/' . $self->{id} . '/' . $path;
    my $res = eval { $self->{connection}->http_put( $api, $params ) };
    if ($@) {
        $self->_server_error_handler( $@, "Failed to update the property($path) of the collection(%s)" );
    }
    return $res;
}

sub _documents_from_respose {
    my ( $self, $res ) = @_;
    my @docs = map { ArangoDB::Document->new($_) } @$res;
    return \@docs;
}

sub _get_edges {
    my ( $self, $vertex, $direction ) = @_;
    my $api = API_EDGE . '/' . $self->{id} . '?vertex=' . $vertex . '&direction=' . $direction;
    my $res = eval { $self->{connection}->http_get($api) };
    if ($@) {
        $self->_server_error_handler( $@,
            'Failed to get edges(' . join( ',', $self->{id}, $vertex, $direction ) . ') in the collection(%s)' );
    }
    my @edges = map { ArangoDB::Edge->new($_) } @{ $res->{edges} };
    return \@edges;
}

sub _server_error_handler {
    my ( $self, $error, $message ) = @_;
    my $msg = sprintf( $message, $self->{name} );
    if ( ref($error) && $error->isa('ArangoDB::ServerException') ) {
        $msg .= ':' . ( $error->detail->{errorMessage} || q{} );
    }
    croak $msg;
}

1;
__END__

=pod

=head1 AUTHOR

Hideaki Ohno E<lt>hide.o.j55 {at} gmail.comE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
