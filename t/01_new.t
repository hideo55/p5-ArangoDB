use Test::More;
use ArangoDB;

my $db = ArangoDB->new(
    {   host => 'localhost',
        port => 8529,
    }
);

isa_ok( $db, "ArangoDB" );

done_testing;
