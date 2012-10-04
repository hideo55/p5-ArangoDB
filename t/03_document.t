use Test::More;
use Test::Fatal qw(lives_ok dies_ok exception);
use ArangoDB;
use JSON;

if ( !$ENV{TEST_ARANGODB_PORT} ) {
    plan skip_all => 'Can"t find port of arangod';
}

my $port   = $ENV{TEST_ARANGODB_PORT};
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
};

subtest 'Delete document' => sub {
    my $db   = ArangoDB->new($config);
    my $coll = $db->collection('foo');
    my $doc  = $coll->save( { foo => 'bar' } );
    ok $doc;
    $coll->delete($doc);
    my $e = exception { $coll->document($doc) };
    like $e, qr/^Failed to get the document/;
};

subtest 'Repace document' => sub {
    my $db   = ArangoDB->new($config);
    my $coll = $db->collection('foo');
    my $doc1 = $coll->save( { foo => 'bar' } );
    is_deeply $doc1->content, { foo => 'bar' };
    my $doc2 = $coll->replace( $doc1, { foo => 'baz' } );
    is $doc1, $doc2;
    ok $doc1->revision < $doc2->revision;
    is_deeply $doc2->content, { foo => 'baz' };
};

done_testing;
