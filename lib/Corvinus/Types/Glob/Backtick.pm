package Corvinus::Types::Glob::Backtick {

    use parent qw(
      Corvinus::Object::Object
      );

    use overload q{""} => \&dump;

    sub new {
        my (undef, $backtick) = @_;
        bless \$backtick, __PACKAGE__;
    }

    *nou = \&new;

    sub get_value {
        ${$_[0]};
    }

    sub run {
        my ($self) = @_;
        Corvinus::Types::String::String->new(scalar `$$self`);
    }

    *execute = \&run;
    *exec    = \&run;
    *executa = \&run;

    *{__PACKAGE__ . '::' . '`'} = \&run;

    sub dump {
        my ($self) = @_;
        Corvinus::Types::String::String->new(
                                 'Backtick.new(' . Corvinus::Types::String::String->new($self->get_value)->dump->get_value . ')');
    }
};

1
