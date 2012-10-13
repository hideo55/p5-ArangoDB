use strict;
use Test::More;
use Test::Fatal qw(lives_ok dies_ok exception);
use Test::Mock::Guard;
use Test::Deep;
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

subtest 'Failed to get document' => sub {
    my $db   = ArangoDB->new($config);
    my $coll = $db->collection('test1');
    like exception { $coll->document() }, qr/^Failed to get the document/;
};

subtest 'create document' => sub {
    my $db   = ArangoDB->new($config);
    my $coll = $db->create('foo');
    my $doc1 = $coll->save( { foo => 'bar', baz => 10 } );
    isa_ok $doc1, 'ArangoDB::Document';
    is "$doc1", $doc1->document_handle, 'Test for ArangoDB::Document overload';
    ok defined $doc1->revision;
    is $doc1->document_handle, $doc1->collection_id . '/' . $doc1->id;
    is_deeply $doc1->content, { foo => 'bar', baz => 10 };
    is $doc1->get('foo'), 'bar';

    my $doc2 = $coll->document($doc1);
    is_deeply $doc1, $doc2;

    my $e = exception {
        my $guard = mock_guard(
            'ArangoDB::Connection' => {
                http_post => sub {die}
            }
        );
        $coll->save( { foo => 'bar' } );
    };
    like $e, qr/^Failed to save the new document/;

};

subtest 'Delete document' => sub {
    my $db   = ArangoDB->new($config);
    my $coll = $db->collection('foo');
    my $doc  = $coll->save( { foo => 'bar' } );
    ok $doc;
    $coll->document($doc)->delete();
    like exception { $coll->document($doc) }, qr/^Failed to get the document/;

    my $e = exception {
        $doc->delete();
    };
    like $e, qr/^Failed to delete the document/;

};

subtest 'Update document' => sub {
    my $db   = ArangoDB->new($config);
    my $coll = $db->collection('foo');
    my $doc1 = $coll->save( { foo => 'bar' } );
    is_deeply $doc1->content, { foo => 'bar' };
    my $doc2 = $coll->document($doc1);
    $doc1->set( foo => 'baz' );
    $doc1->save();
    is $doc1->id, $doc2->id;
    ok $doc1->revision > $doc2->revision;
    ok !eq_deeply( $doc1->content, $doc2->content );
    $doc2->fetch;
    is_deeply $doc2->content, $doc1->content;

    like exception {
        my $guard = mock_guard(
            'ArangoDB::Connection' => {
                http_put => sub {die}
            }
        );
        $doc1->set( foo => 'bar' );
        $doc1->save();
    }, qr/^Failed to update the document/;

    like exception {
        my $guard = mock_guard(
            'ArangoDB::Connection' => {
                http_get => sub {die}
            }
        );
        $doc1->fetch;
    }, qr/^Failed to fetch the document/;

};

subtest 'bulk import - header' => sub {
    my $db = ArangoDB->new($config);
    my $res = $db->collection('di')->bulk_import( [qw/fistsName lastName age gender/],
        [ [ "Joe", "Public", 42, "male" ], [ "Jane", "Doe", 31, "female" ], ] );
    ok !$res->{failed};
    is $res->{created}, 2;

    like exception {
        my $guard = mock_guard(
            'ArangoDB::Connection' => {
                http_post_raw => sub {die}
            }
        );
        $db->collection('di')->bulk_import( [qw/fistsName lastName age gender/],
            [ [ "Joe", "Public", 42, "male" ], [ "Jane", "Doe", 31, "female" ], ] );
    }, qr/^Failed to bulk import to the collection/;

};

subtest 'bulk import - self-contained' => sub {
    my $db  = ArangoDB->new($config);
    my $res = $db->collection('di')
        ->bulk_import_self_contained( [ { name => 'foo', age => 20 }, { type => 'bar', count => 100 }, ] );
    ok !$res->{failed};
    is $res->{created}, 2;

    like exception {
        my $guard = mock_guard(
            'ArangoDB::Connection' => {
                http_post_raw => sub {die}
            }
        );
        $db->collection('di')
            ->bulk_import_self_contained( [ { name => 'foo', age => 20 }, { type => 'bar', count => 100 }, ] );
    }, qr/^Failed to bulk import to the collection/;
};

done_testing;
