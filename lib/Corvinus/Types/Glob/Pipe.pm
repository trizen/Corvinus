package Corvinus::Types::Glob::Pipe {

    use 5.014;
    use parent qw(
      Corvinus::Object::Object
      );

    use overload q{""} => \&dump;

    sub new {
        my (undef, @command) = @_;
        bless \@command, __PACKAGE__;
    }

    *call = \&new;
    *nou = \&new;
    *noua = \&new;

    sub get_value {
        join(' ', @{$_[0]});
    }

    sub command {
        my ($self) = @_;
        @{$self} > 1 ? Corvinus::Types::Array::List->new(@{$self}) : $self->[0];
    }

    sub open {
        my ($self, $mode, $var_ref) = @_;

        if (ref $mode) {
            $mode = $mode->get_value;
        }

        my $pid = open(my $pipe_h, $mode, @{$self});
        my $pipe_obj = Corvinus::Types::Glob::FileHandle->new(fh => $pipe_h, self => $self);

        if (defined($var_ref)) {
            $var_ref->get_var->set_value($pipe_obj);

            return defined($pid)
              ? Corvinus::Types::Number::Number->new($pid)
              : ();
        }

        defined($pid) ? $pipe_obj : ();
    }

    sub open_r {
        my ($self, $var_ref) = @_;
        $self->open('-|:utf8', $var_ref);
    }

    *openR     = \&open_r;
    *openRead  = \&open_r;
    *open_read = \&open_r;

    sub open_w {
        my ($self, $var_ref) = @_;
        $self->open('|-:utf8', $var_ref);
    }

    *openW      = \&open_w;
    *openWrite  = \&open_w;
    *open_write = \&open_w;

    sub dump {
        my ($self) = @_;
        Corvinus::Types::String::String->new(
                      'Pipe.new(' . join(', ', map { Corvinus::Types::String::String->new($_)->dump->get_value } @{$self}) . ')');
    }
}

1;
