package Corvinus::Meta::Meta {

    use utf8;
    use 5.020;
    use experimental qw(signatures);

    sub new($, $obj) {
        bless {obj => $obj, ref => ref($obj)}, __PACKAGE__
    }

    sub METHODS($self) {

        my %alias;
        my %methods;
        my $ref = $self->{ref};
        foreach my $method (grep { $_ !~ /^[(_]/ and defined(&{$ref . '::' . $_}) } keys %{$ref . '::'}) {
            $methods{$method} = (
                                 $alias{\&{$ref . '::' . $method}} //=
                                   Corvinus::Variable::LazyMethod->new(
                                                                    obj    => $self->{obj},
                                                                    method => \&{$ref . '::' . $method}
                                                                   )
                                );
        }

        Corvinus::Types::Hash::Hash->new(%methods);
    }

    sub def_metoda($self, $name, $block) {
        *{$self->{ref} . '::' . $name} = sub {
            $block->call(@_);
        };
        $block;
    }

    *__add_method__ = \&def_metoda;

}

1;
