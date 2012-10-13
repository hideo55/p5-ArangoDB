package t::lib::Prove::Plugin::StartArangoDB;
use strict;
use warnings;
use Test::More;
use Test::TCP;
use File::Temp;

our $ARANGODB;
our $TMP_DIR;

sub load {
    if( my $arangodb_port = $ENV{TEST_ARANGODB_PORT} ){
        diag 'TEST_ARANGODB_PORT explicitly set. Not starting ArangoDB.';
        return;
    }
    
    $TMP_DIR = File::Temp->newdir;
    
    $ARANGODB = Test::TCP->new(
        code => sub {
            my $port = shift;
            diag "Starting arangod on 127.0.0.1:$port";
            my $dir = $TMP_DIR->dirname;
            eval{
                exec "arangod --server.http-port $port $dir";
            };
            if( $@ ) {
                diag $@;
            }
        }
    );
    
    $ENV{TEST_ARANGODB_PORT} = $ARANGODB->port;
}

END{
    undef $ARANGODB;
    undef $TMP_DIR; 
}

1;
__END__