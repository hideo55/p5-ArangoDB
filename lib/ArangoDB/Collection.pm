package ArangoDB::Collection;
use strict;
use warnings;
use Scalar::Util qw(weaken);
use Data::Util ();
use JSON;
use Class::Accessor::Lite ( ro => [qw/id status/], );
use ArangoDB::Constants qw(:api :status);
use ArangoDB::Document;

=pod

=head1 NAME

ArangoDB::Collection

=head1 METHODS

=over 4

=item * new

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

=item * is_newborn()

=cut

sub is_newborn {
    $_[0]->{status} == NEWBORN;
}

=pod

=item * is_unloaded()

=cut

sub is_unloaded {
    $_[0]->{status} == UNLOADED;
}

=pod

=item * is_loaded()

=cut

sub is_loaded {
    $_[0]->{status} == LOADED;
}

=pod

=item * is_being_unloaded()

=cut

sub is_being_unloaded {
    return $_[0]->{status} == BEING_UNLOADED;
}

=pod

=item * is_deleted()

=cut

sub is_deleted {
    my $self = shift;
    return $_[0]->{status} == DELETED;
}

=pod

=item * is_corruped()

=cut

sub is_corrupted {
    my $self = shift;
    return $_[0]->{status} >= CORRUPTED;
}

=pod

=item * name()

Name of collection.

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

=item * count()

Number of documents in the collection.

=cut

sub count {
    my $self = shift;
    my $res  = $self->_get_from_this('count');
    return $res->{count};
}

=pod

=item * figure($type)

=cut

sub figure {
    my ( $self, $type ) = @_;
    my $res = $self->_get_from_this('figures');
    if ($type) {
        my ( $area, $name ) = split( '-', $type );
        return $res->{figures}{$area}{$name};
    }
    else {
        return $res->{figures};
    }
}

=pod

=item * wait_for_sync($boolean)

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

=item * drop()

Drop collection.

=cut

sub drop {
    my $self = shift;
    my $api  = API_COLLECTION . '/' . $self->{id};
    eval { $self->{connection}->http_delete($api); };
    if ($@) {
        my $msg = "Failed to drop collection(" . $self->{name} . ")";
        if ( ref($@) && $@->isa('ArangoDB::ServerException') ) {
            $msg .= ':' . ( $@->detail->{errorMessage} || q{} );
        }
        die $msg;
    }
}

=pod

=item * truncate()

Truncate collection.

=cut

sub truncate {
    my $self = shift;
    eval {
        my $res = $self->_put_to_this('truncate');
        $self->{status} = $res->{status};
    };
    if ($@) {
        my $msg = "Failed to truncate collection(" . $self->{name} . ")";
        if ( ref($@) && $@->isa('ArangoDB::ServerException') ) {
            $msg .= ':' . ( $@->detail->{errorMessage} || q{} );
        }
        die $msg;
    }
}

=pod

=item * load()

=cut

sub load {
    my $self = shift;
    my $res  = $self->_put_to_this('load');
    $self->{status} = $res->{status};
}

=pod

=item * unload()

=cut

sub unload {
    my $self = shift;
    my $res  = $self->_put_to_this('unload');
    $self->{status} = $res->{status};
}

=pod

=item * all()

=cut

sub all {
    my ( $self, $options ) = @_;
    $options ||= {};
    my $data = { collection => $self->{name} };
    if ( exists $options->{limit} ) {
        $data->{limit} = $options->{limit};
    }
    if ( exists $options->{skip} ) {
        $data->{skip} = $options->{skip};
    }
    my $res = eval { $self->{connection}->http_put( API_SIMPLE_ALL, $data ) };
    if ($@) {
        my $msg = 'Failed to call simple api(all)';
        if ( ref($@) && $@->isa('ArangoDB::ServerException') ) {
            $msg .= ':' . $@->detail->{errorMessage} || q{};
        }
        die $msg;
    }
    return $self->_documents_from_response( $res->{result} );
}

=pod

=item * by_example()

=cut

sub by_example {
    my ( $self, $ref_data, $options ) = @_;
    $options ||= {};
    my $data = { collection => $self->{name}, example => $ref_data };
    if ( exists $options->{limit} ) {
        $data->{limit} = $options->{limit};
    }
    if ( exists $options->{skip} ) {
        $data->{skip} = $options->{skip};
    }
    my $res = eval { $self->{connection}->http_put( API_SIMPLE_EXAMPLE, $data ) };
    if ($@) {
        my $msg = 'Failed to call simple api(by_example)';
        if ( ref($@) && $@->isa('ArangoDB::ServerException') ) {
            $msg .= ':' . $@->detail->{errorMessage} || q{};
        }
        die $msg;
    }
    return $self->_documents_from_response( $res->{result} );
}

=pod

=item * near()

=cut

sub near {
    my ( $self, $options ) = @_;
    $options ||= {};
    my $data = { collection => $self->{name} };
    if ( exists $options->{latitude} ) {
        $data->{latitude} = $options->{latitude};
    }
    if ( exists $options->{longitude} ) {
        $data->{longitude} = $options->{longitude};
    }
    my $res = eval { $self->{connection}->http_put( API_SIMPLE_NEAR, $data ) };
    if ($@) {
        my $msg = 'Failed to call simple api(near)';
        if ( ref($@) && $@->isa('ArangoDB::ServerException') ) {
            $msg .= ':' . $@->detail->{errorMessage} || q{};
        }
        die $msg;
    }
    return $self->_documents_from_response( $res->{result} );
}

=pod

=item * within()

=cut

sub within {
    my ( $self, $options ) = @_;
    $options ||= {};
    my $data = { collection => $self->{name} };
    if ( exists $options->{latitude} ) {
        $data->{latitude} = $options->{latitude};
    }
    if ( exists $options->{longitude} ) {
        $data->{longitude} = $options->{longitude};
    }
    if ( exists $options->{radius} ) {
        $data->{radius} = $options->{radius};
    }
    my $res = eval { $self->{connection}->http_put( API_SIMPLE_WITHIN, $data ) };
    if ($@) {
        my $msg = 'Failed to call simple api(within)';
        if ( ref($@) && $@->isa('ArangoDB::ServerException') ) {
            $msg .= ':' . $@->detail->{errorMessage} || q{};
        }
        die $msg;
    }
    return $self->_documents_from_response( $res->{result} );
}

=pod

=item * document($document_id)

Get documnet by document id.

=cut

sub document {
    my ( $self, $doc ) = @_;
    my $doc_id = ref($doc) && $doc->isa('ArangoDB::Document') ? $doc->id : $doc;
    my $api    = API_DOCUMENT . '/' . $doc_id;
    my $res    = eval { $self->{connection}->http_get($api) };
    if ($@) {
        my $msg = 'Failed to get document(' . $doc_id . ')';
        if ( ref($@) && $@->isa('ArangoDB::ServerException') ) {
            $msg .= ':' . $@->detail->{errorMessage} || q{};
        }
        die $msg;
    }
    return ArangoDB::Document->new($res);
}

=pod

=item * save($data)

Save document in the collection.

=cut

sub save {
    my ( $self, $data ) = @_;
    my $api = API_DOCUMENT . '?collection=' . $self->{id};
    my $doc = eval {
        my $res = $self->{connection}->http_post( $api, $data );
        $self->document( $res->{_id} );
    };
    if ($@) {
        my $msg = 'Failed to save new document';
        if ( ref($@) && $@->isa('ArangoDB::ServerException') ) {
            $msg .= ':' . $@->detail->{errorMessage} || q{};
        }
        die $msg;
    }
    return $doc;
}

=pod

=item * replace($doc,$data)

Replace document in the collection.

=cut

sub replace {
    my ( $self, $doc, $data ) = @_;
    my $doc_id = defined($doc) && ref($doc) && $doc->isa('ArangoDB::Documents') ? $doc->id : $doc;
    my $api = API_DOCUMENT . '/' . $doc_id . '?policy=last';
    eval { $self->{connection}->http_put( $api, $data ); };
    if ($@) {
        my $msg = 'Failed to replace document(' . $doc_id . ')';
        if ( ref($@) && $@->isa('ArangoDB::ServerException') ) {
            $msg .= ':' . $@->detail->{errorMessage} || q{};
        }
        die $msg;
    }
    return $self->document($doc_id);
}

=pod

=item * remove($doc)

Remove document.

=cut

sub remove {
    my ( $self, $doc ) = @_;
    my $doc_id = defined($doc) && ref($doc) && $doc->isa('ArangoDB::Documents') ? $doc->id : $doc;
    my $api    = API_DOCUMENT . '/' . $doc_id;
    my $res    = eval { $self->{connection}->http_delete($api) };
    if ($@) {
        my $msg = "Failed to remove document(" . $doc_id . ")";
        if ( ref($@) && $@->isa('ArangoDB::ServerException') ) {
            $msg .= ':' . ( $@->detail->{errorMessage} || q{} );
        }
        die $msg;
    }
    return;
}

sub _get_from_this {
    my ( $self, $path ) = @_;
    my $api = API_COLLECTION . '/' . $self->{id} . '/' . $path;
    my $res = eval { $self->{connection}->http_get($api) };
    if ($@) {
        my $msg = 'Failed to get property(' . $self->{id} . ',' . $path . ')';
        if ( ref($@) && $@->isa('ArangoDB::ServerException') ) {
            $msg .= ':' . ( $@->detail->{errorMessage} || q{} );
        }
        die $msg;
    }
    return $res;
}

sub _put_to_this {
    my ( $self, $path, $params ) = @_;
    my $api = API_COLLECTION . '/' . $self->{id} . '/' . $path;
    my $res = eval { $self->{connection}->http_put( $api, $params ) };
    if ($@) {
        my $msg = 'Failed to update property(' . $self->{id} . ',' . $path . ')';
        if ( ref($@) && $@->isa('ArangoDB::ServerException') ) {
            $msg .= ':' . ( $@->detail->{errorMessage} || q{} );
        }
        die $msg;
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
        my $msg = 'Failed to get edges(' . join( ',', $self->{id}, $vertex, $direction ) . ')';
        if ( ref($@) && $@->isa('ArangoDB::ServerException') ) {
            $msg .= ':' . ( $@->detail->{errorMessage} || q{} );
        }
        die $msg;
    }
    my @edges = map { ArangoDB::Edge->new($_) } @{ $res->{edges} };
    return \@edges;
}

=pod

=item * any_edges()

=item * in_edges()

=item * out_edges()

=cut

for my $direction (qw/any in out/) {
    my $sub = sub {
        my ( $self, $vertex ) = @_;
        return $self->_get_edges( $vertex, $direction );
    };
    Data::Util::install_subroutine( __PACKAGE__, "${direction}_edges " => $sub );
}

=pod

=item * edge($edge)

Get edge by edge id.

=cut

sub edge {
    my ( $self, $edge ) = @_;
    my $doc_id = ref($edge) && $edge->isa('ArangoDB::Edge') ? $edge->id : $edge;
    my $api    = API_EDGE . '/' . $doc_id;
    my $res    = eval { $self->{connection}->http_get($api) };
    if ($@) {
        my $msg = 'Failed to get edge(' . $doc_id . ')';
        if ( ref($@) && $@->isa('ArangoDB::ServerException') ) {
            $msg .= ':' . ( $@->detail->{errorMessage} || q{} );
        }
        die $msg;
    }
    return ArangoDB::Edge->new($res);
}

=pod

=item * save_edge($from,$to,$data)

=cut

sub save_edge {
    my ( $self, $from, $to, $data ) = @_;
    my $api = API_EDGE . '?collection=' . $self->{id} . '&from=' . $from . '&to=' . $to;
    my $res = eval { $self->{connection}->http_post( $api, $data ) };
    if ($@) {
        my $msg = 'Failed to save edge(' . join( ',', $self->{id}, $from, $to ) . ')';
        if ( ref($@) && $@->isa('ArangoDB::ServerException') ) {
            $msg .= ':' . ( $@->detail->{errorMessage} || q{} );
        }
        die $msg;
    }
    return $self->edge( $res->{_id} );
}

=pod

=item replace_edge($edge)

=cut

sub replace_edge {
    my ( $self, $edge ) = @_;
    my $doc_id = ref($edge) && $edge->isa('ArangoDB::Edge') ? $edge->id : $edge;
    my $api    = API_EDGE . '/' . $doc_id;
    my $res    = eval { $self->{connection}->http_get($api) };
    if ($@) {
        my $msg = 'Failed to replace edge(' . $doc_id . ')';
        if ( ref($@) && $@->isa('ArangoDB::ServerException') ) {
            $msg .= ':' . ( $@->detail->{errorMessage} || q{} );
        }
        die $msg;
    }
    return $self->edge($doc_id);
}

=pod

=item * remove_edge($edge)

=cut

sub remove_edge {
    my ( $self, $edge ) = @_;
    my $doc_id = ref($edge) && $edge->isa('ArangoDB::Edge') ? $edge->id : $edge;
    my $api    = API_EDGE . '/' . $doc_id;
    my $res    = eval { $self->{connection}->http_delete($api) };
    if ($@) {
        my $msg = 'Failed to delete edge(' . $doc_id . ')';
        if ( ref($@) && $@->isa('ArangoDB::ServerException') ) {
            $msg .= ':' . ( $@->detail->{errorMessage} || q{} );
        }
        die $msg;
    }
}

1;
__END__

=pod

=back

=head1 AUTHOR

Hideaki Ohno E<lt>hide.o.j55 {at} gmail.comE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

=cut
