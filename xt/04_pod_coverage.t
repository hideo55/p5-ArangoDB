use strict;
use Test::More;
eval "use Test::Pod::Coverage";
plan skip_all => "Test::Pod::Coverage required for testing POD coverage" if $@;

my %INNER_CLASSES = map { $_ => 1 } qw/
    ArangoDB::AbstractDocument
    ArangoDB::BindVars
    ArangoDB::ClientException
    ArangoDB::Connection
    ArangoDB::Constants
    ArangoDB::Index
    ArangoDB::ServerException
    ArangoDB::API::V1_0
    ArangoDB::API::V1_0::Collection
    ArangoDB::API::V1_1
    ArangoDB::API::V1_1::Collection
    ArangoDB::API::V1_1::Document
    ArangoDB::API::V1_2
    ArangoDB::API::V1_2::Collection
    ArangoDB::API::V1_2::Document
    /;
    

for my $pkg ( grep { !exists $INNER_CLASSES{$_} } all_modules() )
{
    pod_coverage_ok($pkg);
}

done_testing;
