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