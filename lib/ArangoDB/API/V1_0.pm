package ArangoDB::API::V1_0;
use strict;
use warnings;
use 5.010000;
use parent 'ArangoDB';
use constant {
    _COLLECTION_CLASS => 'ArangoDB::API::V1_0::Collection',
    _DOCUMENT_CLASS => 'ArangoDB::Document',
    _EDGE_CLASS => 'ArangoDB::Edge',
};
use ArangoDB::API::V1_0::Collection;

1;
__END__