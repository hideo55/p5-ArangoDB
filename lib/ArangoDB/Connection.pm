package ArangoDB::Connection;
use strict;
use warnings;
use Furl;
use JSON;
use MIME::Base64;
use ArangoDB::ConnectOptions;
use ArangoDB::ServerException;

use Class::Accessor::Lite ( ro => [qw/options/] );

sub new {
    my ( $class, $options ) = @_;
    my $self = bless {}, $class;
    my $opts = ArangoDB::ConnectOptions->new($options);
    my $furl = Furl->new(
        timeout => $opts->timeout,
        headers => [ 'Connection' => $opts->keep_alive ? 'Keep-Alive' : 'Close', ],
        proxy   => $opts->proxy,
    );
    $self->{_http_agent} = $furl;
    $self->{api_str}     = 'http://' . $opts->host . ':' . $opts->port;
    if ( $opts->auth_type && $opts->auth_user ) {
        $self->{auth_info}
            = sprintf( '%s %s', $opts->auth_type, encode_base64( $opts->auth_user . ':' . $opts->auth_passwd ) );
    }
    $self->{options} = $opts;
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
    $data = encode_json( defined $data ? $data : {} );
    my $url     = $self->{api_str} . $path;
    my $headers = $self->_build_headers($data);
    my $res     = $self->{_http_agent}->post( $url, $headers, $data );
    return $self->_parse_response($res);
}

sub http_post_raw {
    my ( $self, $path, $data ) = @_;
    my $url     = $self->{api_str} . $path;
    my $headers = $self->_build_headers($data);
    my $res     = $self->{_http_agent}->post( $url, $headers, $data );
    return $self->_parse_response($res);
}

sub http_put {
    my ( $self, $path, $data ) = @_;
    $data = encode_json( defined $data ? $data : {} );
    my $url     = $self->{api_str} . $path;
    my $headers = $self->_build_headers($data);
    my $res     = $self->{_http_agent}->put( $url, $headers, $data );
    return $self->_parse_response($res);
}

sub http_delete {
    my ( $self, $path ) = @_;
    my $url     = $self->{api_str} . $path;
    my $headers = $self->_build_headers();
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

    if ( exists $self->{auth_info} ) {
        push @headers, Authorization => $self->{auth_info};
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
        die ArangoDB::ServerException->new( code => $code, status => $status, detail => {} );
    }
    my $data = decode_json( $res->body );
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
