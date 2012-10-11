package ArangoDB::Index;
use strict;
use warnings;
use overload
    q{""}    => sub { $_[0]->id },
    fallback => 1;
use Class::Accessor::Lite ( new => 1, ro => [qw/id type/] );

1;
__END__

=pod

=head1 NAME

ArangoDB::Index

=head1 DESCRIPTION

Base class of ArangoDB index.

=head1 METHODS

=head2 new()

Constructor.

=head2 id()

Returns identifier of index.

=head2 fields()

Returns list of fields.

=head2 type()

Returns type of index.

=cut
