package Corvinus::Types::Char::Chars {

    use utf8;
    use 5.020;
    use experimental qw(signatures);
    use parent qw(Corvinus::Types::Array::Array);

    use overload q{""} => \&dump;

    sub new($, @chars) {
        bless [@{Corvinus::Types::Array::Array->new(@chars)}], __PACKAGE__;
    }

    *noi = \&new;

    sub call($self, @strings) {
        $self->new(map { Corvinus::Types::Char::Char->new($_) } split //, join('', @strings));
    }

    sub dump {
        my ($self) = @_;
        Corvinus::Types::String::String->new('Caractere.noi(' . join(', ', map { $_->get_value } @{$self}) . ')');
    }
};

1
