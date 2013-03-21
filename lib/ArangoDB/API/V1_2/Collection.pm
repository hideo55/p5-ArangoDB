package ArangoDB::API::V1_2::Collection;
use strict;
use warnings;
use 5.010000;
use parent 'ArangoDB::API::V1_1::Collection';
use ArangoDB::Constants qw(:api :collection_type);
use ArangoDB::Index::Fulltext;
use constant { _DOCUMENT_CLASS => 'ArangoDB::API::V1_2::Document', };

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

sub fulltext {
    my ( $self, $attr, $query, $options ) = @_;
    $options ||= {};
    my $data = { collection => $self->{id}, attribute => $attr, query => $query };
    map { $data->{$_} = $options->{$_} } grep { exists $options->{$_} } qw(limit skip index);
    my $res = eval { $self->{connection}->http_put( API_SIMPLE_FULLTEXT, $data ) };
    if ($@) {
        $self->_server_error_handler( $@, 'Failed to call Simple API(fulltext) for the collection(%s)' );
    }
    return ArangoDB::Cursor->new( $self->{connection}, $res, $self->_DOCUMENT_CLASS );
}

sub remove_by_example {
    my ( $self, $example, $options ) = @_;
    $options ||= {};
    my $data = { collection => $self->{id}, example => $example, };
    if ( defined $data->{waitForSync} ) {
        $data->{waitForSync} = $options->{waitForSync} ? JSON::true : JSON::false;
    }
    if ( defined $data->{limit} ) {
        $data->{limit} = $options->{limit};
    }
    my $res = eval { $self->{connection}->http_put( API_SIMPLE_REMOVE_EXAMPLE, $data ) };
    if ($@) {
        $self->_server_error_handler( $@, 'Failed to call Simple API(remove_by_example) for the collection(%s)' );
    }
    return $res->{deleted};
}

sub replace_by_example {
    my ( $self, $example, $new_value, $options ) = @_;
    $options ||= {};
    my $data = { collection => $self->{id}, example => $example, newValue => $new_value, };
    if ( defined $data->{waitForSync} ) {
        $data->{waitForSync} = $options->{waitForSync} ? JSON::true : JSON::false;
    }
    if ( defined $data->{limit} ) {
        $data->{limit} = $options->{limit};
    }
    map { $data->{$_} = $options->{$_} } grep { exists $options->{$_} } qw(limit waitForSync);
    my $res = eval { $self->{connection}->http_put( API_SIMPLE_REPLACE_EXAMPLE, $data ) };
    if ($@) {
        $self->_server_error_handler( $@, 'Failed to call Simple API(replace_by_example) for the collection(%s)' );
    }
    return $res->{replaced};
}

sub update_by_example {
    my ( $self, $example, $new_value, $options ) = @_;
    $options ||= {};
    my $data = { collection => $self->{id}, example => $example, newValue => $new_value, };
    for my $key ( grep { exists $options->{$_} } qw{keepNull waitForSync} ) {
        $data->{$key} = $options->{$key} ? JSON::true : JSON::false;
    }
    if ( defined $data->{limit} ) {
        $data->{limit} = $options->{limit};
    }
    my $res = eval { $self->{connection}->http_put( API_SIMPLE_UPDATE_EXAMPLE, $data ) };
    if ($@) {
        $self->_server_error_handler( $@, 'Failed to call Simple API(update_by_example) for the collection(%s)' );
    }
    return $res->{updated};
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
