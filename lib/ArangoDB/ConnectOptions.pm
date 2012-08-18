package ArangoDB::ConnectOptions;
use strict;
use warnings;
use Scalar::Util qw(blessed looks_like_number);
use List::MoreUtils qw(none);

sub new {
    my ( $class, $options ) = @_;
    my %opts = ( %{ get_defaults() }, %$options );
    my $self = bless { _options => \%opts }, $class;
    $self->validate();

    for my $name ( keys %opts ) {
        no strict 'refs';
        *{ 'ArangoDB::ConnectOptions::' . $name } = sub {
            $_[0]->{_options}{$name};
        };
    }

    return $self;
}

my @supported_auth_type = qw(Basic);

my @supported_connection_type = qw(Close Keep-Alive);

my @valid_policy = qw(last error);

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

sub validate {
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

    if ( none { $options->{policy} eq $_ } @valid_policy ) {
        die 'invalid update policy';
    }

}

sub get_defaults {
    return {
        host              => undef,
        port              => 8529,
        timeout           => 5,
        trace             => 0,
        create_connection => 0,
        policy            => 'error',
        wait_for_sync     => undef,
        auth_user         => undef,
        auth_passwd       => undef,
        auth_type         => undef,
        connection        => 'Close',
        use_proxy         => 0,
    };
}

1;
__END__
