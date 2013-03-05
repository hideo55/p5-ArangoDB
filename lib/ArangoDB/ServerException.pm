package ArangoDB::ServerException;
use strict;
use warnings;
use utf8;
use 5.010000;
use Class::Accessor::Lite ( new => 1, ro => [qw/code status detail/] );

1;
__END__