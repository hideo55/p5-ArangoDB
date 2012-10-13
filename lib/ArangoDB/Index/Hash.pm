package ArangoDB::Index::Hash;
use strict;
use warnings;
use parent 'ArangoDB::Index';
use Class::Accessor::Lite ( ro => [qw/fields unique/], );

1;
__END__

=pod

=head1 NAME

ArangoDB::Index::Hash - An ArangoDB Hash Index

=head1 DESCRIPTION

Instance of ArangoDB hash index.

=head1 METHODS

=head2 new()

Constructor.

=head2 id()

Identifier of index.

=head2 type()

Index type.

=head2 fields()

List of attribute paths.

=head2 unique()

If it is true, it is a unique index.

=head1 SEE ALSO

L<ArangoDB::Index>

=head1 AUTHOR

Hideaki Ohno E<lt>hide.o.j55 {at} gmail.comE<gt>

=cut
