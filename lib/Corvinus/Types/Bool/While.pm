package Corvinus::Types::Bool::While {

    use utf8;
    use 5.020;
    use experimental qw(signatures);

    sub new($) {
        bless {}, __PACKAGE__;
    }

    sub cat_timp($self, $code) {
        $self->{arg} = $code;
        $self;
    }

    sub do($self, $code) {
        $code->cat_timp($self->{arg}, $self);
    }

    sub else($self, $code) {
        $self->{did_while} // $code->run;
        undef $self->{did_while};
        $self;
    }

}

1;
