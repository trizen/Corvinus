package Corvinus::Types::Block::Given {

    use utf8;
    use 5.020;
    use experimental qw(signatures);

    sub new {
        bless {}, __PACKAGE__;
    }

    sub given($, $expr) {
        Corvinus::Types::Block::Switch->new($expr);
    }

    *dat = \&given;
}

1;
