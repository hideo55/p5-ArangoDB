package ArangoDB::API::V1_1::Collection;
use strict;
use warnings;
use parent 'ArangoDB::Collection';
use ArangoDB::Constants qw(:collection_type);
use constant {
    _DOCUMENT_CLASS => 'ArangoDB::API::V1_1::Document',
};

sub new {
    my ( $class, $db, $raw_collection ) = @_;
    my $self = $class->SUPER::new( $db, $raw_collection );
    $self->{type} = $raw_collection->{type};
    return $self;
}

sub is_document_collection {
    $_[0]->{type} == DOCUMENT_COLLECTION;
}

sub is_edge_collection {
    $_[0]->{type} == EDGE_COLLECTION;
}

1;
__END__
