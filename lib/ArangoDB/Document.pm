package ArangoDB::Document;
use strict;
use warnings;
use overload
    '0+'  => sub { shift->id },
    q{""} => sub { shift->id },
    fallback => 1;

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

sub content {
    return $_[0]->{document};
}

1;
__END__

=pod

=head1 NAME

ArangoDB::Document

=head1 DESCRIPTION

Instance of ArangoDB document.

=head1 METHODS

=head2 new()

Constructor.

=head2 id()

Returns id of the document.

=head2 revision()

Returns revision of the document.

=head2 content()

Returns content of the document.

=head1 AUTHOR

Hideaki Ohno E<lt>hide.o.j55 {at} gmail.comE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
