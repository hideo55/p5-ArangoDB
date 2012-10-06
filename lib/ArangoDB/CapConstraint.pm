package ArangoDB::CapConstraint;
use strict;
use warnings;
use Class::Accessor::Lite ( new => 1, ro => [qw/id size/], );

1;
__END__

=pod

=head1 NAME

ArangoDB::CapConstraint

=head1 DESCRIPTION

Instance of ArangoDB cap constraint.

=head1 METHODS

=head2 new()

Constructor.

=head2 id()

Returns identifier of cap constraint.

=head2 size()

Returns restriction size of collection.

=head1 AUTHOR

Hideaki Ohno E<lt>hide.o.j55 {at} gmail.comE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
