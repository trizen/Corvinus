package Corvinus::Types::Block::Try {

    use utf8;
    use 5.020;
    use experimental qw(signatures);

    sub new {
        bless {catch => 0}, __PACKAGE__;
    }

    sub catch($self, $code) {
        $self->{catch}
          ? $code->run(Corvinus::Types::String::String->new($self->{type}),
                       Corvinus::Types::String::String->new($self->{msg} =~ s/^\[.*?\]\h*//r)->chomp)
          : $self->{val};
    }

    *prinde = \&catch;
};

1
