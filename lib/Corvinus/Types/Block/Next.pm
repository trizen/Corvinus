package Corvinus::Types::Block::Next {

    use utf8;
    use 5.020;
    use experimental qw(signatures);

    sub new {
        bless {depth => 1}, __PACKAGE__;
    }

    sub next($self, $depth=1) {
        $self->{depth} = ref($depth) ? $depth->get_value : $depth;
        $self;
    }

    *sari = \&next;
}

1;
