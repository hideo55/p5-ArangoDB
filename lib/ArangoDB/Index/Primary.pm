package ArangoDB::Index::Primary;
use strict;
use warnings;
use parent 'ArangoDB::Index';
use Class::Accessor::Lite ( ro => [qw/fields/], );

sub new {
    my $class = shift;
    return $class->SUPER::new(@_);
}

1;
__END__

=pod

=head1 NAME

ArangoDB::Index::Primary - An ArangoDB Primary Index

=head1 DESCRIPTION

Instance of ArangoDB primary index.

=head1 METHODS

=head2 new()

Constructor.

=head2 id()

Identifier of index.

=head2 type()

Index type.

=head2 fields()

List of attribure paths.

=head1 AUTHOR

Hideaki Ohno E<lt>hide.o.j55 {at} gmail.comE<gt>

=cut
