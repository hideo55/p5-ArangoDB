use strict;
use Test::More;
use Test::Fatal qw(exception lives_ok);
use ArangoDB;

my $db = ArangoDB->new(
    {   host        => 'localhost',
        port        => 0,
        timeout     => 10,
        keep_alive  => 1,
        use_proxy   => 1,
        auth_type   => 'Basic',
        auth_user   => 'tesuser',
        auth_passwd => 'testuserpw',
        inet_aton   => sub { },
    }
);

isa_ok $db, 'ArangoDB';
isa_ok $db, 'ArangoDB::API::V1_0';
ok exception { $db->find('foo') };

$db = ArangoDB->new( { api => '1.1', } );
isa_ok $db, 'ArangoDB::API::V1_1';

$db = ArangoDB->new( { api => '1.2', } );
isa_ok $db, 'ArangoDB::API::V1_2';

lives_ok {
    ArangoDB->new();
};

like exception {
    ArangoDB->new('foo');
}, qr/^Argument must be HASH reference/;

my $db2 = ArangoDB->new(
    {   port      => 0,
        auth_user => 'testuser',
    }
);
ok !exists $db2->{connection}{auth_info};

my $db3 = ArangoDB->new(
    {   port      => 0,
        auth_type => 'Basic',
    }
);
ok !exists $db2->{connection}{auth_info};

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
        {   host => undef,
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
        {   host => 'localhost',
            port => undef,
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

lives_ok {
    ArangoDB->new(
        {   host    => 'localhost',
            timeout => undef,
        }
    );
};

like exception {
    ArangoDB->new(
        {   host      => 'localhost',
            auth_user => [],
        }
    );
}, qr/^auth_user should be a string/;

like exception {
    ArangoDB->new(
        {   host        => 'localhost',
            auth_passwd => [],
        }
    );
}, qr/^auth_passwd should be a string/;

like exception {
    ArangoDB->new( { 'inet_aton' => {}, } );
}, qr/^inet_aton should be a CODE reference/;

like exception {
    ArangoDB->new( { api => '2.0' } );
}, qr/^\Q'api' must be 1.0, 1.1 or 1.2\E/;

subtest 'check server version' => sub {
    plan 'skip_all' => 'Server not found' if !$ENV{TEST_ARANGODB_PORT};
    my $api_version = $ENV{TEST_ARANGODB_VERSION};
    my $port        = $ENV{TEST_ARANGODB_PORT};
    my $config      = {
        host          => 'localhost',
        port          => $port,
        keep_alive    => 1,
        api           => $api_version,
        check_version => 1,
    };
    lives_ok {
        my $db = ArangoDB->new($config);
        like $db->server_version(), qr/^\Q$api_version\E/;
    };

    my $wrong_version = {
        '1.0' => '1.1',
        '1.1' => '1.2',
        '1.2' => '1.0',
    };
    $config->{api} = $wrong_version->{$api_version};
    like exception {
        ArangoDB->new($config);
    }, qr/^API version not matched/;
};

done_testing;
