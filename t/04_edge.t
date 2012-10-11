use strict;
use Test::More;
use strict;
use warnings;

use Test::More;
use Test::Fatal qw(lives_ok exception);
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

subtest 'create edge' => sub {
    my $db    = ArangoDB->new($config);
    my $coll  = $db->create('foo');
    my $doc1  = $coll->save( { foo => 'bar', baz => 10 } );
    my $doc2  = $coll->save( { foo => 'qux', baz => 11 } );
    my $edge1 = $coll->save_edge( $doc1, $doc2, { foo => 1 } );
    is $edge1->from, $doc1->id;
    is $edge1->to,   $doc2->id;
    my $edge2 = $coll->edge($edge1);
    is_deeply( $edge1, $edge2 );

    like exception {
        my $guard = mock_guard(
            'ArangoDB::Connection' => {
                http_post => sub {die}
            }
        );
        $coll->save_edge( $doc2, $doc1 );
    }, qr/Failed to save the new edge to the collection/;

};

subtest 'get edges' => sub {
    my $db   = ArangoDB->new($config);
    my $coll = $db->collection('test1');
    my $doc1 = $coll->save( { foo => 1 } );
    my $doc2 = $coll->save( { foo => 2 } );
    my $doc3 = $coll->save( { foo => 3 } );
    my $doc4 = $coll->save( { foo => 4 } );

    my $e1 = $coll->save_edge( $doc1, $doc2, { e => 1 } );
    $coll->save_edge( $doc1, $doc3, { e => 2 } );
    $coll->save_edge( $doc2, $doc1, { e => 4 } );
    $coll->save_edge( $doc3, $doc1, { e => 4 } );

    my $e1_1 = $coll->edge($e1);
    is_deeply $e1_1, $e1;
    like exception { $coll->edge() }, qr/^Failed to get the edge/;

    my $edges = $coll->any_edges($doc1);
    ok !grep { !$_->isa('ArangoDB::Edge') } @$edges;
    is scalar @$edges, 4;

    $edges = $coll->any_edges($doc2);
    is scalar @$edges, 2;

    $edges = $coll->any_edges($doc4);
    is scalar @$edges, 0;

    my $e = exception {
        my $guard = mock_guard(
            'ArangoDB::Connection' => {
                http_get => sub {die}
            }
        );
        $coll->any_edges($doc2);
    };
    like $e, qr{Failed to get edges\(\d+,\d+/\d+,any\) in the collection};

    $edges = $coll->out_edges($doc1);
    is scalar @$edges, 2;

    $edges = $coll->out_edges($doc4);
    is scalar @$edges, 0;

    #in edges
    $edges = $coll->in_edges($doc1);
    is scalar @$edges, 2;

    $edges = $coll->in_edges($doc2);
    is scalar @$edges, 1;

    $edges = $coll->in_edges($doc4);
    is scalar @$edges, 0;
};

subtest 'Update edge' => sub {
    my $db   = ArangoDB->new($config);
    my $coll = $db->find('test1');
    my $doc  = $coll->first_example( { foo => 3 } );
    my $edge = $coll->in_edges($doc)->[0];
    $coll->update_edge( $edge->id, { e => '2-2' } );
    my $new_edge = $coll->edge( $edge->id );
    is_deeply $new_edge->content, { e => '2-2' };

    like exception { $coll->update_edge() }, qr/^Failed to update the edge/;

};

subtest 'delete edges' => sub {
    my $db   = ArangoDB->new($config);
    my $coll = $db->find('test1');
    my $doc  = $coll->first_example( { foo => 3 } );

    my $edges = $coll->out_edges($doc);

    lives_ok {
        for my $edge (@$edges) {
            $coll->delete_edge($edge);
        }
    };

    like exception {
        my $guard = mock_guard(
            'ArangoDB::Connection' => {
                http_delete => sub {die}
            }
        );
        $coll->delete_edge( $edges->[0] );
    }, qr/^Failed to delete the edge/;

};

done_testing;
