use strict;
use Test::More;
use Test::Fatal qw(lives_ok dies_ok exception);
use Test::Mock::Guard;
use ArangoDB;
use JSON;

if ( !$ENV{TEST_ARANGODB_PORT} ) {
    plan skip_all => 'Can"t find port of arangod';
}

my $port   = $ENV{TEST_ARANGODB_PORT};
my $config = {
    host => 'localhost',
    port => $port,
};

init();

sub init {
    my $db = ArangoDB->new($config);
    map { $_->drop } @{ $db->collections };
}

subtest 'SYNOPSYS' => sub {
    my $db = ArangoDB->new($config);
    $db->collection('my_collection')->save( { x => 42, y => { a => 1, b => 2, } } );    # Create document
    $db->collection('my_collection')->save( { x => 1,  y => { a => 1, b => 10, } } );
    $db->collection('my_collection')->name('new_name');                                 # rename the collection
    $db->collection('new_name')->ensure_hash_index( [qw/y/] );
    my $cur = $db->collection('new_name')->by_example( { x => 42 } );
    my @docs;
    while ( my $doc = $cur->next() ) {
        push @docs, $doc;
    }
    is scalar @docs, 1;
    is_deeply $docs[0]->content, { x => 42, y => { a => 1, b => 2, } };
    $db->collection('new_name')->drop();                                                # Drop the collection
};

subtest 'create collection' => sub {
    my $db = ArangoDB->new($config);
    my $coll;
    lives_ok { $coll = $db->create("foo"); } 'Create new collection';
    isa_ok $coll, 'ArangoDB::Collection';
    is $coll->name, 'foo';
    ok $coll->is_loaded;
    ok !$coll->is_newborn;
    ok !$coll->is_unloaded;
    ok !$coll->is_being_unloaded;
    ok !$coll->is_deleted;
    ok !$coll->is_corrupted;

    my $e = exception {
        my $guard = mock_guard( 'ArangoDB::Connection' => { http_post => sub {die}, } );
        $db->create('bar');
    };
    like $e, qr/^Failed to create collection/;
    $db->collection('baz');
};

subtest 'get collection' => sub {
    my $db   = ArangoDB->new($config);
    my $coll = $db->find('bar');
    ok !defined $coll;
    $coll = $db->find('foo');
    ok $coll;
};

subtest 'get all collections' => sub {
    my $db    = ArangoDB->new($config);
    my $colls = $db->collections;
    is scalar @$colls, 2;
    my $e = exception {
        my $guard = mock_guard( 'ArangoDB::Connection', { http_get => sub {die}, } );
        $db->collections();
    };
    like $e, qr/^Failed to get collections/;
};

subtest 'drop collection' => sub {
    my $db = ArangoDB->new($config);
    lives_ok {
        $db->drop('baz');
    };

    my $e = exception {
        my $guard = mock_guard( 'ArangoDB::Connection', { http_delete => sub {die}, } );
        $db->drop('baz');
    };
    like $e, qr/^Failed to drop collection/;
};

subtest 'collection name confliction' => sub {
    my $db = ArangoDB->new($config);
    dies_ok { $db->create("foo") } 'Attempt to create collection that already exist name';
    lives_ok { $db->drop('foo') } 'Drop collection';
    lives_ok { $db->create( 'foo', { waitForSync => 1, } ); } 'Create collection with name that dropped collection';
};

subtest 'rename collection' => sub {
    my $db   = ArangoDB->new($config);
    my $coll = $db->collection('foo');
    is $coll->name, 'foo';
    $coll->name('bar');
    is $coll->name, 'bar';
    my $coll2 = $db->collection('bar');
    is $coll->id,    $coll2->id;
    is $coll2->name, 'bar';
};

subtest 'wait for sync' => sub {
    my $db   = ArangoDB->new($config);
    my $coll = $db->collection('bar');
    is $coll->wait_for_sync, 0;
    $coll->wait_for_sync(1);
    is $coll->wait_for_sync, 1;
    $coll->wait_for_sync(0);
    is $coll->wait_for_sync, 0;
};

subtest 'unload and load collection' => sub {
    my $db   = ArangoDB->new($config);
    my $coll = $db->collection('bar');
    ok $coll->is_loaded;
    $coll->unload;
    ok $coll->is_being_unloaded;
    $coll->load;
    ok $coll->is_loaded;
};

subtest 'count documents in collection' => sub {
    my $db   = ArangoDB->new($config);
    my $coll = $db->collection('bar');
    is $coll->count, 0;
    my $doc = $coll->save( { baz => 1 } );
    isa_ok $doc, 'ArangoDB::Document';
    is $coll->count, 1;
    my $doc = $coll->save( { qux => 1 } );
    is $coll->count, 2;
};

subtest 'figures' => sub {
    my $db    = ArangoDB->new($config);
    my $coll  = $db->collection('bar');
    my $stats = $coll->figure();
    is ref($stats), 'HASH';
    is $stats->{alive}{count}, $coll->figure('alive-count');
    is $stats->{alive}{size},  $coll->figure('alive-size');
    is $coll->figure('count'), 2;
    ok $coll->figure('journalSize');
    ok !defined $coll->figure('foo');
};

subtest 'drop collection by name' => sub {
    my $db   = ArangoDB->new($config);
    my $coll = $db->create('qux');
    ok $coll;
    $db->drop('qux');
    $coll = $db->find('qux');
    ok !defined $coll;
};

subtest 'fail drop collection' => sub {
    my $db   = ArangoDB->new($config);
    my $coll = $db->collection('bar');
    $coll->drop();
    my $e = exception { $coll->drop() };
    like $e, qr/^Failed to drop the collection\(bar\)/;
};

subtest 'truncate collection' => sub {
    my $db   = ArangoDB->new($config);
    my $coll = $db->create('foo');
    my $id   = $coll->id;
    $coll->save( { foo => 1 } );
    is $coll->count, 1;
    lives_ok { $coll->truncate() };
    $coll = $db->collection('foo');
    is $coll->id,    $id;
    is $coll->count, 0;
    $coll->save( { save => 2 } );
    is $coll->count, 1;
    lives_ok { $db->truncate('foo') };
    is $coll->count, 0;
};

subtest 'fail truncate collection' => sub {
    my $guard = mock_guard( 'ArangoDB::Connection' =>
            { http_put => sub { die ArangoDB::ServerException->new( code => 500, status => 500, detail => {} ) }, } );
    my $db   = ArangoDB->new($config);
    my $coll = $db->collection('foo');
    my $e    = exception { $coll->truncate() };
    like $e, qr/^Failed to truncate the collection\(foo\)/;
};

done_testing;
