package Web::Nav;

use Moo;

use Dancer2 appname => 'Web';

my %tree;

sub tree { \%tree }

hook before_template_render => sub {
    my ($stash) = @_;
    $stash->{Page}{nav}{tree}    = \%tree;
    $stash->{Page}{nav}{pages}   = \&nav_pages;
    $stash->{Page}{nav}{current} = \&is_current_page;
};

my $next_position = 0;

sub branch {
    my ($id) = @_ or return;
    return $id if ref $id;
    my $branch = eval '\\tree()->' . join '', map {"{$_}"} split /\./, $id;
    die "Path: $id\nError: $@" if $@;
    return wantarray ? $branch : $$branch;
}

sub add {
    my ( $self, $id, $config ) = @_;

    my ($branch) = branch $id;

    %{ $$branch ||= {} }
        = ( id => $id, %{ $config // {} }, _position => $next_position++ );

    return ( $id, $config );
}

sub nav_pages {
    my ($path) = @_;

    my $branch = branch $path // tree;

    my @pages;

    foreach my $id (
        sort { $branch->{$a}{_position} <=> $branch->{$b}{_position} }
        keys %$branch
        )
    {
        next if $id eq '_postion' || $id eq '_children';

        my $page = $branch->{$id};

        $page->{link} = sub {
            my ($attr) = @_;
            Web::Pages::link( $id, $attr );
        };

        push @pages, $page;
    }

    return \@pages;
}

sub is_current_page {
    my ($id) = @_ or return;

    my $page         = branch $id;
    my $current_path = request->path;
    my $route        = $page->{route} or return;

    my @path
        = UNIVERSAL::isa( $route->{path}, 'ARRAY' )
        ? @{ $route->{path} }
        : ( $route->{path} );

    my @found = grep {
        UNIVERSAL::isa( $_, 'REGEXP' )
            ? $current_path =~ m/$_/
            : $current_path eq $_
    } @path;

    return scalar @found;
}

1;
