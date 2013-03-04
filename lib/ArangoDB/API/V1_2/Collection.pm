package ArangoDB::API::V1_2::Collection;
use strict;
use warnings;
use parent 'ArangoDB::API::V1_1::Collection';

sub is_volatile {
    my $self = shift;
    my $res  = $self->_get_from_this('properties');
    my $ret  = $res->{isVolatile} eq 'true' ? 1 : 0;
    return $ret;
}

1;
__END__
