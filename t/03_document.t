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
    is "$doc1", $doc1->id, 'Test for ArangoDB::Document overload';
    ok defined $doc1->revision;
    is_deeply $doc1->content, { foo => 'bar', baz => 10 };

    my $doc2 = $coll->document( $doc1->id );
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
    $coll->delete($doc);
    like exception { $coll->document($doc) }, qr/^Failed to get the document/;

    my $e = exception {
        my $guard = mock_guard(
            'ArangoDB::Connection' => {
                http_delete => sub {die}
            }
        );
        $coll->delete($doc);
    };
    like $e, qr/^Failed to delete the document/;
};

subtest 'Update document' => sub {
    my $db   = ArangoDB->new($config);
    my $coll = $db->collection('foo');
    my $doc1 = $coll->save( { foo => 'bar' } );
    is_deeply $doc1->content, { foo => 'bar' };
    my $doc2 = $coll->update( $doc1, { foo => 'baz' } );
    is $doc1, $doc2;
    ok $doc1->revision < $doc2->revision;
    is_deeply $doc2->content, { foo => 'baz' };

    my $e = exception {
        my $guard = mock_guard(
            'ArangoDB::Connection' => {
                http_put => sub {die}
            }
        );
        $coll->update( $doc1, { foo => 'bar' } );
    };
    like $e, qr/^Failed to update the document/;

};

subtest 'bulk import - header' => sub {
    my $db = ArangoDB->new($config);
    my $res = $db->collection('di')->bulk_import( [qw/fistsName lastName age gender/],
        [ [ "Joe", "Public", 42, "male" ], [ "Jane", "Doe", 31, "female" ], ] );
    ok !$res->{failed};
    is $res->{created}, 2;

    my $e = exception {
        my $guard = mock_guard(
            'ArangoDB::Connection' => {
                http_post_raw => sub {die}
            }
        );
        $db->collection('di')->bulk_import( [qw/fistsName lastName age gender/],
            [ [ "Joe", "Public", 42, "male" ], [ "Jane", "Doe", 31, "female" ], ] );
    };

    like $e, qr/^Failed to bulk import to the collection/;

};

subtest 'bulk import - self-contained' => sub {
    my $db  = ArangoDB->new($config);
    my $res = $db->collection('di')
        ->bulk_import_self_contained( [ { name => 'foo', age => 20 }, { type => 'bar', count => 100 }, ] );
    ok !$res->{failed};
    is $res->{created}, 2;

    my $e = exception {
        my $guard = mock_guard(
            'ArangoDB::Connection' => {
                http_post_raw => sub {die}
            }
        );
        $db->collection('di')
            ->bulk_import_self_contained( [ { name => 'foo', age => 20 }, { type => 'bar', count => 100 }, ] );
    };

    like $e, qr/^Failed to bulk import to the collection/;
};

subtest 'get all document id' => sub {
    my $db      = ArangoDB->new($config);
    my $coll = $db->collection('di');
    my $doc_ids = $coll->all_document_ids;
    is scalar @$doc_ids, 4;
    
    my $e = exception {
        my $guard = mock_guard( 'ArangoDB::Connection' => { http_get => sub {die} } );
        $coll->all_document_ids;
    };
    like $e, qr/^Failed to get the all document ids/;
};

done_testing;
