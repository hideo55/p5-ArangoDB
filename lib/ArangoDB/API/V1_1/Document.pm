package ArangoDB::API::V1_1::Document;
use strict;
use warnings;
use parent 'ArangoDB::Document';

sub partial_update {
    my ( $self, $value, $keep_null ) = @_;
    if (defined $keep_null) {
        $keep_null
            = $keep_null
            ? '?keepNull=true'
            : '?keepNull=false';
    }
    else {
        $keep_null = q{};
    }
    eval { $self->{connection}->http_patch( $self->_api_path . $keep_null, $value ); };
    if ($@) {
        $self->_server_error_handler( $@, 'partialy update' );
    }
    $self->fetch(1);
    return $self;
}

1;
__END__
