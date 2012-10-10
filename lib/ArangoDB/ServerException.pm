package ArangoDB::ServerException;
use strict;
use warnings;
use Class::Accessor::Lite ( new => 1, ro => [qw/code status detail/] );

1;
__END__

=pod

=head1 NAME

ArangoDB::ServerException

=head1 DESCRIPTION

Exception class that thrown by client when the server returns an error response.

=head1 METHODS

=head2 new()

Constructor.

=head2 code()

Returns HTTP response code.

=head2 status()

Returns HTTP status.

=head2 detail()

Returns detail information of server error.

=cut