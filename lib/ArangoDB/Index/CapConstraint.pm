package ArangoDB::Index::CapConstraint;
use strict;
use warnings;
use parent 'ArangoDB::Index';
use Class::Accessor::Lite ( ro => [qw/size/], );

1;
__END__

=pod

=head1 NAME

ArangoDB::Index::CapConstraint - An ArangoDB Cap Constraint

=head1 DESCRIPTION

Instance of ArangoDB cap constraint.

=head1 METHODS

=head2 new()

Constructor.

=head2 id()

Identifier of cap constraint.

=head2 type()

Index type.

=head2 size()

Restriction size of collection.

=head1 SEE ALSO

L<ArangoDB::Index>

=head1 AUTHOR

Hideaki Ohno E<lt>hide.o.j55 {at} gmail.comE<gt>

=cut
