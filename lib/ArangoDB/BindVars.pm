package ArangoDB::BindVars;
use strict;
use warnings;

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
    my ( $self, $name, $val ) = @_;
    if ( ArangoDB::BindVars::Validator::is_hash_ref($name) ) {
        ArangoDB::BindVars::Validator::validate($name);
        $self->{_values} = $name;
    }
    elsif ( ArangoDB::BindVars::Validator::is_integer($name) || ArangoDB::BindVars::Validator::is_string($name) ) {
        ArangoDB::BindVars::Validator::validate($val);
        $self->{_values}{$name} = $val;
    }
}

sub count {
    return scalar keys %{ $_[0]->{_values} };
}

{

    package#Hiding package
        ArangoDB::BindVars::Validator;
    use strict;
    use warnings;
    use Scalar::Util qw(looks_like_number);
    use ArangoDB::ClientException;

    sub is_bool {
        !defined( $_[0] ) || $_[0] eq "" || "$_[0]" eq '1' || "$_[0]" eq '0';
    }

    sub is_string {
        defined( $_[0] ) && ref( \$_[0] ) eq 'SCALAR';
    }

    sub is_number {
        !ref( $_[0] ) && looks_like_number( $_[0] );
    }

    sub is_integer {
        defined( $_[0] ) && !ref( $_[0] ) && $_[0] =~ /^-?[0-9]+$/;
    }

    sub is_array_ref {
        defined( $_[0] ) && ref( $_[0] ) eq 'ARRAY';
    }

    sub is_hash_ref {
        defined( $_[0] ) && ref( $_[0] ) eq 'HASH';
    }

    sub validate {
        my $val = shift;
        return if is_string($val) || is_integer($val) || is_number($val) || is_bool($val);
        if ( is_array_ref($val) ) {
            for my $v (@$val) {
                validate($v);
            }
            return;
        }
        die ArangoDB::ClientException->new('Invalid bind parameter value');
    }
}

1;
__END__

=pod

=head1 NAME

ArangoDB::BindVars

=head1 DESCRIPTION

A simple container for bind variables.

=head1 METHODS

=head2 new()

Constructor.

=head2 get_all()

Returns all bind variables.

=head2 get($key)

Returns bind variable.

=head2 set($vars)
=head2 set( $key => $val )

Set bind variable(s).
$vars is HASH reference that set of key/value pairs.

=head1 AUTHOR

Hideaki Ohno E<lt>hide.o.j55 {at} gmail.comE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
