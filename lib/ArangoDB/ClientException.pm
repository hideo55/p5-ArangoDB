package ArangoDB::ClientException;
use strict;
use warnings;
use Class::Accessor::Lite ( ro => [qw/message package file line subrutine/] );

sub new {
    my ( $class, $message ) = @_;
    my @caller_info = caller;
    my $self        = bless {
        message   => $message,
        package   => $caller_info[0],
        file      => $caller_info[1],
        line      => $caller_info[2],
        subrutine => $caller_info[3],
    }, $class;
    return $self;
}

1;
__END__
