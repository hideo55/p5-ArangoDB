package ArangoDB::API::V1_1;
use strict;
use warnings;
use parent 'ArangoDB';
use ArangoDB::Constants qw(:api :collection_type);
use constant {
    _COLLECTION_CLASS => 'ArangoDB::API::V1_1::Collection',
    _DOCUMENT_CLASS => 'ArangoDB::Document',
    _EDGE_CLASS => 'ArangoDB::Edge',
};
use ArangoDB::API::V1_1::Collection;

sub create {
    my ( $self, $name, $_options ) = @_;
    my $params = { ( waitForSync => 0, isSystem => 0, type => DOCUMENT_COLLECTION, ), %{ $_options || {} } };
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

sub create_document_collection {
    my ( $self, $name, $_options ) = @_;
    $_options ||= {};
    $_options->{type} = DOCUMENT_COLLECTION;
    return $self->create( $name, $_options );
}

sub create_edge_collection {
    my ( $self, $name, $_options ) = @_;
    $_options ||= {};
    $_options->{type} = EDGE_COLLECTION;
    return $self->create( $name, $_options );
}

1;
__END__
