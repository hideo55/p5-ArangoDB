package ArangoDB::API::V1_2::Collection;
use strict;
use warnings;
use parent 'ArangoDB::API::V1_1::Collection';
use ArangoDB::Constants qw(:api :collection_type);
use ArangoDB::Index::Fulltext;
use constant {
    _DOCUMENT_CLASS => 'ArangoDB::API::V1_2::Document',
};

sub is_volatile {
    my $self = shift;
    my $res  = $self->_get_from_this('properties');
    my $ret  = $res->{isVolatile} eq 'true' ? 1 : 0;
    return $ret;
}

sub revision {
    my $self = shift;
    my $res  = $self->_get_from_this('revision');
    return $res->{revision};
}

sub ensure_fulltext_index {
    my ( $self, $field, $min_length ) = @_;
    my $api = API_INDEX . '?collection=' . $self->{id};
    my $data = { type => 'fulltext', fields => [$field], };
    if ( defined $min_length ) {
        $data->{minLength} = $min_length;
    }
    my $res = eval { $self->{connection}->http_post( $api, $data ) };
    if ($@) {
        $self->_server_error_handler( $@, 'Failed to create fulltext index on the collection(%s)' );
    }
    return ArangoDB::Index::Fulltext->new( $self->{connection}, $res );
}

sub _get_index_instance {
    my ( $self, $index ) = @_;
    my $type = $index->{type} || q{};
    my $conn = $self->{connection};
    if ( $type eq 'fulltext' ) {
        return ArangoDB::Index::Fulltext->new( $conn, $index );
    }
    else {
        return $self->SUPER::_get_index_instance($index);
    }
}

1;
__END__
