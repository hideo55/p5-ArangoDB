package ArangoDB::API::V1_2;
use strict;
use warnings;
use 5.010000;
use parent 'ArangoDB::API::V1_1';
use ArangoDB::Constants qw(:api :collection_type);
use constant {
    _COLLECTION_CLASS => 'ArangoDB::API::V1_2::Collection',
    _DOCUMENT_CLASS   => 'ArangoDB::API::V1_2::Document',
    _EDGE_CLASS       => 'ArangoDB::Edge',
};
use ArangoDB::API::V1_2::Collection;
use ArangoDB::API::V1_2::Document;

1;
__END__
