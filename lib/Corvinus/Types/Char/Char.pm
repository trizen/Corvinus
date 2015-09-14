package Corvinus::Types::Char::Char {

    use utf8;
    use 5.020;
    use experimental qw(signatures);

    use parent qw(
      Corvinus::Convert::Convert
      Corvinus::Types::String::String
      );

    use overload q{""} => \&dump;

    sub new($, $char="\0") {
        ref($char) && return $char->to_char;
        bless \$char, __PACKAGE__;
    }

    *nou = \&new;

    sub call($self, $char="\0") {
        $self->new(chr ord $char);
    }

    sub dump {
        my ($self) = @_;
        Corvinus::Types::String::String->new(q{Caracter(} . $self->SUPER::dump->get_value . q{)});
    }
};

1
