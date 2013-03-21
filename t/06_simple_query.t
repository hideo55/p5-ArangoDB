use strict;
use Test::More;
use Test::Fatal qw(lives_ok dies_ok exception);
use Test::Mock::Guard;
use ArangoDB;
use JSON;

if ( !$ENV{TEST_ARANGODB_PORT} ) {
    plan skip_all => 'Can"t find port of arangod';
}

my $port        = $ENV{TEST_ARANGODB_PORT};
my $api_version = $ENV{TEST_ARANGODB_VERSION};
my $config      = {
    host => 'localhost',
    port => $port,
    api  => $api_version,
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

    my $e = exception {
        my $guard = mock_guard( 'ArangoDB::Connection', { http_put => sub {die}, } );
        $db->collection('test1')->all();
    };
    like $e, qr/^Failed to call Simple API\(all\) for the collection/;

};

subtest 'simple query - by_example' => sub {
    my $db = ArangoDB->new($config);

    my $coll = $db->collection('test2_1');
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

    $cur = $coll->by_example( { "x.a" => 1 }, { limit => 1, } );
    my @docs2;
    while ( my $doc = $cur->next ) {
        push @docs2, $doc->content;
    }
    is scalar @docs2, 1;

    my $e = exception {
        my $guard = mock_guard( 'ArangoDB::Connection', { http_put => sub {die}, } );
        $db->collection('test2_1')->by_example( { "x.a" => 1 } );
    };
    like $e, qr/^Failed to call Simple API\(by_example\) for the collection/;
};

subtest 'simple query - first_example' => sub {
    my $db = ArangoDB->new($config);

    my $coll = $db->collection('test3');
    $coll->save( { name => 'foo', x => { a => 1, b => 2 } } );
    $coll->save( { name => 'bar', x => { a => 2, b => 2 } } );
    $coll->save( { name => 'baz', x => { a => 3, b => 2 } } );
    $coll->save( { name => 'qux', x => { b => 1, a => 1 } } );

    my $doc = $coll->first_example( { "x.a" => 1 } );
    isa_ok $doc, 'ArangoDB::Document';

    is_deeply $doc->content->{x}{a}, 1;

    my $e = exception {
        my $guard = mock_guard( 'ArangoDB::Connection', { http_put => sub {die}, } );
        $db->collection('test3')->first_example( { "x.a" => 1 } );
    };
    like $e, qr/^Failed to call Simple API\(first_example\) for the collection/;

};

subtest 'simple query - range' => sub {
    my $db = ArangoDB->new($config);

    my $coll = $db->collection('test4');
    $coll->save( { name => 'foo', x => { a => 1, b => 2 } } );
    $coll->save( { name => 'bar', x => { a => 2, b => 2 } } );
    $coll->save( { name => 'baz', x => { a => 3, b => 2 } } );
    $coll->save( { name => 'qux', x => { b => 1, a => 4 } } );

    my $e = exception {
        $coll->range( 'x.a', 2, 4 );
    };
    like $e, qr/^Failed to call Simple API\(range\).*not implemented/;

    $coll->ensure_skiplist( [qw/x.a/] );

    my $cur = $coll->range( 'x.a', 2, 4 );

    my $expect = [ { name => 'bar', x => { a => 2, b => 2 } }, { name => 'baz', x => { a => 3, b => 2 } }, ];

    my @docs;
    while ( my $doc = $cur->next ) {
        push @docs, $doc->content;
    }

    is_deeply( [ sort { $a->{name} cmp $b->{name} } @docs ], $expect );

    $cur = $coll->range( 'x.a', 2, 4, { closed => 1 } );

    $expect = [
        { name => 'bar', x => { a => 2, b => 2 } },
        { name => 'baz', x => { a => 3, b => 2 } },
        { name => 'qux', x => { b => 1, a => 4 } },
    ];

    @docs = ();
    while ( my $doc = $cur->next ) {
        push @docs, $doc->content;
    }

    is_deeply( [ sort { $a->{name} cmp $b->{name} } @docs ], $expect );

    like exception {
        my $guard = mock_guard( 'ArangoDB::Connection', { http_put => sub {die}, } );
        $db->collection('test3')->range( { "x.a", 1, 2 } );
    }, qr/^Failed to call Simple API\(range\) for the collection/;

};

subtest 'simple query - near' => sub {
    my $db = ArangoDB->new($config);

    my $coll = $db->collection('test4');
    my $id   = 0;
    $coll->save( { id => $id++, loc => [ 0,  0 ] } );
    $coll->save( { id => $id++, loc => [ 20, 20 ] } );
    $coll->save( { id => $id++, loc => [ 1,  -5 ] } );
    $coll->save( { id => $id++, loc => [ 10, 10 ] } );
    $coll->save( { id => $id++, loc => [ 20, 10 ] } );

    like exception { $coll->near( 0, 0 ) }, qr/^Failed to call Simple API\(near\)/;

    $coll->ensure_geo_index( [qw/loc/] );
    my $cur = $coll->near( 0, 0, { limit => 2 } );
    my @docs;
    while ( my $doc = $cur->next ) {
        push @docs, $doc->content;
    }

    my $expect = [ { id => 0, loc => [ 0, 0 ] }, { id => 2, loc => [ 1, -5 ] }, ];

    is_deeply( [ sort { $a->{id} <=> $b->{id} } @docs ], $expect );

};

subtest 'simple query - within' => sub {
    my $db = ArangoDB->new($config);

    my $coll = $db->collection('test5');
    my $id   = 0;
    $coll->save( { id => $id++, loc => [ 0,  1 ] } );
    $coll->save( { id => $id++, loc => [ 20, 20 ] } );
    $coll->save( { id => $id++, loc => [ 1,  -5 ] } );
    $coll->save( { id => $id++, loc => [ 10, 10 ] } );
    $coll->save( { id => $id++, loc => [ 20, 10 ] } );

    like exception { $coll->within( 0, 0, 10 ) }, qr/^Failed to call Simple API\(within\)/;

    $coll->ensure_geo_index( [qw/loc/] );
    my $cur = $coll->within( 0, 0, 1000 * 1000 );
    my @docs;
    while ( my $doc = $cur->next ) {
        push @docs, $doc->content;
    }

    my $expect = [ { id => 0, loc => [ 0, 1 ] }, { id => 2, loc => [ 1, -5 ] }, ];
    is_deeply [ sort { $a->{id} <=> $b->{id} } @docs ], $expect;

    $cur = $coll->within( 0, 0, 2000 * 1000, { distance => 'dist', limit => 2 } );
    @docs = ();
    while ( my $doc = $cur->next ) {
        push @docs, $doc->content;
    }
    $expect = [ { id => 0, loc => [ 0, 1 ] }, { id => 2, loc => [ 1, -5 ] }, ];
    is_deeply [ map { $_->{id} } sort { $a->{id} <=> $b->{id} } @docs ], [ 0, 2 ];
    ok exists $docs[0]->{dist};
    ok exists $docs[1]->{dist};

};

subtest 'simple query - fulltext' => sub {
    plan 'skip_all' => 'Tests for API 1.2 or later' if $api_version ne '1.2';

    my $db   = ArangoDB->new($config);
    my $coll = $db->collection('test6');
    $coll->save( { name => 'foo bar',       x => { a => 1, b => 2 } } );
    $coll->save( { name => 'bar xxx foo',   x => { a => 2, b => 2 } } );
    $coll->save( { name => 'baz',           x => { a => 3, b => 2 } } );
    $coll->save( { name => 'qux',           x => { b => 1, a => 1 } } );
    $coll->save( { name => 'xxx foo x qux', x => { b => 1, a => 1 } } );
    my $index = $coll->ensure_fulltext_index('name');

    my $cur = $coll->fulltext( 'name', 'foo', { index => $index->id } );
    isa_ok $cur, 'ArangoDB::Cursor';

    my @docs;
    while ( my $doc = $cur->next ) {
        push @docs, $doc->content;
    }

    is scalar(@docs), 3;

    my $e = exception {
        my $guard = mock_guard( 'ArangoDB::Connection', { http_put => sub {die}, } );
        $coll->fulltext('foo');
    };
    like $e, qr/^Failed to call Simple API\(fulltext\) for the collection/;

};

subtest 'simple query - remove_by_example' => sub {
    my $db = ArangoDB->new($config);

    my $coll = $db->collection('test7');
    $coll->save( { name => 'foo', x => { a => 1, b => 2 } } );
    $coll->save( { name => 'bar', x => { a => 2, b => 2 } } );
    $coll->save( { name => 'baz', x => { a => 3, b => 2 } } );
    $coll->save( { name => 'qux', x => { b => 1, a => 1 } } );

    my $deleted = $coll->remove_by_example( { "x.a" => 1 } );
    is $deleted, 2;

    my $cur = $coll->all();
    my @docs;
    while ( my $doc = $cur->next ) {
        push @docs, $doc->content;
    }
    my $expect = [ { name => 'bar', x => { a => 2, b => 2 } }, { name => 'baz', x => { a => 3, b => 2 } }, ];

    is_deeply( [ sort { $a->{name} cmp $b->{name} } @docs ], $expect );

    my $e = exception {
        my $guard = mock_guard( 'ArangoDB::Connection', { http_put => sub {die}, } );
        $db->collection('test7')->remove_by_example( { "x.a" => 1 } );
    };
    like $e, qr/^Failed to call Simple API\(remove_by_example\) for the collection/;
};

subtest 'simple query - replace_by_example' => sub {
    my $db = ArangoDB->new($config);

    my $coll = $db->collection('test8');
    $coll->save( { name => 'foo', x => { a => 1, b => 2 } } );
    $coll->save( { name => 'bar', x => { a => 2, b => 2 } } );
    $coll->save( { name => 'baz', x => { a => 3, b => 2 } } );
    $coll->save( { name => 'qux', x => { b => 1, a => 1 } } );

    my $replaced = $coll->replace_by_example( { "x.a" => 1 }, { name => 'abc' } );
    is $replaced, 2;

    my $cur = $coll->all();
    my @docs;
    while ( my $doc = $cur->next ) {
        push @docs, $doc->content;
    }
    my $expect = [
        { name => 'abc' },
        { name => 'abc' },
        { name => 'bar', x => { a => 2, b => 2 } },
        { name => 'baz', x => { a => 3, b => 2 } },
    ];
    is_deeply( [ sort { $a->{name} cmp $b->{name} } @docs ], $expect );

    my $e = exception {
        my $guard = mock_guard( 'ArangoDB::Connection', { http_put => sub {die}, } );
        $db->collection('test8')->replace_by_example( { "x.a" => 1 } );
    };
    like $e, qr/^Failed to call Simple API\(replace_by_example\) for the collection/;
};

subtest 'simple query - update_by_example' => sub {
    my $db = ArangoDB->new($config);

    my $coll = $db->collection('test9');
    $coll->save( { name => 'foo', x => { a => 1, b => 2 } } );
    $coll->save( { name => 'bar', x => { a => 2, b => 2 } } );
    $coll->save( { name => 'baz', x => { a => 3, b => 2 } } );
    $coll->save( { name => 'qux', x => { b => 1, a => 1 } } );

    my $updated = $coll->update_by_example( { "x.b" => 1 }, { name => 'abc', x => { b => undef } }, { keepNull => 1 } );
    is $updated, 1;

    my $cur = $coll->all();
    my @docs;
    while ( my $doc = $cur->next ) {
        push @docs, $doc->content;
    }
    my $expect = [
        { name => 'abc', x => { b => undef, a => 1 } },
        { name => 'bar', x => { a => 2,     b => 2 } },
        { name => 'baz', x => { a => 3,     b => 2 } },
        { name => 'foo', x => { a => 1,     b => 2 } },
    ];
    is_deeply( [ sort { $a->{name} cmp $b->{name} } @docs ], $expect );

    $coll->update_by_example( { "x.a" => 1 }, { name => 'foo', x => { b => undef } } );
    $cur  = $coll->all();
    @docs = ();
    while ( my $doc = $cur->next ) {
        push @docs, $doc->content;
    }
    $expect = [
        { name => 'bar', x => { a => 2, b        => 2 } },
        { name => 'baz', x => { a => 3, b        => 2 } },
        { name => 'foo', x => { a => 1 } },
        { name => 'foo', x => { a => 1 } },

    ];
    is_deeply( [ sort { $a->{name} cmp $b->{name} } @docs ], $expect );

    my $e = exception {
        my $guard = mock_guard( 'ArangoDB::Connection', { http_put => sub {die}, } );
        $db->collection('test8')->update_by_example( { "x.a" => 1 } );
    };
    like $e, qr/^Failed to call Simple API\(update_by_example\) for the collection/;
};

done_testing;
