use strict;
use Test::More;
use Test::Fatal qw(exception lives_ok);
use ArangoDB;

my $db = ArangoDB->new(
    {   host        => 'localhost',
        port        => 8529,
        timeout     => 10,
        keep_alive  => 1,
        use_proxy   => 1,
        auth_type   => 'Basic',
        auth_user   => 'tesuser',
        auth_passwd => 'testuserpw'
    }
);

isa_ok( $db, "ArangoDB" );

lives_ok {
    ArangoDB->new( { host => 'localhost' } );
};

like exception {
    ArangoDB->new(
        {   host => {},
            port => 8529,
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

like exception {
    ArangoDB->new(
        {   host    => 'localhost',
            timeout => 'foo',
        }
    );
}, qr/^timeout should be an integer/;

like exception {
    ArangoDB->new(
        {   host    => 'localhost',
            auth_user => [],
        }
    );
}, qr/^auth_user should be a string/;

like exception {
    ArangoDB->new(
        {   host    => 'localhost',
            auth_passwd => [],
        }
    );
}, qr/^auth_passwd should be a string/;

ok exception{ $db->find('foo') };

done_testing;
