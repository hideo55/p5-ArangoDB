package ArangoDB::Validator;
use strict;
use warnings;
use Data::Util qw(:check);
use ArangoDB::ClientException;

sub is_bool {
    !defined( $_[0] ) || $_[0] eq "" || "$_[0]" eq '1' || "$_[0]" eq '0';
}

sub validate {
    my $val = shift;
    return if is_string($val) || is_integer($val) || is_number($val) || is_bool($val);
    if ( is_array_ref($val) ) {
        map { validate($_) } @$val;
        return;
    }
    die ArangoDB::ClientException->new('Invalid bind parameter value');
}

1;
__END__
