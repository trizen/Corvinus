package Corvinus::Object::Object {

    use utf8;
    use 5.020;
    use parent qw(Corvinus);
    use experimental qw(signatures);

    sub spune(@args) {
        Corvinus::Types::Bool::Bool->new(say @args);
    }

    sub scrie(@args) {
        Corvinus::Types::Bool::Bool->new(print @args);
    }

    {
        no strict 'refs';

        # Logical AND
        *{__PACKAGE__ . '::' . '&&'} = *{__PACKAGE__ . '::' . 'si'} = sub($x, $y) {
            $x
              ? Corvinus::Types::Block::Code->new($y)->run
              : $x;
        };

        # Logical OR
        *{__PACKAGE__ . '::' . '||'} = *{__PACKAGE__ . '::' . 'sau'} =  sub($x, $y) {
            $x
              ? $x
              : Corvinus::Types::Block::Code->new($y)->run;
        };

        # Logical XOR
        *{__PACKAGE__ . '::' . '^'} = sub($x, $y) {
            Corvinus::Types::Bool::Bool->new($x xor $y);
        };

        # Defined-OR
        *{__PACKAGE__ . '::' . '\\\\'} = sub($x, $y) {
            ref($x) eq 'Corvinus::Types::Nil::Nil'
              ? Corvinus::Types::Block::Code->new($y)->run
              : $x;
        };

        # Ternary operator (Obj ? TrueExpr : FalseExpr)
        *{__PACKAGE__ . '::' . '?'} = sub($x, $y) {
            Corvinus::Types::Bool::Ternary->new(code => $y, bool => !!$x);
        };

        # Smart match operator
        *{__PACKAGE__ . '::' . '~~'} = sub($first, $second) {

            my $f_type = ref($first);
            my $s_type = ref($second);

            # First is String
            if (   $f_type eq 'Corvinus::Types::String::String'
                or $f_type eq 'Corvinus::Types::Char::Char'
                or $f_type eq 'Corvinus::Types::Glob::File'
                or $f_type eq 'Corvinus::Types::Glob::Dir') {

                # String ~~ Array
                if ($s_type eq 'Corvinus::Types::Array::Array') {
                    return $second->contains($first);
                }

                # String ~~ RangeString
                if ($s_type eq 'Corvinus::Types::Array::RangeString') {
                    return $second->contains($first);
                }

                # String ~~ Hash
                if ($s_type eq 'Corvinus::Types::Hash::Hash') {
                    return $second->exists($first);
                }

                # String ~~ String
                if ($s_type eq 'Corvinus::Types::String::String') {
                    return $second->contains($first);
                }

                # String ~~ Regex
                if ($s_type eq 'Corvinus::Types::Regex::Regex') {
                    return $second->match($first)->is_successful;
                }
            }

            # First is Number
            if ($f_type eq 'Corvinus::Types::Number::Number') {

                # Number ~~ RangeNumber
                if ($s_type eq 'Corvinus::Types::Array::RangeNumber') {
                    return $second->contains($first);
                }
            }

            # First is Array
            if ($f_type eq 'Corvinus::Types::Array::Array') {

                # Array ~~ Array
                if ($s_type eq 'Corvinus::Types::Array::Array') {
                    return $second->contains_all($first);
                }

                # Array ~~ Regex
                if ($s_type eq 'Corvinus::Types::Regex::Regex') {
                    return $second->match($first)->is_successful;
                }

                # Array ~~ Hash
                if ($s_type eq 'Corvinus::Types::Hash::Hash') {
                    return $second->keys->contains_all($first);
                }

                # Array ~~ Any
                return $first->contains($second);
            }

            # First is Hash
            if ($f_type eq 'Corvinus::Types::Hash::Hash') {

                # Hash ~~ Array
                if ($s_type eq 'Corvinus::Types::Array::Array') {
                    return $second->contains_all($first->keys);
                }

                # Hash ~~ Hash
                if ($s_type eq 'Corvinus::Types::Hash::Hash') {
                    return $second->keys->contains_all($first->keys);
                }

                # Hash ~~ Any
                return $first->exists($second);
            }

            # First is Regex
            if ($f_type eq 'Corvinus::Types::Regex::Regex') {

                # Regex ~~ Array
                if ($s_type eq 'Corvinus::Types::Array::Array') {
                    return $first->match($second)->is_successful;
                }

                # Regex ~~ Hash
                if ($s_type eq 'Corvinus::Types::Hash::Hash') {
                    return $first->match($second->keys)->is_successful;
                }

                # Regex ~~ Any
                return $first->match($second)->is_successful;
            }

            # Second is Array
            if ($s_type eq 'Corvinus::Types::Array::Array') {

                # Any ~~ Array
                return $second->contains($first);
            }

            Corvinus::Types::Bool::Bool->false;
        };

        # Negation of smart match
        *{__PACKAGE__ . '::' . '!~'} = sub($x, $y) {
            state $method = '~~';
            $x->$method($y)->not;
        };
    }
};

1
