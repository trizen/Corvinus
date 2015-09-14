package Corvinus::Convert::Convert {

    # This module is used only as parent!

    use utf8;
    use 5.020;
    use parent qw(Corvinus);
    use experimental qw(signatures);

    use overload;

    sub to_s($self) {
        $self->isa('SCALAR')
          || $self->isa('REF')
          ? Corvinus::Types::String::String->new(overload::StrVal($self) ? "$self" : defined($$self) ? "$$self" : "")
          : $self;
    }

    *to_str    = \&to_s;
    *to_string = \&to_s;
    *ca_text = \&to_s;
    *ca_string = \&to_s;

    sub to_obj($self, $obj) {
        return $self if ref($self) eq ref($obj);
        $obj->new($self);
    }

    *to_object = \&to_obj;

    sub to_i($self) {
        Corvinus::Types::Number::Number->new_int($self->get_value);
    }

    *ca_intreg = \&to_i;
    *to_int = \&to_i;

    sub to_rat($self) {
        Corvinus::Types::Number::Number->new_rat($self->get_value);
    }

    *to_r = \&to_rat;
    *ca_rational = \&to_rat;
    *ca_rat = \&to_rat;

    sub to_complex($self) {
        Corvinus::Types::Number::Complex->new($self->get_value);
    }

    *to_c = \&to_complex;
    *ca_complex = \&to_complex;

    sub to_n($self) {
        Corvinus::Types::Number::Number->new($self->get_value);
    }

    *ca_numar = \&to_n;
    *to_num = \&to_n;

    sub to_float($self) {
        Corvinus::Types::Number::Number->new_float($self->get_value);
    }

    *to_f = \&to_float;
    *ca_decimal = \&to_float;

    sub to_file($self) {
        Corvinus::Types::Glob::File->new($self->get_value);
    }

    *ca_fisier = \&to_file;

    sub to_dir($self) {
        Corvinus::Types::Glob::Dir->new($self->get_value);
    }

    *ca_dosar = \&to_dir;

    sub to_bool($self) {
        Corvinus::Types::Bool::Bool->new($self->get_value);
    }

    *ca_logic = \&to_bool;
    *ca_bool = \&to_bool;

    sub to_byte($self) {
        Corvinus::Types::Byte::Byte->new(CORE::ord($self->get_value));
    }

    *ca_octet = \&to_byte;

    sub to_char($self) {
        Corvinus::Types::Char::Char->call($self->get_value);
    }

    *ca_caracter = \&to_char;

    sub to_regex($self) {
        Corvinus::Types::Regex::Regex->new($self->get_value);
    }

    *to_re = \&to_regex;
    *ca_expreg = \&to_regex;

    sub to_bytes($self) {
        Corvinus::Types::Byte::Bytes->call($self->get_value);
    }

    *ca_octeti = \&to_byte;

    sub to_chars($self) {
        Corvinus::Types::Char::Chars->call($self->get_value);
    }

    *ca_caractere = \&to_chars;

    sub to_array($self) {
        Corvinus::Types::Array::Array->new($self);
    }

    *ca_lista = \&to_array;

    sub to_caller($self) {
        Corvinus::Module::OO->__NEW__($self->get_value);
    }

    *ca_oo = \&to_caller;

    sub to_fcaller($self) {
        Corvinus::Module::Func->__NEW__($self->get_value);
    }

    *ca_ff = \&to_fcaller;
};

1
