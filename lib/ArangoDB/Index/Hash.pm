package ArangoDB::Index::Hash;
use strict;
use warnings;
use parent 'ArangoDB::Index';
use Class::Accessor::Lite ( ro => [qw/fields unique/], );

sub new {
    my $class = shift;
    return $class->SUPER::new(@_);
}

1;
__END__

=pod

=head1 NAME

ArangoDB::Index::Hash

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

=cut
