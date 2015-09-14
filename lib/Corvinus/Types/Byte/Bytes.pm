package Corvinus::Types::Byte::Bytes {

    use utf8;
    use 5.020;
    use experimental qw(signatures);
    use parent qw(Corvinus::Types::Array::Array);

    use overload q{""} => \&dump;

    sub new($, @bytes) {
        bless [@{Corvinus::Types::Array::Array->new(@bytes)}], __PACKAGE__;
    }

    *noi = \&new;
    *nou = \&new;

    sub call($self, @strings) {
        my $string = CORE::join('', @strings);
        my @bytes = do {
            use bytes;
            map { Corvinus::Types::Byte::Byte->new(CORE::ord bytes::substr($string, $_, 1)) } 0 .. bytes::length($string) - 1;
        };
        $self->new(@bytes);
    }

    sub join($self) {
        state $x = require Encode;
        Corvinus::Types::String::String->new(
            eval {
                Encode::decode_utf8(CORE::join('', map { CORE::chr($_->get_value) } @{$self}));
              } // return
        );
    }

    sub encode($self, $encoding='UTF-8') {
        state $x = require Encode;
        $encoding = $encoding->get_value if ref($encoding);
        Corvinus::Types::String::String->new(
            eval {
                Encode::decode($encoding, CORE::join('', map { CORE::chr($_->get_value) } @{$self}));
              } // return
        );
    }

    sub dump {
        my ($self) = @_;
        Corvinus::Types::String::String->new(
                                       'Octeti.noi(' . CORE::join(', ', map { $_->get_value } @{$self}) . ')');
    }
};

1
