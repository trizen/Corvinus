package Corvinus::Types::Block::Fork {

    use utf8;
    use 5.020;
    use experimental qw(signatures);

    sub new($, %opts) {
        bless \%opts, __PACKAGE__;
    }

    sub get($self) {

        # Wait for the process to finish
        waitpid($self->{pid}, 0);

        # Return when the fork doesn't hold a file-handle
        exists($self->{fh}) or return;

        state $x = require Storable;
        seek($self->{fh}, 0, 0);    # rewind at the beginning
        scalar eval { Storable::fd_retrieve($self->{fh}) };
    }

    *wait = \&get;
    *join = \&get;
    *asteapta = \&get;

    sub kill($self, $signal) {
        kill(defined($signal) ? $signal->get_value : 'KILL', $self->{pid});
    }

    *termina = \&kill;
};

1
