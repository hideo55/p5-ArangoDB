package ArangoDB::Collection;
use strict;
use warnings;
use Scalar::Util qw(weaken);
use JSON;
use Class::Accessor::Lite ( ro => [qw/id status/], );
use ArangoDB::Constants qw(:api);
use ArangoDB::Document;

sub new {
    my ( $class, $conn, $raw_collection ) = @_;
    my $self = bless {}, $class;
    $self->{connection} = $conn;
    weaken( $self->{connection} );
    map { $self->{$_} = $raw_collection->{$_} } qw(id name status);
    return $self;
}

sub is_newborn {
    $_[0]->{status} == 1;
}

sub is_unloaded {
    $_[0]->{status} == 2;
}

sub is_loaded {
    $_[0]->{status} == 3;
}

sub is_being_unloaded {
    return $_[0]->{status} == 4;
}

sub is_deleted {
    my $self = shift;
    return $_[0]->{status} == 5;
}

sub is_corrupted {
    my $self = shift;
    return $_[0]->{status} > 5;
}

sub name {
    my ( $self, $_name ) = @_;
    if ($_name) {    #rename
        $self->_put_to_this( 'rename', { name => $_name } );
        $self->{name} = $_name;
    }
    return $self->{name};
}

sub count {
    my $self = shift;
    my $res  = $self->_get_from_this('count');
    return $res->{count};
}

sub figure {
    my ( $self, $type ) = @_;
    my $res = $self->_get_from_this('figures');
    my ( $area, $name ) = split( '-', $type );
    return $res->{figures}{$area}{$name};
}

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

sub drop {
    my $self = shift;
    my $api  = API_COLLECTION . '/' . $self->{id};
    eval { $self->{connection}->http_delete($api); };
    if ($@) {
        my $msg = "Failed to drop collection(" . $self->{name} . ")";
        if ( ref($@) && $@->isa('ArangoDB::ServerException') ) {
            $msg .= ':' . $@->detail->{errorMessage};
        }
        die $msg;
    }
}

sub trancate {
    my $self = shift;
    eval {
        my $res = $self->_put_to_this('truncate');
        $self->{status} = $res->{status};
    };
    if ($@) {
        my $msg = "Failed to drop collection(" . $self->{name} . ")";
        if ( ref($@) && $@->isa('ArangoDB::ServerException') ) {
            $msg .= ':' . $@->detail->{errorMessage};
        }
        die $msg;
    }
}

sub load {
    my $self = shift;
    my $res  = $self->_put_to_this('load');
    $self->{status} = $res->{status};
}

sub unload {
    my $self = shift;
    my $res  = $self->_put_to_this('unload');
    $self->{status} = $res->{status};
}

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
    my $res = $self->{connection}->http_put( API_SIMPLE_ALL, $data );
    return $self->_documents_from_response( $res->{result} );
}

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
    my $res = $self->{connection}->http_put( API_SIMPLE_EXAMPLE, $data );
    return $self->_documents_from_response( $res->{result} );
}

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
    my $res = $self->{connection}->http_put( API_SIMPLE_NEAR, $data );
    return $self->_documents_from_response( $res->{result} );
}

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
    my $res = $self->{connection}->http_put( API_SIMPLE_WITHIN, $data );
    return $self->_documents_from_response( $res->{result} );
}

sub document {
    my ( $self, $doc ) = @_;
    my $doc_id = ref($doc) && $doc->isa('ArangoDB::Document') ? $doc->id : $doc;
    my $api    = API_DOCUMENT . '/' . $doc_id;
    my $res    = $self->{connection}->http_get($api);
    return ArangoDB::Document->new($res);
}

sub save {
    my ( $self, $data ) = @_;
    my $api = API_DOCUMENT . '?collection=' . $self->{id};
    my $res = $self->{connection}->http_post( $api, $data );
    my $doc = { %$data, _id => $res->{_id}, _rev => $res->{_rev}, };
    return ArangoDB::Document->new($doc);
}

sub replace {
    my ($self, $doc, $data) =@_;
    my $doc_id = defined($doc) && ref($doc) && $doc->isa('ArangoDB::Documents') ? $doc->id : $doc ;
    my $api = API_DOCUMENT . '/' . $doc_id . '?policy=last';
    my $res = $self->{connection}->http_put($api, $data);
        
    #TODO replace document
}

sub remove {
    my ($self, $doc) = @_;
    my $doc_id = defined($doc) && ref($doc) && $doc->isa('ArangoDB::Documents') ? $doc->id : $doc ;
    my $api = API_DOCUMENT . '/' . $doc_id;
    my $res = $self->{connection}->http_delete($api);
    return;
}

sub _get_from_this {
    my ( $self, $path ) = @_;
    my $api = join( '/', API_COLLECTION, $self->{id}, $path );
    return $self->{connection}->http_get($api);
}

sub _put_to_this {
    my ( $self, $path, $params ) = @_;
    my $api = join( '/', API_COLLECTION, $self->{id}, $path );
    return $self->{connection}->http_put( $api, $params );
}

sub _documents_from_respose {
    my ( $self, $res ) = @_;
    my @docs = map { ArangoDB::Document->new($_) } @$res;
    return \@docs;
}

#TODO implement Edges API

1;
__END__
