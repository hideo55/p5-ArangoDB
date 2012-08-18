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


subtest 'create collection' => sub {
    my $coll;
    lives_ok { $coll = $db->create("foo"); } 'Create new collection';
    isa_ok $coll, 'ArangoDB::Collection';
    is $coll->name, 'foo';
    ok $coll->is_loaded;
};

subtest 'collection name confliction' => sub {
    dies_ok { $db->create("foo") } 'Attempt to create collection that already exist name';
    lives_ok { $db->drop('foo') } 'Drop collection';
    lives_ok { $db->create('foo'); } 'Create collection with name that dropped collection';
};

subtest 'rename collection' => sub {
    my $coll = $db->collection('foo');
    is $coll->name, 'foo';
    $coll->name('bar');
    is $coll->name, 'bar';
    my $coll2 = $db->collection('bar');
    is $coll->id,    $coll2->id;
    is $coll2->name, 'bar';
};

subtest 'wait for sync' => sub {
    my $coll = $db->collection('bar');
    is $coll->wait_for_sync, 0;
    $coll->wait_for_sync(1);
    is $coll->wait_for_sync, 1;
    $coll->wait_for_sync(0);
    is $coll->wait_for_sync, 0;
};

subtest 'unload collection' => sub {
    my $coll = $db->collection('bar');
    ok $coll->is_loaded;
    $coll->unload;
    ok $coll->is_being_unloaded;
};

subtest 'documents in collection' => sub{
  my $coll =   $db->collection('bar');
  is $coll->count, 0;
  my $doc = $coll->save({ baz => 1 });
  isa_ok $doc, 'ArangoDB::Document';
  is $coll->count, 1;
};

done_testing;
