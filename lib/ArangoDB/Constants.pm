package ArangoDB::Constants;
use strict;
use warnings;
use utf8;
use 5.010000;
use parent qw(Exporter);

our $VERSION = '0.08';

my @options = qw(OPTION_ENDPOINT OPTION_HOST OPTION_PORT OPTION_PILICY OPTION_WAIT_SYNC OPTION_AUTH_USER
    OPTION_AUTH_PASSWD OPTION_AUTH_TYPE OPTION_CONNECTION);
my @policies = qw(POLICY_LAST PILICY_ERROR);
my @api = qw(API_DOCUMENT API_COLLECTION API_CURSOR API_EXAMPLE API_EDGE API_QUERY API_SIMPLE_ALL API_SIMPLE_EXAMPLE
    API_SIMPLE_REMOVE_EXAMPLE API_SIMPLE_REPLACE_EXAMPLE API_SIMPLE_UPDATE_EXAMPLE API_SIMPLE_FIRST API_SIMPLE_RANGE
    API_SIMPLE_NEAR API_SIMPLE_WITHIN API_SIMPLE_FULLTEXT API_INDEX API_IMPORT API_EDGES API_EXPLAIN API_KEY API_KEYS
    API_VERSION API_GRAPH);

my @status          = qw(NEWBORN UNLOADED LOADED BEING_UNLOADED DELETED CORRUPTED);
my @collection_type = qw(DOCUMENT_COLLECTION EDGE_COLLECTION);

our @EXPORT_OK = ( @options, @policies, @api, @status, @collection_type );
our %EXPORT_TAGS = (
    all             => \@EXPORT_OK,
    option          => \@options,
    policy          => \@policies,
    api             => \@api,
    status          => \@status,
    collection_type => \@collection_type,
);

# Options
use constant {
    OPTION_HOST        => 'host',
    OPTION_PORT        => 'port',
    OPTION_TIMEOUT     => 'timeout',
    OPTION_PILICY      => 'policy',
    OPTION_WAIT_SYNC   => 'wait_for_sysnc',
    OPTION_AUTH_USER   => 'auth_user',
    OPTION_AUTH_PASSWD => 'auth_passwd',
    OPTION_AUTH_TYPE   => 'auth_type',
    OPTION_CONNECTION  => 'connection',
};

# Update policies
use constant {
    POLICY_LAST  => 'last',
    PILICY_ERROR => 'error',
};

# API
use constant {
    API_VERSION                => '/_admin/version',
    API_DOCUMENT               => '/_api/document',
    API_COLLECTION             => '/_api/collection',
    API_CURSOR                 => '/_api/cursor',
    API_EDGE                   => '/_api/edge',
    API_EDGES                  => '/_api/edges',
    API_KEY                    => '/_api/key/',
    API_KEYS                   => '/_api/keys/',
    API_SIMPLE_EXAMPLE         => '/_api/simple/by-example',
    API_SIMPLE_REMOVE_EXAMPLE  => '/_api/simple/remove-by-example',
    API_SIMPLE_REPLACE_EXAMPLE => '/_api/simple/replace-by-example',
    API_SIMPLE_UPDATE_EXAMPLE  => '/_api/simple/update-by-example',
    API_QUERY                  => '/_api/query',
    API_EXPLAIN                => '/_api/explain',
    API_INDEX                  => '/_api/index',
    API_IMPORT                 => '/_api/import',
    API_SIMPLE_ALL             => '/_api/simple/all',
    API_SIMPLE_EXAMPLE         => '/_api/simple/by-example',
    API_SIMPLE_FIRST           => '/_api/simple/first-example',
    API_SIMPLE_RANGE           => '/_api/simple/range',
    API_SIMPLE_NEAR            => '/_api/simple/near',
    API_SIMPLE_WITHIN          => '/_api/simple/within',
    API_SIMPLE_FULLTEXT        => '/_api/simple/fulltext',
    API_GRAPH                  => '/_api/graph',

};

# Status
use constant {
    NEWBORN        => 1,
    UNLOADED       => 2,
    LOADED         => 3,
    BEING_UNLOADED => 4,
    DELETED        => 5,
    CORRUPTED      => 6,
};

# Collection type
use constant {
    DOCUMENT_COLLECTION => 2,
    EDGE_COLLECTION     => 3,
};

1;
__END__
