package ArangoDB::Graph::Element;
use strict;
use warnings;
use parent 'ArangoDB::AbstractDocument';
use overload
    q{""}    => sub { shift->name },
    fallback => 1;

our $VERSION = '0.08';

sub new {
    my ( $class, $conn, $graph_id, $vertex ) = @_;
    my $self = $class->SUPER::new( $conn, $vertex );
    $self->{_graph} = $graph_id;
    return $self;
}

sub name {
    $_[0]->{_key};
}


sub partial_update {
    my ( $self, $value, $keep_null ) = @_;
    if ( defined $keep_null ) {
        $keep_null
            = $keep_null
            ? '?keepNull=true'
            : '?keepNull=false';
    }
    else {
        $keep_null = q{};
    }
    eval { 
        $self->{connection}->http_patch( $self->_api_path . $keep_null, $value ); 
    };
    if ($@) {
        $self->_server_error_handler( $@, 'partialy update' );
    }
    return $self;
}

1;
__END__