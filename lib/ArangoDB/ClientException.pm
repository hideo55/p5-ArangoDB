package ArangoDB::ClientException;
use strict;
use warnings;
use Class::Accessor::Lite ( ro => [qw/message package file line subrutine/] );
use overload
    q{""} => sub { $_[0]->message },
    fallback => 1;

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

=pod

=head1 NAME

ArangoDB::ClientException

=head1 DESCRIPTION

Exception class that thrown by client when the client use invalid bind variables.

=head1 METHODS

=head2 new()

Constructor.

=head2 message()

Returns error message.

=head2 package()

Returns package name of the error occured.

=head2 file()

Returns file name of the error occured.

=head2 line()

Returns line number of the error occured.

=head2 subroutine()

Returns subroutine name of the error occured.

=cut