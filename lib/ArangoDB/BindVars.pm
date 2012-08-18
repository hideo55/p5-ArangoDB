package ArangoDB::BindVars;
use strict;
use warnings;
use Data::Util qw(:check);
use ArangoDB::Validator;

sub new {
    my $class = shift;
    my $self = bless { _values => +{} }, $class;
    return $self;
}

sub get_all {
    $_[0]->{_values};
}

sub get {
    $_[0]->{_values}{ $_[1] };
}

sub set {
    if ( is_hash_ref( $_[1] ) ) {
        ArangoDB::Validator::validate( $_[1] );
        $_[0]->{_values} = $_[1];
    }
    elsif ( is_integer( $_[1] ) && is_string( $_[1] ) ) {
        ArangoDB::Validator::validate( $_[2] );
        $self->{_values}{ $_[1] } = $_[2];
    }
}

sub count {
    scalar keys %{ $_[0]->{_values} };
}

1;
__END__
