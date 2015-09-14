package Corvinus::Object::Unary {

    use utf8;
    use 5.020;
    use parent qw(Corvinus);
    use experimental qw(signatures);

    sub new {
        bless {}, __PACKAGE__;
    }

    {
        no strict 'refs';
        *{__PACKAGE__ . '::' . '+'} = sub ($, $obj) {
            $obj;
        };

        *{__PACKAGE__ . '::' . '~'} = sub ($, $obj) {
            $obj->not;
        };

        *{__PACKAGE__ . '::' . '-'} = sub ($, $obj) {
            $obj->negate;
        };

        *{__PACKAGE__ . '::' . '√'} = sub ($, $obj) {
            $obj->sqrt;
        };

        *{__PACKAGE__ . '::' . '?'} = sub($, $obj) {
            Corvinus::Types::Bool::Bool->new($obj->get_value);
        };

        *{__PACKAGE__ . '::' . '!'} = sub($, $obj) {
            Corvinus::Types::Bool::Bool->new(not $obj->get_value);
        };

        *{__PACKAGE__ . '::' . '>'} = sub($, @args) {
            Corvinus::Types::Bool::Bool->new(say join(" ", @args));
        };

        *{__PACKAGE__ . '::' . '>>'} = sub($, @args) {
            Corvinus::Types::Bool::Bool->new(print join(" ", @args));
        };
    }
};

1;
