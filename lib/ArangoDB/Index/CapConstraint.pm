package ArangoDB::Index::CapConstraint;
use strict;
use warnings;
use parent 'ArangoDB::Index';
use Class::Accessor::Lite ( ro => [qw/size/], );

sub new {
    my $class = shift;
    return $class->SUPER::new(@_);
}

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

Identifier of cap constraint.

=head2 type()

Index type.

=head2 size()

Restriction size of collection.

=cut
