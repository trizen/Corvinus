package Corvinus::Types::Byte::Byte {

    use utf8;
    use 5.020;
    use experimental qw(signatures);
    use parent qw(Corvinus::Types::Number::Number);

    use overload q{""} => \&dump;

    sub new($, $byte=0) {
        state $x = require Math::BigInt;
        bless \Math::BigInt->new($byte), __PACKAGE__;
    }

    *call = \&new;
    *nou = \&new;

    sub dump {
        my ($self) = @_;
        Corvinus::Types::String::String->new('Octet(' . $self->get_value . ')');
    }
};

1
