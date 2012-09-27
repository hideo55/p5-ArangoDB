use Test::More;
use strict;
use warnings;

use Test::More;
use Test::Fatal qw(lives_ok dies_ok);
use ArangoDB;
use JSON;

if(!$ENV{TEST_ARANGODB_PORT}){
    plan skip_all => 'Can"t find port of arangod';
}

my $port = $ENV{TEST_ARANGODB_PORT};

my $db = ArangoDB->new(
    {   host => 'localhost',
        port => $port,
    }
);

map { $_->drop } @{ $db->collections };

subtest 'create edge' => sub{
    my $coll = $db->create('foo');
    my $doc1 = $coll->save({ foo => 'bar', baz => 10 });
    my $doc2 = $coll->save({ foo => 'qux', baz => 11 });
    my $edge1 = $coll->save_edge($doc1,$doc2,{ foo => 1 });
    my $edge2 = $coll->edge($edge1);
    is_deeply($edge1,$edge2);
};

#TODO edge api test

done_testing;