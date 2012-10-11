package ArangoDB::Collection;
use strict;
use warnings;
use JSON;
use Carp qw(croak);
use Scalar::Util qw(weaken);
use Class::Accessor::Lite ( ro => [qw/id status/], );
use ArangoDB::Constants qw(:api :status);
use ArangoDB::Document;
use ArangoDB::Edge;
use ArangoDB::Index::Primary;
use ArangoDB::Index::Hash;
use ArangoDB::Index::Skiplist;
use ArangoDB::Index::Geo;
use ArangoDB::Index::CapConstraint;
use ArangoDB::Cursor;
use ArangoDB::ClientException;
use overload
    q{""}    => sub { shift->id },
    fallback => 1;

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
    for my $key (qw/id name status/) {
        $self->{$key} = $raw_collection->{$key};
    }
    return $self;
}

=pod

=head2 id()

Returns identifer of the collection.

=head2 status()

Returns status of the collection.

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
    $_[0]->{status} == BEING_UNLOADED;
}

=pod

=head2 is_deleted()

Return true if status of the collection is 'deleted'.

=cut

sub is_deleted {
    $_[0]->{status} == DELETED;
}

=pod

=head2 is_corruped()

Return true if status of the collection is invalid.

=cut

sub is_corrupted {
    return $_[0]->{status} >= CORRUPTED;
}

=pod

=head2 name($name)

Returns name of collection.
If $name is set, rename the collection.

=cut

sub name {
    my ( $self, $name ) = @_;
    if ($name) {    #rename
        $self->_put_to_this( 'rename', { name => $name } );
        $self->{name} = $name;
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
        return $res->{count}       if $type eq 'count';
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

=head2 all_document_ids()

Returns list of document id in the collection.

=cut

sub all_document_ids {
    my $self = shift;
    my $api  = API_DOCUMENT . '?collection=' . $self->{id};
    my $res  = eval { $self->{connection}->http_get($api) };
    if ($@) {
        $self->_server_error_handler( $@, "Failed to get the all document ids in the collection(%s)" );
    }
    my @doc_ids = map {m|^/_api/document/(.+)$|} @{ $res->{documents} };
    return \@doc_ids;
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

=head2 bulk_import($header,$body)

Import multiple documents at once.

$header is ARRAY reference of attribute names.
$body is ARRAY reference of document values.

Example

    $collection->bulk_import(
        [qw/fistsName lastName age gender/],
        [
            [ "Joe", "Public", 42, "male" ],
            [ "Jane", "Doe", 31, "female" ],
        ]
    );    

=cut

sub bulk_import {
    my ( $self, $header, $body ) = @_;
    croak ArangoDB::ClientException->new('2nd parameter must be ARRAY reference.')
        unless $body && ref($body) eq 'ARRAY';
    my $api  = API_IMPORT . '?collection=' . $self->{id};
    my $data = join "\n", map { encode_json($_) } ( $header, @$body );
    my $res  = eval { $self->{connection}->http_post_raw( $api, $data ); };
    if ($@) {
        $self->_server_error_handler( $@, 'Failed to bulk import to the collection(%s)' );
    }
    return $res;
}

=pod

=head2 bulk_import_self_contained($documents)

Import multiple self-contained documents at once.

$documents is the ARRAY reference of documents.

=cut

sub bulk_import_self_contained {
    my ( $self, $documents ) = @_;
    croak ArangoDB::ClientException->new('Parameter must be ARRAY reference.')
        unless $documents && ref($documents) eq 'ARRAY';
    my $api  = API_IMPORT . '?type=documents&collection=' . $self->{id};
    my $data = join "\n", map { encode_json($_) } @$documents;
    my $res  = eval { $self->{connection}->http_post_raw( $api, $data ); };
    if ($@) {
        $self->_server_error_handler( $@, 'Failed to bulk import to the collection(%s)' );
    }
    return $res;
}

=pod

=head2 update($doc_id,$data)

Update document in the collection.

=cut

sub update {
    my ( $self, $doc_id, $data ) = @_;
    $doc_id = defined $doc_id ? $doc_id : q{};
    my $api = API_DOCUMENT . '/' . $doc_id;
    eval { $self->{connection}->http_put( $api, $data ); };
    if ($@) {
        $self->_server_error_handler( $@, "Failed to update the document($doc_id) in the collection(%s)" );
    }
    return $self->document($doc_id);
}

=pod

=head2 delete($doc_id)

Delete document in the collection.

=cut

sub delete {
    my ( $self, $doc_id ) = @_;
    $doc_id = defined $doc_id ? $doc_id : q{};
    my $api = API_DOCUMENT . '/' . $doc_id;
    my $res = eval { $self->{connection}->http_delete($api) };
    if ($@) {
        $self->_server_error_handler( $@, "Failed to delete the document($doc_id) in the collection(%s)" );
    }
    return;
}

=pod

=head2 any_edges($vertex)

Returns the list of edges starting or ending in the vertex identified by $vertex.


=cut

sub any_edges {
    my ( $self, $vertex ) = @_;
    return $self->_get_edges( $vertex, 'any' );
}

=pod

=head2 in_edges($vertex)

Returns the list of edges ending in the vertex identified by $vertex.

=cut

sub in_edges {
    my ( $self, $vertex ) = @_;
    return $self->_get_edges( $vertex, 'in' );
}

=pod

=head2 out_edges($vertex)

Returns the list of edges starting in the vertex identified by $vertex.

=cut

sub out_edges {
    my ( $self, $vertex ) = @_;
    return $self->_get_edges( $vertex, 'out' );
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

=head2 update_edge($edge_id,$data)

Update edge in the collection.

=cut

sub update_edge {
    my ( $self, $edge_id, $data ) = @_;
    $edge_id = defined $edge_id ? $edge_id : q{};
    my $api = API_EDGE . '/' . $edge_id;
    eval { $self->{connection}->http_put( $api, $data ) };
    if ($@) {
        $self->_server_error_handler( $@, "Failed to update the edge($edge_id) in the collection(%s)" );
    }
    return $self->edge($edge_id);
}

=pod

=head2 delete_edge($edge_id)

Remoce edge in the collection.

=cut

sub delete_edge {
    my ( $self, $edge_id ) = @_;
    $edge_id = defined $edge_id ? $edge_id : q{};
    my $api = API_EDGE . '/' . $edge_id;
    my $res = eval { $self->{connection}->http_delete($api) };
    if ($@) {
        $self->_server_error_handler( $@, "Failed to delete the edge($edge_id) in the collection(%s)" );
    }
    return;
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
    for my $key ( grep { exists $options->{$_} } qw{limit skip} ) {
        $data->{$key} = $options->{$key};
    }
    my $res = eval { $self->{connection}->http_put( API_SIMPLE_ALL, $data ) };
    if ($@) {
        $self->_server_error_handler( $@, 'Failed to call Simple API(all) for the collection(%s)' );
    }
    return ArangoDB::Cursor->new( $self->{connection}, $res );
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
    return ArangoDB::Cursor->new( $self->{connection}, $res );
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
    return ArangoDB::Document->new( $res->{document} );
}

=pod

=head2 range($attr,$lower,$upper,$options)

Send 'range' simple query. 
It looks for documents in the collection with attribute between two values.

Note: You must declare a skip-list index on the attribute in order to be able to use a range query.

$attr is the attribute path to check.
$lower is the lower bound.
$upper is the upper bound.
$options is query option(HASH reference).The attributes of $options are:

=over 4

=item closed

If true, use intervall including $lower and $upper, otherwise exclude $upper, but include $lower

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
    return ArangoDB::Cursor->new( $self->{connection}, $res );
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
    return ArangoDB::Cursor->new( $self->{connection}, $res );
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
    return ArangoDB::Cursor->new( $self->{connection}, $res );
}

=pod

=head2 ensure_hash_index($fileds)

Create hash index for the collection.

$fileds is the field of index.

=cut

sub ensure_hash_index {
    my ( $self, $fields, $unique ) = @_;
    my $api  = API_INDEX . '?collection=' . $self->{id};
    my $data = { type => 'hash', unique => JSON::false, fields => $fields, };
    my $res  = eval { $self->{connection}->http_post( $api, $data ) };
    if ($@) {
        $self->_server_error_handler( $@, 'Failed to create hash index on the collection(%s)' );
    }
    return ArangoDB::Index::Hash->new($res);
}

=pod

=head2 ensure_unique_constraint($fileds)

Create unique hash index for the collection.

$fileds is the field of index.

=cut

sub ensure_unique_constraint {
    my ( $self, $fields ) = @_;
    my $api  = API_INDEX . '?collection=' . $self->{id};
    my $data = { type => 'hash', unique => JSON::true, fields => $fields, };
    my $res  = eval { $self->{connection}->http_post( $api, $data ) };
    if ($@) {
        $self->_server_error_handler( $@, 'Failed to create unique hash index on the collection(%s)' );
    }
    return ArangoDB::Index::Hash->new($res);
}

=pod

=head2 ensure_skiplist($fileds)

Create skiplist index for the collection.

$fileds is the field of index.

=cut

sub ensure_skiplist {
    my ( $self, $fields ) = @_;
    my $api  = API_INDEX . '?collection=' . $self->{id};
    my $data = { type => 'skiplist', unique => JSON::false, fields => $fields, };
    my $res  = eval { $self->{connection}->http_post( $api, $data ) };
    if ($@) {
        $self->_server_error_handler( $@, 'Failed to create skiplist index on the collection(%s)' );
    }
    return ArangoDB::Index::Skiplist->new($res);
}

=pod

=head2 ensure_unique_skiplist($fileds)

Create unique skiplist index for the collection.

$fileds is the field of index.

=cut

sub ensure_unique_skiplist {
    my ( $self, $fields, $unique ) = @_;
    my $api  = API_INDEX . '?collection=' . $self->{id};
    my $data = { type => 'skiplist', unique => JSON::true, fields => $fields, };
    my $res  = eval { $self->{connection}->http_post( $api, $data ) };
    if ($@) {
        $self->_server_error_handler( $@, 'Failed to create unique skiplist index on the collection(%s)' );
    }
    return ArangoDB::Index::Skiplist->new($res);
}

=pod

=head2 ensure_geo_index($fileds,$is_geojson)

Create geo index for the collection.

$fileds is the field of index.
$is_geojson is boolean flag. If it is true, then the order within the list is longitude followed by latitude. 

=cut

sub ensure_geo_index {
    my ( $self, $fields, $is_geojson ) = @_;
    my $api  = API_INDEX . '?collection=' . $self->{id};
    my $data = {
        type       => 'geo',
        fields     => $fields,
        constraint => JSON::false,
        geoJson    => $is_geojson ? JSON::true : JSON::false,
    };
    my $res = eval { $self->{connection}->http_post( $api, $data ) };
    if ($@) {
        $self->_server_error_handler( $@, 'Failed to create geo index on the collection(%s)' );
    }
    return ArangoDB::Index::Geo->new($res);
}

=pod

=head2 ensure_geo_constraint($fileds,$ignore_null)

It works like ensure_geo_index() but requires that the documents contain a valid geo definition.

$fileds is the field of index.
$ignore_null is boolean flag. If it is true, then documents with a null in location or at least one null in latitude or longitude are ignored.

=back

=cut

sub ensure_geo_constraint {
    my ( $self, $fields, $ignore_null ) = @_;
    my $api  = API_INDEX . '?collection=' . $self->{id};
    my $data = {
        type       => 'geo',
        fields     => $fields,
        constraint => JSON::true,
        ignoreNull => $ignore_null ? JSON::true : JSON::false,
    };
    my $res = eval { $self->{connection}->http_post( $api, $data ) };
    if ($@) {
        $self->_server_error_handler( $@, 'Failed to create geo constraint on the collection(%s)' );
    }
    return ArangoDB::Index::Geo->new($res);
}

=pod

=head2 ensure_cap_constraint($size)

Create cap constraint for the collection.

=cut

sub ensure_cap_constraint {
    my ( $self, $size ) = @_;
    my $api  = API_INDEX . '?collection=' . $self->{id};
    my $data = { type => 'cap', size => $size, };
    my $res  = eval { $self->{connection}->http_post( $api, $data ) };
    if ($@) {
        $self->_server_error_handler( $@, 'Failed to create cap constraint on the collection(%s)' );
    }
    return ArangoDB::Index::CapConstraint->new($res);
}

=pod

=head2 get_index($index_id)

Returns index object.

=cut

sub get_index {
    my ( $self, $index_id ) = @_;
    $index_id = defined $index_id ? $index_id : q{};
    my $api = API_INDEX . '/' . $index_id;
    my $res = eval { $self->{connection}->http_get($api) };
    if ($@) {
        $self->_server_error_handler( $@, 'Failed to get the index($index_id) on the collection(%s)' );
    }
    return _get_index_instance($res);
}

=pod

=head2 drop_index($index_id)

Drop the index.

=cut

sub drop_index {
    my ( $self, $index_id ) = @_;
    $index_id = defined $index_id ? $index_id : q{};
    my $api = API_INDEX . '/' . $index_id;
    my $res = eval { $self->{connection}->http_delete($api) };
    if ($@) {
        $self->_server_error_handler( $@, 'Failed to drop the index($index_id)' );
    }
    return;
}

=pod

=head2 indexes()

Returns list of indexes of the collection.

=cut

sub indexes {
    my $self = shift;
    my $api  = API_INDEX . '?collection=' . $self->{id};
    my $res  = eval { $self->{connection}->http_get($api) };
    if ($@) {
        $self->_server_error_handler( $@, 'Failed to get the index($index_id) on the collection(%s)' );
    }
    my @indexes = map { _get_index_instance($_) } @{ $res->{indexes} };
    return \@indexes;
}

# Get property of the collection.
sub _get_from_this {
    my ( $self, $path ) = @_;
    my $api = API_COLLECTION . '/' . $self->{id} . '/' . $path;
    my $res = eval { $self->{connection}->http_get($api) };
    if ($@) {
        $self->_server_error_handler( $@, "Failed to get the property($path) of the collection(%s)" );
    }
    return $res;
}

# Set property of the collection.
sub _put_to_this {
    my ( $self, $path, $params ) = @_;
    my $api = API_COLLECTION . '/' . $self->{id} . '/' . $path;
    my $res = eval { $self->{connection}->http_put( $api, $params ) };
    if ($@) {
        $self->_server_error_handler( $@, "Failed to update the property($path) of the collection(%s)" );
    }
    return $res;
}

sub _get_edges {
    my ( $self, $vertex, $direction ) = @_;
    my $api = API_EDGES . '/' . $self->{id} . '?vertex=' . $vertex . '&direction=' . $direction;
    my $res = eval { $self->{connection}->http_get($api) };
    if ($@) {
        $self->_server_error_handler( $@,
            'Failed to get edges(' . join( ',', $self->{id}, $vertex, $direction ) . ') in the collection(%s)' );
    }
    my @edges = map { ArangoDB::Edge->new($_) } @{ $res->{edges} };
    return \@edges;
}

# get instance of index
sub _get_index_instance {
    my $index = shift;
    my $type = $index->{type} || q{};
    if ( $type eq 'primary' ) {
        return ArangoDB::Index::Primary->new($index);
    }
    elsif ( $type eq 'hash' ) {
        return ArangoDB::Index::Hash->new($index);
    }
    elsif ( $type eq 'skiplist' ) {
        return ArangoDB::Index::Skiplist->new($index);
    }
    elsif ( $type eq 'cap' ) {
        return ArangoDB::Index::CapConstraint->new($index);
    }
    else {
        return ArangoDB::Index::Geo->new($index);
    }
}

# Handling server error
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
