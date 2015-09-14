package Corvinus::Types::Nil::Nil {

    use overload
      q{bool} => sub { },
      q{""}   => sub { '' };

    use parent qw(
      Corvinus::Object::Object
      Corvinus::Convert::Convert
      );

    sub new {
        bless \(my $nil = undef), __PACKAGE__;
    }

    *nou = \&new;
    *noua = \&new;

    sub get_value {
        undef;
    }

    sub dump {
        Corvinus::Types::String::String->new('nil');
    }
};

1
