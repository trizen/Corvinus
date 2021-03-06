package Corvinus::Types::Array::Pair {

    use 5.014;

    use parent qw(
      Corvinus::Types::Array::Array
      );

    use overload q{""} => \&dump;

    sub new {
        my (undef, $item1, $item2) = @_;
        bless [map { Corvinus::Variable::Variable->new(name => '', type => 'var', value => $_) } ($item1, $item2)], __PACKAGE__;
    }

    *nou = \&new;
    *noua = \&new;

    sub get_value {
        my ($self) = @_;

        my @array;
        foreach my $i (0, 1) {
            my $item = $self->[$i]->get_value;

            if (index(ref($item), 'Corvinus::') == 0) {
                push @array, $item->get_value;
            }
            else {
                push @array, $item;
            }
        }

        \@array;
    }

    {
        no strict 'refs';
        foreach my $pair ([first => 0], [second => 1]) {
            *{__PACKAGE__ . '::' . $pair->[0]} = sub {
                $_[0]->[$pair->[1]];
            };
        }
    }

    sub swap {
        my ($self) = @_;
        ($self->[0], $self->[1]) = ($self->[1], $self->[0]);
        $self;
    }

    sub to_hash {
        my ($self) = @_;
        Corvinus::Types::Hash::Hash->new(map { $_->get_value } @{$self});
    }

    *to_h   = \&to_hash;
    *toHash = \&to_hash;

    sub to_array {
        my ($self) = @_;
        Corvinus::Types::Array::Array->new(map { $_->get_value } @{$self});
    }

    *to_a    = \&to_array;
    *toArray = \&to_array;

    sub dump {
        my ($self) = @_;

        Corvinus::Types::String::String->new(
            "Pair.new(" . "\n" . join(
                ",\n",

                (' ' x ($Corvinus::SPACES += $Corvinus::SPACES_INCR)) . join(
                    ", ",
                    map {
                        my $val =
                          ref($_) eq 'Corvinus::Variable::Variable'
                          ? $_->get_value
                          : Corvinus::Types::Nil::Nil->new;

                        eval { $val->can('dump') } ? ${$val->dump} : $val
                      } @{$self}
                )
              )
              . "\n"
              . (' ' x ($Corvinus::SPACES -= $Corvinus::SPACES_INCR)) . ")"
        );
    }
};

1
