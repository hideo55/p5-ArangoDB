package ArangoDB::Connection;
use strict;
use warnings;
use utf8;
use 5.008001;
use Furl::HTTP;
use JSON ();
use MIME::Base64;
use ArangoDB::ConnectOptions;
use ArangoDB::ServerException;

use Class::Accessor::Lite ( ro => [qw/options/] );

my $JSON = JSON->new->utf8;

sub new {
    my ( $class, $options ) = @_;
    my $opts = ArangoDB::ConnectOptions->new($options);
    my $headers = [ Host => $opts->host, Connection => $opts->keep_alive ? 'Keep-Alive' : 'Close', ];
    if ( $opts->auth_type && $opts->auth_user ) {
        push @$headers, Authorization =>
            sprintf( '%s %s', $opts->auth_type, encode_base64( $opts->auth_user . ':' . $opts->auth_passwd ) );
    }
    my $furl = Furl::HTTP->new(
        timeout => $opts->timeout,
        headers => $headers,
        proxy   => $opts->proxy,
    );

    my $self = bless {
        options   => $opts,
        _req_args => {
            scheme => 'http',
            host   => $opts->host,
            port   => $opts->port,
        },
        _http_agent => $furl,
    }, $class;

    return $self;
}

sub http_get {
    my ( $self, $path ) = @_;
    my $headers = $self->_build_headers();
    my ( undef, $code, $msg, undef, $body ) = $self->{_http_agent}->request(
        %{ $self->{_req_args} },
        method     => 'GET',
        path_query => $path,
        headers    => $headers,
    );
    return $self->_parse_response( $code, $msg, $body );
}

sub http_post {
    my ( $self, $path, $data ) = @_;
    $data = $JSON->encode( defined $data ? $data : {} );
    my $headers = $self->_build_headers($data);
    my ( undef, $code, $msg, undef, $body ) = $self->{_http_agent}->request(
        %{ $self->{_req_args} },
        method     => 'POST',
        path_query => $path,
        headers    => $headers,
        content    => $data,
    );
    return $self->_parse_response( $code, $msg, $body );
}

sub http_post_raw {
    my ( $self, $path, $data ) = @_;
    my $headers = $self->_build_headers($data);
    my ( undef, $code, $msg, undef, $body ) = $self->{_http_agent}->request(
        %{ $self->{_req_args} },
        method     => 'POST',
        path_query => $path,
        headers    => $headers,
        content    => $data,
    );
    return $self->_parse_response( $code, $msg, $body );
}

sub http_put {
    my ( $self, $path, $data ) = @_;
    $data = $JSON->encode( defined $data ? $data : {} );
    my $headers = $self->_build_headers($data);
    my ( undef, $code, $msg, undef, $body ) = $self->{_http_agent}->request(
        %{ $self->{_req_args} },
        method     => 'PUT',
        path_query => $path,
        headers    => $headers,
        content    => $data,
    );
    return $self->_parse_response( $code, $msg, $body );
}

sub http_delete {
    my ( $self, $path ) = @_;
    my $headers = $self->_build_headers();
    my ( undef, $code, $msg, undef, $body ) = $self->{_http_agent}->request(
        %{ $self->{_req_args} },
        method     => 'DELETE',
        path_query => $path,
        headers    => $headers,
    );
    return $self->_parse_response( $code, $msg, $body );
}

sub _build_headers {
    my ( $self, $body ) = @_;
    my $content_length = length( $body || q{} );
    my @headers = ();
    if ( $content_length > 0 ) {
        push @headers, 'Content-Type' => 'application/json';
    }
    return \@headers;
}

sub _parse_response {
    my ( $self, $code, $status, $body ) = @_;
    if ( $code < 200 || $code >= 400 ) {
        if ( $body ne q{} ) {
            my $details = $JSON->decode($body);
            my $exception = ArangoDB::ServerException->new( code => $code, status => $status, detail => $details );
            die $exception;
        }
        die ArangoDB::ServerException->new( code => $code, status => $status, detail => {} );
    }
    my $data = $JSON->decode($body);
    return $data;
}

1;
__END__

=pod

=head1 NAME

ArangoDB::Connection - A connection to a ArangoDB server.

=head1 DESCRIPTION

The ArangoDB::Connection class creates a connection to the ArangoDB server.

=head1 METHODS

=head2 new($options)

Constructor.
$options if connection option.
It is arguments of L<ArangoDB::ConnectOptions>.

=head2 options

Returns instance of L<ArangoDB::ConnectOptions>.

=head2 http_get($path)

Send GET HTTP request to $path.

=head2 http_post($path,$data)

Send POST HTTP request to $path with $data.
$data is encoded to JSON.

=head2 http_post_raw($path,$raw_data)

Send POST HTTP request to $path with $raw_data.
$raw_data isn't encoded to JSON.

=head2 http_put($path,$data)

Send PUT HTTP request to $path with $data.
$data is encoded to JSON.

=head2 http_delete($path)

Send DELETE HTTP request to $path.

=head1 AUTHOR

Hideaki Ohno E<lt>hide.o.j55 {at} gmail.comE<gt>

=cut
