package ArangoDB::Statement;
use strict;
use warnings;
use overload
    '&{}'    => sub { shift->execute() },
    q{""}    => sub { shift->{query} },
    fallback => 1;

use ArangoDB::Cursor;
use ArangoDB::Constants qw(:api);

sub new {
    my ( $class, $conn, $data ) = @_;
    my $self = bless {}, $class;
    $self->{connection} = $conn;
    $self->{bind_vars}  = ArangoDB::BindVars->new();
    return $self;
}

sub execute {
    my $self = shift;
    my $data = $self->_build_data;
    my $res  = $self->{connection}->http_post( URL_CURSOR, encode_json($data) );
    return ArangoDB::Cursor->new( $self->{connection}, $res->{data}, { sanitize => $self->{sanitize} } );
}

sub bind {
    my ( $self, $key, $value ) = @_;
    $self->{bind_vars}->set( $key => $value );
}

sub bind_vars {
    return shift->{bind_vars}->get_all();
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

    if ( $self->{batch_size} > 0 ) {
        $data{batchSize} = $self->{batch_size};
    }

    return $data;
}

1;
__END__
