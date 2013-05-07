package ArangoDB::API::V1_1;
use strict;
use warnings;
use 5.010000;
use parent 'ArangoDB';
use ArangoDB::Constants qw(:api :collection_type);
use constant {
    _COLLECTION_CLASS => 'ArangoDB::API::V1_1::Collection',
    _DOCUMENT_CLASS   => 'ArangoDB::API::V1_1::Document',
    _EDGE_CLASS       => 'ArangoDB::Edge',
};
use ArangoDB::API::V1_1::Collection;
use ArangoDB::API::V1_1::Document;

our $VERSION = '0.08';

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
