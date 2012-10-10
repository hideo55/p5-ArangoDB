package ArangoDB::Edge;
use strict;
use warnings;
use parent 'ArangoDB::Document';

sub new {
    my ($class, $raw_edge) = @_;
    my $self = $class->SUPER::new($raw_edge);
    $self->{_from} = delete $self->{document}{_from};
    $self->{_to} = delete $self->{document}{_to};
    $self = bless $self, $class;
    return $self;
}

sub from {
    return $_[0]->{_from};
}

sub to {
    return $_[0]->{_to};
}

1;
__END__

=pod

=head1 NAME

ArangoDB::Edge

=head1 DESCRIPTION

Instance of ArangoDB edge.

=head1 METHODS

=head2 new()

Constructor.

=head2 from()

Returns document id that start of the edge.

=head2 to()

Returns document id that end of the edge.

=head2 id()

Returns id of the document.

=head2 revision()

Returns revision of the document.

=head2 content()

Returns content of the document.

=cut
