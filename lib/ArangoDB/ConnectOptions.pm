package ArangoDB::ConnectOptions;
use strict;
use warnings;
use Scalar::Util qw(blessed looks_like_number);
use List::MoreUtils qw(none);

sub new {
    my ( $class, $options ) = @_;
    my %opts = ( %{ $class->_get_defaults() }, %$options );
    my $self = bless { _options => \%opts }, $class;
    $self->_validate();

    for my $name ( keys %opts ) {
        next if $class->can($name);
        no strict 'refs';
        *{ $class . '::' . $name } = sub {
            $_[0]->{_options}{$name};
        };
    }

    return $self;
}

my @supported_auth_type = qw(Basic);

my @supported_connection_type = qw(Close Keep-Alive);

my $validator = {
    is_str => sub {
        defined( $_[0] ) && ref( \$_[0] ) eq 'SCALAR';
    },
    is_int => sub {
        defined( $_[0] )
            && !ref( $_[0] )
            && $_[0] =~ /^-?[0-9]+$/;
    },
};

sub _validate {
    my $self    = shift;
    my $options = $self->{_options};
    die "host should be a string"
        if !$validator->{is_str}->( $options->{host} );
    die "port should be an integer"
        if exists( $options->{port} )
            && !$validator->{is_int}->( $options->{port} );

    if ( $options->{auth_type} && none { $options->{auth_type} eq $_ } @supported_auth_type ) {
        die "unsupported authorization method";
    }

    if ( $options->{connection} && none { $options->{connection} eq $_ } @supported_connection_type ) {
        die sprintf( "unsupported connection value '%s'", $options->{connection} );
    }

}

sub _get_defaults {
    return {
        host        => undef,
        port        => 8529,
        timeout     => 5,
        auth_user   => undef,
        auth_passwd => undef,
        auth_type   => undef,
        connection  => 'Close',
        use_proxy   => 0,
    };
}

1;
__END__

=pod

=head1 NAME

ArangoDB::ConnectOptions;

=head1 DESCRIPTION

Connect options of ArangoDB.

=head1 METHODS

=head2 new($options)

Constructor.
$options is a connect option(Hash reference. The attributes of $options are:

=over 4

=item host

=item port

=item timeout

=item auth_user

=item auth_passwd

=item auth_type

=item connection

=item use_proxy

=back

=head1 AUTHOR

Hideaki Ohno E<lt>hide.o.j55 {at} gmail.comE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut