package ArangoDB::Document;
use strict;
use warnings;

sub new {
    my ( $class, $doc ) = @_;
    my $self = bless {}, $class;
    $self->{_id}      = delete $doc->{_id};
    $self->{_rev}     = delete $doc->{_rev};
    $self->{document} = {%$doc};
    return $self;
}

sub id {
    $_[0]->{_id};
}

sub revision {
    $_[0]->{_rev};
}

sub data {
    return $_[0]->{document};
}

1;
__END__
