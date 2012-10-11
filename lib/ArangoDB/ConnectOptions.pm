package ArangoDB::ConnectOptions;
use strict;
use warnings;
use Data::Util qw(:check);
use List::MoreUtils qw(none);

sub new {
    my ( $class, $options ) = @_;
    my %opts = ( %{ $class->_get_defaults() }, %$options );
    my $self = bless { _options => \%opts }, $class;
    $self->_validate();
    return $self;
}

for my $name (qw/host port timeout keep_alive proxy auth_type auth_user auth_passwd/) {
    next if __PACKAGE__->can($name);
    no strict 'refs';
    *{ __PACKAGE__ . '::' . $name } = sub {
        $_[0]->{_options}{$name};
    };
}

my @supported_auth_type = qw(Basic);

sub _validate {
    my $self    = shift;
    my $options = $self->{_options};
    die "host should be a string"
        if !is_string( $options->{host} );
    die "port should be an integer"
        if $options->{port}
            && !is_integer( $options->{port} );

    die "timeout should be an integer"
        if $options->{timeout}
            && !is_integer( $options->{timeout} );

    if ( $options->{auth_type} && none { $options->{auth_type} eq $_ } @supported_auth_type ) {
        die sprintf( "unsupported auth_type value '%s'", $options->{auth_type} );
    }

    die "auth_user should be a string"   if $options->{auth_user}   && !is_string( $options->{auth_user} );
    die "auth_passwd should be a string" if $options->{auth_passwd} && !is_string( $options->{auth_passwd} );

}

sub _get_defaults {
    return {
        host        => 'localhost',
        port        => 8529,
        timeout     => 5,
        auth_user   => undef,
        auth_passwd => undef,
        auth_type   => undef,
        keep_alive  => 0,
        proxy       => undef,
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

Hostname or IP address of ArangoDB server.
Default: localhost

=item port

Port number of ArangoDB server.
Default: 8529

=item timeout

Seconds of HTTP connection timeout.

=item auth_user

User name for authentication

=item auth_passwd

Password for authentication

=item auth_type

Authentication method.
Supporting "Basic" only.

=item keep_alive

If it is true, use HTTP Keep-Alive connection.
Default: false

=item proxy

HTTP proxy.

=back

=head1 AUTHOR

Hideaki Ohno E<lt>hide.o.j55 {at} gmail.comE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
