package ArangoDB::Index;
use strict;
use warnings;
use Class::Accessor::Lite ( new => 1, ro => [qw/id fields type/] );

1;
__END__

=pod

=head1 NAME

ArangoDB::Index

=head1 DESCRIPTION

Instance of ArangoDB index.

=head1 METHODS

=head2 new()

Constructor.

=head2 id()

Returns identifier of index.

=head2 fields()

Returns list of fields.

=head2 type()

Returns type of index.

=head1 AUTHOR

Hideaki Ohno E<lt>hide.o.j55 {at} gmail.comE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
