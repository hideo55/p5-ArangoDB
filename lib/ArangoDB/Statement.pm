package ArangoDB::Statement;
use strict;
use warnings;
use overload
    '&{}'    => sub { shift->execute() },
    q{""}    => sub { shift->{query} },
    fallback => 1;
use Carp qw(croak);
use ArangoDB::Cursor;
use ArangoDB::BindVars;
use ArangoDB::Constants qw(:api);

sub new {
    my ( $class, $conn, $query, $options ) = @_;
    my $self = bless {
        connection => $conn,
        query      => $query,
    }, $class;
    for my $key ( grep { exists $options->{$_} } qw{batch_size do_count} ) {
        $self->{$key} = $options->{$key};
    }
    $self->{bind_vars} = ArangoDB::BindVars->new();
    return $self;
}

sub execute {
    my $self = shift;
    my $data = $self->_build_data;
    my $res  = eval { $self->{connection}->http_post( API_CURSOR, $data ) };
    if ($@) {
        $self->_server_error_handler( $@, 'Failed to execute query' );
    }
    return ArangoDB::Cursor->new( $self->{connection}, $res );
}

sub bind_vars {
    return shift->{bind_vars}->get_all();
}

sub bind {
    my ($self) = shift;
    if ( @_ == 1 ) {
        $self->{bind_vars}->set( $_[0] );
    }
    else {
        my ( $key, $value ) = @_;
        $self->{bind_vars}->set( $key => $value );
    }
    return;
}

sub _build_data {
    my $self = shift;
    my $data = {
        query => $self->{query},
        count => $self->{do_count},
    };

    if ( $self->{bind_vars}->count > 0 ) {
        $data->{bindVars} = $self->{bind_vars}->get_all();
    }

    if ( exists $self->{batch_size} && $self->{batch_size} > 0 ) {
        $data->{batchSize} = $self->{batch_size};
    }

    return $data;
}

sub _server_error_handler {
    my ( $self, $error, $message ) = @_;
    if ( ref($error) && $error->isa('ArangoDB::ServerException') ) {
        $message .= ':' . ( $error->detail->{errorMessage} || q{} );
    }
    croak $message;
}

1;
__END__


=pod

=head1 NAME

ArangoDB::Statement

=head1 SYNOPSIS

    use ArangoDB;
    
    my $db = ArangoDB->new({
        host => 'localhost',
        port => 8529,
    });
  
    my $sth = $db->query('FOR u IN users FILTER u.active == true');
    my $cur = $sth->execute();
    while( my $doc = $cur->next() ){
        # do something
    }
  
    # Use bind variable
    $sth = $db->query('FOR u IN users FILTER u.name == @name');
    $sth->bind( name => 'John Doe' );
        


=head1 DESCRIPTION

A AQL(Arango Query Language) statement handler.

=head1 METHODS

=head2 new($conn,$query,$options)

Constructor.

$conn is instance of ArangoDB::Connection.
$query is AQL statement.
$options is query options.The attributes of $options are:

=over 4

=item batch_size

Maximum number of result documents to be transferred from the server to the client in one roundtrip (optional). 

=item do_count

Boolean flag that indicates whether the number of documents found should be returned as "count" attribute in the result set (optional).

=back

=head2 execute()

Execute AQL query and returns cursor(instance of ArangoDB::Cursor).

=head2 bind_vars()

Returns all bind variables.

=head2 bind($vars)
=head2 bind($key => $val)

Set bind variable(s).
$vars is HASH reference that set of key/value pairs.

=head2 validate_query()

=head1 AUTHOR

Hideaki Ohno E<lt>hide.o.j55 {at} gmail.comE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
