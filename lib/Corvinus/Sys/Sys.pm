package Corvinus::Sys::Sys {

    use 5.020;
    use parent qw(Corvinus);
    use experimental qw(signatures);

    sub new($, %opt) {
        CORE::bless \%opt, __PACKAGE__;
    }

    sub exit($, $code) {
        exit($code // 0);
    }

    sub alarm($, $sec) {
        state $x = require Time::HiRes;
        Corvinus::Types::Bool::Bool->new(Time::HiRes::alarm($sec->get_value));
    }

    sub ualarm($, $sec) {
        state $x = require Time::HiRes;
        Corvinus::Types::Bool::Bool->new(Time::HiRes::ualarm($sec->get_value));
    }

    sub sleep($, $sec) {
        state $x = require Time::HiRes;
        Corvinus::Types::Bool::Bool->new(Time::HiRes::sleep($sec->get_value));
    }

    sub nanosleep($, $sec) {
        state $x = require Time::HiRes;
        Corvinus::Types::Bool::Bool->new(Time::HiRes::nanosleep($sec->get_value));
    }

    *nanoSleep = \&nanosleep;

    sub usleep($, $sec) {
        state $x = require Time::HiRes;
        Corvinus::Types::Bool::Bool->new(Time::HiRes::usleep($sec->get_value));
    }

    sub osname($) {
        Corvinus::Types::String::String->new($^O);
    }

    *osName = \&osname;

    sub user($) {
        Corvinus::Types::String::String->new(CORE::getlogin);
    }

    *getlogin = \&user;

    sub umask {
        my ($self, $mode) = @_;

        if (defined($mode)) {
            return Corvinus::Types::Number::Number->new(CORE::umask($mode->get_value));
        }

        Corvinus::Types::Number::Number->new(CORE::umask);
    }

    sub ref {
        my ($self, $obj) = @_;
        Corvinus::Types::String::String->new(CORE::ref $obj);
    }

    sub sidef {
        my ($self) = @_;

        state $x = require File::Spec;
        Corvinus::Types::String::String->new(File::Spec->rel2abs($0));
    }

    sub die {
        my ($self, @args) = @_;
        if (exists $self->{file_name}) {
            CORE::die(@args, " at $self->{file_name} line $self->{line}.\n");
        }
        else {
            CORE::die(@args, "\n");
        }
    }

    *raise = \&die;

    sub assert {
        my ($self, $bool) = @_;
        $bool || $self->die("assert: not true");
    }

    sub assert_eq {
        my ($self, $arg1, $arg2) = @_;
        state $method = '==';
        $arg1->$method($arg2) || $self->die("assert_eq: $arg1 $method $arg2 is false");
    }

    sub assert_ne {
        my ($self, $arg1, $arg2) = @_;
        state $method = '!=';
        $arg1->$method($arg2) || $self->die("assert_ne: $arg1 $method $arg2 is false");
    }

    sub warn {
        my ($self, @args) = @_;
        if (exists $self->{file_name}) {
            CORE::warn(@args, " at $self->{file_name} line $self->{line}.\n");
        }
        else {
            CORE::warn(@args, "\n");
        }
    }

    sub spune($self, @args) {
        Corvinus::Types::Bool::Bool->new(say @args);
    }

    sub scrie($self, @args) {
        Corvinus::Types::Bool::Bool->new(print @args);
    }

    sub printf {
        my ($self, @args) = @_;
        Corvinus::Types::Bool::Bool->new(printf @args);
    }

    sub printh {
        my ($self, $fh, @args) = @_;

        if (CORE::ref($fh) eq 'GLOB') {
            return Corvinus::Types::Bool::Bool->new(print {$fh} @args);
        }

        $fh->print(@args);
    }

    sub citeste_linie {
        my ($self, $text) = @_;

        if (defined($text)) {
            $text->print;
        }

        Corvinus::Types::String::String->new(scalar unpack("A*", scalar <STDIN>));
    }

    sub citeste {
        my ($self, $type, @vars) = @_;

        if (@vars) {
            foreach my $var_ref (@vars) {
                my $var = $var_ref->get_var;
                print "$var->{name}: ";
                chomp(my $input = <STDIN>);
                $var->set_value($type->new($input));
            }

            return $self;
        }

        if (defined $type) {
            chomp(my $input = <STDIN>);
            return $type->new($input);
        }

        chomp(my $input = <STDIN>);
        Corvinus::Types::String::String->new($input);
    }

    sub open {
        my ($self, $var, $mode, $filename) = @_;
        $filename->to_file->open($mode, $var);
    }

    sub stdin {
        Corvinus::Types::Glob::FileHandle->stdin;
    }

    sub stdout {
        Corvinus::Types::Glob::FileHandle->stdout;
    }

    sub stderr {
        Corvinus::Types::Glob::FileHandle->stderr;
    }

    sub opendir {
        my ($self, $var, $dirname) = @_;
        $dirname->to_dir->open($var);
    }

    sub eval {
        my ($self, @args) = @_;
        Corvinus::Perl::Perl->eval(@args);
    }

    sub bless {
        my ($self, $obj, $class) = @_;
        CORE::bless $obj, $class;
    }

    sub refaddr {
        my ($self, $obj) = @_;
        state $x = require Scalar::Util;
        Corvinus::Types::Number::Number->new(Scalar::Util::refaddr($obj));
    }

    sub reftype {
        my ($self, $obj) = @_;
        state $x = require Scalar::Util;
        Corvinus::Types::String::String->new(Scalar::Util::reftype($obj));
    }

    sub weaken {
        my ($self, $obj) = @_;
        state $x = require Scalar::Util;
        Corvinus::Types::Bool::Bool->new(Scalar::Util::weaken($obj));
    }

    sub isweak {
        my ($self, $obj) = @_;
        state $x = require Scalar::Util;
        Corvinus::Types::Bool::Bool->new(Scalar::Util::isweak($obj));
    }

    sub unweaken {
        my ($self, $obj) = @_;
        state $x = require Scalar::Util;
        Corvinus::Types::Bool::Bool->new(Scalar::Util::unweaken($obj));
    }

    sub copy {
        my ($self, $obj) = @_;
        state $x = require Storable;
        Storable::dclone($obj);
    }

    *clone = \&copy;

    sub select {
        my ($self, $fh) = @_;
        CORE::select(CORE::ref($fh) eq 'GLOB' ? $fh : $fh->get_value);
    }

    sub system {
        my ($self, @args) = @_;
        Corvinus::Types::Number::Number->new(CORE::system(@args));
    }

    *run = \&system;

    sub exec {
        my ($self, @args) = @_;
        CORE::exec(@args);
    }

    sub __GETPW__ {
        my ($self, $name, $passwd, $uid, $gid, $quota, $comment, $gcos, $dir, $shell) = @_;
        $name // return;
        Corvinus::Types::Array::Array->new(
                                        Corvinus::Types::String::String->new($name),
                                        Corvinus::Types::String::String->new($passwd),
                                        Corvinus::Types::Number::Number->new($uid),
                                        Corvinus::Types::Number::Number->new($gid),
                                        Corvinus::Types::String::String->new($quota),
                                        Corvinus::Types::String::String->new($comment),
                                        Corvinus::Types::String::String->new($gcos),
                                        Corvinus::Types::String::String->new($shell),
                                       );
    }

    sub setpwent {
        my ($self) = @_;
        Corvinus::Types::Bool::Bool->new(CORE::setpwent);
    }

    sub getpwuid {
        my ($self, $uid) = @_;
        $self->__GETPW__(CORE::getpwuid($uid->get_value));
    }

    sub getpwnam {
        my ($self, $name) = @_;
        $self->__GETPW__(CORE::getpwnam($name->get_value));
    }

    sub getpwent {
        my ($self) = @_;
        $self->__GETPW__(CORE::getpwent);
    }

    sub __GETGR__ {
        my ($self, $name, $passwd, $gid, $members) = @_;
        $name // return
          Corvinus::Types::Array::Array->new(
                                          Corvinus::Types::String::String->new($name),
                                          Corvinus::Types::String::String->new($passwd),
                                          Corvinus::Types::Number::Number->new($gid),
                                          Corvinus::Types::Array::Array->new(
                                                             map { Corvinus::Types::String::String->new($_) } split(' ', $members)
                                          ),
                                         );
    }

    sub setgrent {
        my ($self) = @_;
        Corvinus::Types::Bool::Bool->new(CORE::setgrent);
    }

    sub getgrent {
        my ($self) = @_;
        $self->__GETGR__(CORE::getgrent);
    }

    sub getgrgid {
        my ($self, $gid) = @_;
        $self->__GETGR__(CORE::getgrgid($gid->get_value));
    }

    sub getgrnam {
        my ($self, $name) = @_;
        $self->__GETGR__(CORE::getgrnam($name->get_value));
    }

    sub __GETHOST__ {
        my ($self, $name, $aliases, $addrtype, $length, @addrs) = @_;
        $name // return;
        Corvinus::Types::Array::Array->new(
                                        Corvinus::Types::String::String->new($name),
                                        Corvinus::Types::String::String->new($aliases),
                                        Corvinus::Types::String::String->new($addrtype),
                                        Corvinus::Types::Number::Number->new($length),
                                        Corvinus::Types::Array::Array->new(map { Corvinus::Types::String::String->new($_) } @addrs),
                                       );
    }

    sub sethostent {
        my ($self, $stayopen) = @_;
        Corvinus::Types::Bool::Bool->new(CORE::sethostent($stayopen->get_value));
    }

    sub gethostbyaddr {
        my ($self, $addr, $addrtype) = @_;
        $self->__GETHOST__(CORE::gethostbyaddr($addr->get_value, $addrtype->get_value));
    }

    sub gethostbyname {
        my ($self, $name) = @_;
        $self->__GETHOST__(CORE::gethostbyname($name->get_value));
    }

    sub gethostent {
        my ($self) = @_;
        $self->__GETHOST__(CORE::gethostent);
    }

    sub __GETNET__ {
        my ($self, $name, $aliases, $addrtype, $net) = @_;
        $name // return;
        Corvinus::Types::Array::Array->new(
                                        Corvinus::Types::String::String->new($name),
                                        Corvinus::Types::String::String->new($aliases),
                                        Corvinus::Types::String::String->new($addrtype),
                                        Corvinus::Types::String::String->new($net),
                                       );
    }

    sub setnetent {
        my ($self, $stayopen) = @_;
        Corvinus::Types::Bool::Bool->new(CORE::setnetent($stayopen->get_value));
    }

    sub getnetbyaddr {
        my ($self, $addr, $addrtype) = @_;
        $self->__GETNET__(CORE::getnetbyaddr($addr->get_value, $addrtype->get_value));
    }

    sub getnetbyname {
        my ($self, $name) = @_;
        $self->__GETNET__(CORE::getnetbyname($name->get_value));
    }

    sub getnetent {
        my ($self) = @_;
        $self->__GETNET__(CORE::getnetent);
    }

    sub __GETPROTO__ {
        my ($self, $name, $aliases, $proto) = @_;
        $name // return;
        Corvinus::Types::Array::Array->new(
                                        Corvinus::Types::String::String->new($name),
                                        Corvinus::Types::String::String->new($aliases),
                                        Corvinus::Types::String::String->new($proto),
                                       );
    }

    sub setprotoent {
        my ($self, $stayopen) = @_;
        Corvinus::Types::Bool::Bool->new(CORE::setprotoent($stayopen->get_value));
    }

    sub getprotobyname {
        my ($self, $name) = @_;
        $self->__GETPROTO__(CORE::getprotobyname($name->get_value));
    }

    sub getprotobynumber {
        my ($self, $num) = @_;
        $self->__GETPROTO__(CORE::getprotobynumber($num->get_value));
    }

    sub getprotoent {
        my ($self) = @_;
        $self->__GETPROTO__(CORE::getprotoent);
    }

    sub __GETSERV__ {
        my ($self, $name, $aliases, $port, $proto) = @_;
        $name // return;
        Corvinus::Types::Array::Array->new(
                                        Corvinus::Types::String::String->new($name),
                                        Corvinus::Types::String::String->new($aliases),
                                        Corvinus::Types::Number::Number->new($port),
                                        Corvinus::Types::String::String->new($proto),
                                       );
    }

    sub setservent {
        my ($self, $stayopen) = @_;
        Corvinus::Types::Bool::Bool->new(CORE::setservent($stayopen->get_value));
    }

    sub getservbyname {
        my ($self, $name, $proto) = @_;
        $self->__GETSERV__(CORE::getservbyname($name->get_value, $proto->get_value));
    }

    sub getservbyport {
        my ($self, $port, $proto) = @_;
        $self->__GETSERV__(CORE::getservbyport($port->get_value, $proto->get_value));
    }

    sub getservent {
        my ($self) = @_;
        $self->__GETSERV__(CORE::getservent);
    }

    #
    ## get/set priority
    #
    sub getpriority {
        my ($self, $which, $who) = @_;
        Corvinus::Types::Number::Number->new(CORE::getpriority($which->get_value, $who->get_value));
    }

    sub setpriority {
        my ($self, $which, $who, $priority) = @_;
        Corvinus::Types::Number::Number->new(CORE::setpriority($which->get_value, $who->get_value, $priority->get_value));
    }

    sub getppid {
        my ($self) = @_;
        Corvinus::Types::Number::Number->new(CORE::getppid);
    }

    #
    ## get/set the process group of a process
    #
    sub getpgrp {
        my ($self, $pid) = @_;
        Corvinus::Types::Number::Number->new(CORE::getpgrp(defined($pid) ? $pid->get_value : ()));
    }

    sub setpgrp {
        my ($self, $pid, $pgrp) = @_;
        $pid  = defined($pid)  ? $pid->get_value  : 0;
        $pgrp = defined($pgrp) ? $pgrp->get_value : 0;
        Corvinus::Types::Number::Number->new(CORE::setpgrp($pid, $pgrp));
    }

};

1
