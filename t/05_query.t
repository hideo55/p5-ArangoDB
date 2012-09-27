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
};

subtest 'Use bind var1' => sub {
    my $db  = ArangoDB->new($config);
    my $sth = $db->query('FOR u IN users FILTER u.age > @age SORT u.name ASC RETURN u');
    $sth->bind( age => 10 );
    my $cur = $sth->execute();
    my @docs;
    while ( my $doc = $cur->next() ) {
        push @docs, $doc->content;
    }
    my $expects = [ { name => 'Bar', age => 11 }, { name => 'Baz', age => 20 }, { name => 'John Doe', age => 42 }, ];
    is_deeply( \@docs, $expects );
    $sth->bind( age => 20 );
    my $cur2 = $sth->execute();
    my @docs2;
    while ( my $doc = $cur2->next() ) {
        push @docs2, $doc->content;
    }
    my $expects2 = [ { name => 'John Doe', age => 42 }, ];
    is_deeply( \@docs2, $expects2 );
};

done_testing;

__END__
