package ArangoDB::Index::Geo;
use strict;
use warnings;
use parent 'ArangoDB::Index';
use Class::Accessor::Lite ( ro => [qw/fields geoJson constraint/], );

sub new {
    my $class = shift;
    return $class->SUPER::new(@_);
}

1;
__END__

=pod

=head1 NAME

ArangoDB::Index::Geo;

=head1 DESCRIPTION

Instance of ArangoDB geo index.

=head1 METHODS

=head2 new()

Constructor.

=head2 id()

Identifier of index.

=head2 type()

Index type.

=head2 fields()

List of attribure paths.

=head2 geoJson()

If it is true, This geo-spatial index is using geojson format.

=haed2 constraint()

If it is true, this index is geo-spatial constraint.

=cut
