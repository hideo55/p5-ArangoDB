package ArangoDB::Connection;
use strict;
use warnings;
use Furl;
use MIME::Base64;
use JSON;

use ArangoDB::ConnectOptions;
use ArangoDB::ServerException;

use Class::Accessor::Lite ( ro => [qw/options/] );

sub new {
    my ( $class, $options ) = @_;
    my $self = bless {}, $class;
    $self->{options} = ArangoDB::ConnectOptions->new($options);
    my $furl = Furl->new( timeout => $self->{options}->timeout );
    if ( $self->{options}->use_proxy ) {
        $furl->env_proxy();
    }
    $self->{_http_agent} = $furl;
    my $api_str = 'http://' . $self->{options}->host;
    if ( my $port = $self->{options}->port ) {
        $api_str .= ':' . $port;
    }
    $self->{api_str} = $api_str;

    return $self;
}

sub http_get {
    my ( $self, $path ) = @_;
    my $url     = $self->{api_str} . $path;
    my $headers = $self->_build_headers();
    my $res     = $self->{_http_agent}->get( $url, $headers );
    return $self->_parse_response($res);
}

sub http_post {
    my ( $self, $path, $data ) = @_;
    $data = defined $data ? encode_json($data) : q{};
    my $url     = $self->{api_str} . $path;
    my $headers = $self->_build_headers($data);
    my $res     = $self->{_http_agent}->post( $url, $headers, $data );
    return $self->_parse_response($res);
}

sub http_put {
    my ( $self, $path, $data ) = @_;
    $data = defined $data ? encode_json($data) : q{};
    my $url     = $self->{api_str} . $path;
    my $headers = $self->_build_headers($data);
    my $res     = $self->{_http_agent}->put( $url, $headers, $data );
    return $self->_parse_response($res);
}

sub http_delete {
    my ( $self, $path ) = @_;
    my $url     = $self->{api_str} . $path;
    my $headers = $self->_build_headers($url);
    my $res     = $self->{_http_agent}->delete( $url, $headers );
    return $self->_parse_response($res);
}

sub _build_headers {
    my ( $self, $body ) = @_;
    my $content_length = length( $body || q{} );
    my $options        = $self->{options};
    my @headers        = ();

    push @headers, Host => $options->host;

    if ( $content_length > 0 ) {
        push @headers, 'Content-Type' => 'application/json';
    }

    if ( $options->auth_type && $options->auth_user ) {
        my $auth_value = encode_base64( $options->auth_user . ':' . $options->auth_passwd );
        push @headers, Authorization => sprintf( '%s %s', $options->auth_type, $auth_value );
    }

    if ( my $conn = $options->connection ) {
        push @headers, Connection => $conn;
    }

    return \@headers;
}

sub _parse_response {
    my ( $self, $res ) = @_;
    my $code   = $res->code;
    my $status = $res->status;
    if ( $code < 200 || $code >= 400 ) {
        my $body = $res->body;
        if ( $body ne q{} ) {
            my $details = decode_json($body);
            my $exception = ArangoDB::ServerException->new( code => $code, status => $status, detail => $details );
            die $exception;
        }
        die ArangoDB::ServerException->new( code => $code, status => $status );
    }
    my $data    = decode_json( $res->body );
    return $data;
}

1;
__END__
