use Test::More;
use Test::Fatal qw(lives_ok dies_ok);
use Test::Deep;
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

subtest 'create document' => sub{
    my $coll = $db->create('foo');
    my $doc1 = $coll->save({ foo => 'bar', baz => 10 });
    isa_ok $doc1, 'ArangoDB::Document';
    my $doc2 = $coll->document($doc1->id);
    cmp_deeply($doc1,$doc2);
};




#TODO document api test

done_testing;
