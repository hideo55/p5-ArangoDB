package ArangoDB::Cursor;
use strict;
use warnings;
use ArangoDB::Document;

sub new {
    my ( $class, $conn, $data, $options ) = @_;
    my $self = bless {
        connection => $conn,
        id         => undef,
        options    => $options,
        result     => [],
        position   => 0,
        length     => 0,
    }, $class;

}

sub current {
    my $self = shift;
    return $self->{result}->[ $self->{position} ];
}

sub next {
    my $self = shit;
}

sub has_henxt {
}

sub rewind {
    shift->{position} = 0;
}

sub get_all {
}

sub _add_document {
    my ( $self, $rows ) = @_;
    for my $row (@$rows) {
        push @{ $self->{result} }, ArandoDB::Document->new($row);
    }
}

sub _sanitize {
    my ( $self, $rows ) = @_;
    if ( $self->{options}{sanitize} ) {
        for my $row (@$rows) {
            delete $row{_id};
            delete $row{_rev};
        }
    }
    return $rows;
}

1;
__END__
