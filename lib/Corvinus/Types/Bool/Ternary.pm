package Corvinus::Types::Bool::Ternary {

    use utf8;
    use 5.020;
    use experimental qw(signatures);

    sub new($, %opt) {
        bless \%opt, __PACKAGE__;
    }

    *{__PACKAGE__ . '::' . ':'} = sub($self, $code) {
        Corvinus::Types::Block::Code->new($self->{bool} ? $self->{code} : $code)->run;
    };
};

1
