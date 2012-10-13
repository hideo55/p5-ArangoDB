package ArangoDB::ServerException;
use strict;
use warnings;
use Class::Accessor::Lite ( new => 1, ro => [qw/code status detail/] );

1;
__END__