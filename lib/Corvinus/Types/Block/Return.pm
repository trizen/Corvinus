package Corvinus::Types::Block::Return {

    use utf8;
    use 5.020;
    use experimental qw(signatures);

    sub new {
        bless {}, __PACKAGE__;
    }

    sub return($self, @obj) {
        $self->{obj} = @obj > 1 ? Corvinus::Types::Array::List->new(@obj) : $obj[0];
        $self;
    }

    *returneaza = \&return;
}

1;
