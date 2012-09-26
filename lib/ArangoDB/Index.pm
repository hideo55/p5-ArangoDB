package ArangoDB::Index;
use strict;
use warnings;
use Class::Accessor::Lite ( ro => [qw/id fields type/] );

sub new {
    my ( $class, $index_info ) = @_;
    my $self = bless {}, $class;
    map { $self->{$_} = $index_info->{$_} } qw(id type fields);
    return $self;
}

1;
__END__

=pod

=head1 NAME

ArangoDB::Index

=head1 DESCRIPTION

Instance of ArangoDB index.

=cut
