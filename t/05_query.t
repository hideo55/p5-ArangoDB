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
    my $users = $db->collection('users');
    $users->save( { name => 'John Doe', age => 42 } );
    $users->save( { name => 'Foo',      age => 10 } );
    $users->save( { name => 'Bar',      age => 11 } );
    $users->save( { name => 'Baz',      age => 20 } );
}

subtest 'Normal statement' => sub {
    my $db  = ArangoDB->new($config);
    my $sth = $db->query('FOR u IN users SORT u.name ASC RETURN u');
    is "$sth", 'FOR u IN users SORT u.name ASC RETURN u';
    my $cur = $sth->execute();
    my @docs;
    while ( my $doc = $cur->next() ) {
        push @docs, $doc->content;
    }
    my $expects = [
        { name => 'Bar',      age => 11 },
        { name => 'Baz',      age => 20 },
        { name => 'Foo',      age => 10 },
        { name => 'John Doe', age => 42 },
    ];
    is_deeply( \@docs, $expects );

    my $e = exception {
        my $guard = mock_guard(
            'ArangoDB::Connection' => {
                http_post => sub {die}
            }
        );
        $sth->execute();
    };
    like $e, qr/^Failed to execute query/;

};

subtest 'Use bind var1' => sub {
    my $db  = ArangoDB->new($config);
    my $sth = $db->query('FOR u IN users FILTER u.age > @age SORT u.name ASC RETURN u');
    $sth->bind( age => 10 );
    is_deeply $sth->bind_vars, { age => 10 };
    is $sth->bind_vars('age'), 10;

    my $cur = $sth->();
    my @docs;
    while ( my $doc = $cur->next() ) {
        push @docs, $doc->content;
    }
    my $expects = [ { name => 'Bar', age => 11 }, { name => 'Baz', age => 20 }, { name => 'John Doe', age => 42 }, ];
    is_deeply( \@docs, $expects );
    my $cur2 = $sth->bind( { age => 20 } )->execute();
    my @docs2;
    while ( my $doc = $cur2->next() ) {
        push @docs2, $doc->content;
    }
    my $expects2 = [ { name => 'John Doe', age => 42 }, ];
    is_deeply( \@docs2, $expects2 );

    my $cur3 = $sth->bind( { age => [ 1 .. 10 ] } )->execute( { do_count => 1 } );
    is $cur3->length, 0;

    my $e = exception {
        $sth->bind( age => {} );
    };
    like $e, qr/^Invalid bind parameter value/;

};

subtest 'batch query' => sub {
    my $db  = ArangoDB->new($config);
    my $sth = $db->query('FOR u IN users FILTER u.age > @age SORT u.name ASC RETURN u');
    $sth->bind( age => 10 );
    my $cur = $sth->execute( { batch_size => 2, do_count => 1 } );
    is $cur->count,  3;
    is $cur->length, 2;
    my @docs;
    while ( my $doc = $cur->next() ) {
        push @docs, $doc->content;
    }
    is scalar @docs, 3;
};

subtest 'delete cursor' => sub {
    my $db  = ArangoDB->new($config);
    my $sth = $db->query('FOR u IN users FILTER u.age > @age SORT u.name ASC RETURN u');
    $sth->bind( age => 10 );
    my $cur = $sth->execute( { batch_size => 2, } );
    $cur->delete;
    my $e = exception {
        while ( my $doc = $cur->next() ) {
        }
    };
    like $e, qr/^Failed to get next batch cursor/;

    $e = exception {
        $cur->delete;
    };
    like $e, qr/^Failed to delete cursor/;

};

subtest 'parse query' => sub {
    my $db    = ArangoDB->new($config);
    my $binds = $db->query('FOR u IN users SORT u.name ASC RETURN u')->parse();
    is scalar @$binds, 0;

    $binds = $db->query('FOR u IN users FILTER u.age > @age SORT u.name ASC RETURN u')->parse();
    is_deeply $binds, [qw/age/];

    my $e = exception {
        $binds = $db->query('FOR u IN users FILTER u.age > @age SORT u.name ASC RETUR')->parse();
    };
    like $e, qr/^Failed to parse query/;
};

subtest 'explain query' => sub{
    my $db    = ArangoDB->new($config);
    my $plan = $db->query('FOR u IN users SORT u.name ASC RETURN u')->explain();
    ok $plan && ref($plan) eq 'ARRAY';
    like exception { $db->query('FOR u IN users SORT u.name ASC RETURN ')->explain(); }, qr/^Failed to explain query/;
};

done_testing;

__END__
