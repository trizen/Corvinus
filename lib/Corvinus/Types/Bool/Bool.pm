package Corvinus::Types::Bool::Bool {

    use utf8;
    use 5.020;
    use experimental qw(signatures);

    use overload
      q{bool} => \&get_value,
      q{""}   => \&dump;

    use parent qw(
      Corvinus::Object::Object
      Corvinus::Convert::Convert
      );

    {
        my $true  = (bless \(my $t = 1), __PACKAGE__);
        my $false = (bless \(my $f = 0), __PACKAGE__);

        sub new($, $bool) {
            $bool ? $true : $false;
        }

        *call = \&new;
        *nou = \&new;
        *noua = \&new;

        sub true($)  { $true }
        sub false($) { $false }

        *adevarat = \&true;
        *fals = \&false;
        *adev = \&adevarat;
    }

    sub get_value { ${$_[0]} }

    {
     no strict 'refs';

    *{__PACKAGE__ . '::' . '|'} = sub($self, $arg) {
        $self->get_value ? $self : $arg;
    };

    *{__PACKAGE__ . '::' . '&'} = sub($self, $arg) {
        $self->get_value ? $arg : $self;
    };
}

    sub is_true($self) { $self }

    *isTrue = \&is_true;
    *e_adevarat = \&is_true;
    *e_adev = \&is_true;

    sub not($self) {
        $self->get_value ? $self->false : $self->true;
    }

    *e_fals = \&not;
    *neaga = \&not;

    sub dump {
        my ($self) = @_;
        Corvinus::Types::String::String->new($self->get_value ? 'adevarat' : 'fals');
    }

};

1
