package ArangoDB::Index::Geo;
use strict;
use warnings;
use parent 'ArangoDB::Index';
use Class::Accessor::Lite ( ro => [qw/fields geoJson constraint/], );

1;
__END__

=pod

=head1 NAME

ArangoDB::Index::Geo - An ArangoDB Geo Index

=head1 DESCRIPTION

Instance of ArangoDB geo index.

=head1 METHODS

=head2 new()

Constructor.

=head2 id()

Returns identifier of index.

=head2 type()

Returns type of index.

=head2 collection_id()

Returns identifier of the index.

=head2 drop()

Drop the index.

=head2 fields()

List of attribure paths.

=head2 geoJson()

If it is true, This geo-spatial index is using geojson format.

=head2 constraint()

If it is true, this index is geo-spatial constraint.

=head1 AUTHOR

Hideaki Ohno E<lt>hide.o.j55 {at} gmail.comE<gt>

=cut
