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

=cut
