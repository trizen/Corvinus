package Corvinus::Variable::ClassInit {

    use 5.014;
    use overload q{""} => \&dump;

    use parent qw(
      Corvinus::Object::Object
      );

    sub __new__ {
        my (undef, %opt) = @_;
        bless \%opt, __PACKAGE__;
    }

    sub __set_params__ {
        my ($self, $names) = @_;
        $self->{__VARS__} = $names;
    }

    sub __set_block__ {
        my ($self, $block) = @_;
        $self->{__BLOCK__} = $block;
        $self;
    }

    sub __add_method__ {
        my ($self, $name, $method) = @_;
        $self->{__METHODS__}{$name} = $method;
        $self;
    }

    *def_method = \&__add_method__;

    sub __add_vars__ {
        my ($self, $vars) = @_;
        push @{$self->{__DEF_VARS__}}, @{$vars};
        $self;
    }

    sub def_var {
        my ($self, $name, $value) = @_;
        $self->{__VALS__}{$name} = $value;
        $self;
    }

    sub respond_to {
        my ($self, $name) = @_;
        Corvinus::Types::Bool::Bool->new(exists $self->{__METHODS__}{$name});
    }

    sub inherit {
        my ($self, $class) = @_;
        my $name = $self->{name};
        foreach my $type (qw(__METHODS__ __VALS__)) {
            foreach my $key (keys %{$class->{$type}}) {
                if (not exists $self->{$type}{$key}) {
                    $self->{$type}{$key} = $class->{$type}{$key};
                }
            }
        }
        push @{$self->{__VARS__}}, @{$class->{__VARS__}};
        $self->{name} = $name;
        $self;
    }

    sub replace {
        my ($self, $class) = @_;
        my $name = $self->{name};
        delete @{$self}{keys %{$self}};
        %{$self} = %{$class};
        $self->{name} = $name;
        $self;
    }

    sub is_a {
        my ($self, $arg) = @_;
        Corvinus::Types::Bool::Bool->new(
                                      ref($arg) eq 'Corvinus::Variable::ClassInit' || ref($arg) eq 'Corvinus::Variable::Class'
                                      ? $self->{name} eq $arg->{name}
                                      : 0
                                     );
    }

    *is_an = \&is_a;

    sub dump {
        my ($self) = @_;
        Corvinus::Types::String::String->new($self->{name});
    }

    sub init {
        my ($self, @args) = @_;

        my $class = Corvinus::Variable::Class->__new__(class => $self, name => $self->{name});

        # The class parameters
        my @names          = map { $_->{name} } @{$self->{__VARS__}};
        my @default_values = map { $_->{value} } @{$self->{__VARS__}};

        # Init the class variables
        @{$class->{__VARS__}}{@names} = @default_values;

        # Save the names of class parameters
        $class->{__PARAMS__} = [@names];

        # Set the class arguments
        foreach my $i (0 .. $#{$self->{__VARS__}}) {
            if (ref($args[$i]) eq 'Corvinus::Types::Array::Pair') {
                foreach my $pair (@args[$i .. $#args]) {
                    ref($pair) eq 'Corvinus::Types::Array::Pair' || do {
                        warn "[WARN] Class init error -- expected a Pair type argument, but got: ", ref($pair), "\n";
                        last;
                    };
                    $self->{__VARS__}[$i]->set_value($class->{__VARS__}{$pair->[0]->get_value} = $pair->[1]->get_value);
                }
                last;
            }

            exists($self->{__VARS__}[$i]->{array}) && do {
                $self->{__VARS__}[$i]->set_value($class->{__VARS__}{$self->{__VARS__}[$i]{name}} =
                                                 Corvinus::Types::Array::Array->new(@args[$i .. $#args]));
                next;
            };

            exists($self->{__VARS__}[$i]->{hash}) && do {
                $self->{__VARS__}[$i]->set_value($class->{__VARS__}{$self->{__VARS__}[$i]{name}} =
                                                 Corvinus::Types::Hash::Hash->new(@args[$i .. $#args]));
                next;
            };

            $self->{__VARS__}[$i]->set_value($class->{__VARS__}{$self->{__VARS__}[$i]{name}} =
                                             exists($args[$i]) ? $args[$i] : $self->{__VARS__}[$i]->{value});
        }

        # Run the auxiliary code of the class
        $self->{__BLOCK__}->run;

        # Set back the default values for variables
        while (my ($i, $var) = each @{$self->{__VARS__}}) {
            $var->set_value($default_values[$i]);
        }

        # Add 'def' defined variables
        foreach my $var (@{$self->{__DEF_VARS__}}) {
            $class->{__VARS__}{$var->{name}} = $var->get_value;
        }

        # Add some new defined values
        while (my ($key, $value) = each %{$self->{__VALS__}}) {
            $class->{__VARS__}{$key} = $value;
        }

        # Store the class methods
        while (my ($key, $value) = each %{$self->{__METHODS__}}) {
            $class->{method}{$key} = $value;
        }

        # Execute the 'new' method (if exists)
        if (exists $self->{__METHODS__}{new}) {
            $self->{__METHODS__}{new}->call($class, @args);
        }

        $class;
    }

    *call = \&init;
    *new  = \&init;

    {
        no strict 'refs';
        *{__PACKAGE__ . '::' . '='}  = \&replace;
        *{__PACKAGE__ . '::' . '+='} = \&inherit;
        *{__PACKAGE__ . '::' . '<'}  = \&inherit;
        *{__PACKAGE__ . '::' . '<<'} = \&inherit;
    }
};

1;
