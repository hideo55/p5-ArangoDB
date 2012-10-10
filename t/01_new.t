use strict;
use Test::More;
use Test::Fatal qw(exception);
use ArangoDB;

my $db = ArangoDB->new(
    {   host       => 'localhost',
        port       => 8529,
        keep_alive => 1,
    }
);

isa_ok( $db, "ArangoDB" );

like exception {
    ArangoDB->new(
        {   host      => {},
            port      => 8529,
            auth_type => 'Basic',
        }
    );
}, qr/^host should be a string/;

like exception {
    ArangoDB->new(
        {   host => 'localhost',
            port => 'foo',
        }
    );
}, qr/^port should be an integer/;

like exception {
    ArangoDB->new(
        {   host      => 'localhost',
            auth_type => 'foo',
        }
    );
}, qr/^unsupported auth_type value 'foo'/;

done_testing;
