package Web::Nav;

use Moo;

use Dancer2 appname => 'Web';

hook before_template_render => sub {
    my ($stash) = @_;
    $stash->{page}{nav} = \&tree;
};

my %tree;

sub tree { \%tree }

1;
