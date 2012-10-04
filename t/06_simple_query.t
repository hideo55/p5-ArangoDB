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

subtest 'simple query - all' => sub {
    my $db = ArangoDB->new($config);

    my $coll = $db->collection('test1');
    $coll->save( { name => 'foo', score => 10 } );
    $coll->save( { name => 'bar', score => 50 } );
    $coll->save( { name => 'baz', score => 40 } );
    $coll->save( { name => 'qux', score => 45 } );

    my $cur = $db->collection('test1')->all;
    is $cur->length, 4;
    my @all;
    while ( my $doc = $cur->next ) {
        push @all, $doc;
    }
    my @all_contents = sort { $a->{name} cmp $b->{name} } map { $_->content } @all;
    my $expect = [
        { name => 'bar', score => 50 },
        { name => 'baz', score => 40 },
        { name => 'foo', score => 10 },
        { name => 'qux', score => 45 },
    ];
    is_deeply \@all_contents, $expect;

    my $cur2 = $db->collection('test1')->all( { limit => 2 } );
    is $cur2->length, 2, 'limit option for simple query';

    my $cur3 = $db->collection('test1')->all( { skip => 1 } );
    is $cur3->length, 3;

};

subtest 'simple query - by_example' => sub {
    my $db = ArangoDB->new($config);

    my $coll = $db->collection('test2');
    $coll->save( { name => 'foo', x => { a => 1, b => 2 } } );
    $coll->save( { name => 'bar', x => { a => 2, b => 2 } } );
    $coll->save( { name => 'baz', x => { a => 3, b => 2 } } );
    $coll->save( { name => 'qux', x => { b => 1, a => 1 } } );

    my $cur = $coll->by_example( { "x.a" => 1 } );
    is $cur->length, 2;
    my @docs;
    while ( my $doc = $cur->next ) {
        push @docs, $doc->content;
    }
    my $expect = [ { name => 'foo', x => { a => 1, b => 2 } }, { name => 'qux', x => { b => 1, a => 1 } }, ];

    is_deeply( [ sort { $a->{name} cmp $b->{name} } @docs ], $expect );

};

done_testing;
