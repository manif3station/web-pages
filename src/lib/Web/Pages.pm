package Web::Pages;

use Moo;

use Dancer2 appname => 'Web';

hook before_template_render => sub {
    my ($stash) = @_;
    $stash->{Page}{link} = \&link;
};

has theme => ( is => 'ro' );

my %pages;

sub pages { \%pages }

sub link {
    my ( $id, $attrs ) = @_;

    $id = [split /\./, $id]->[-1];

    my $page = $pages{$id} or die "Page '$id' is not defined";

    $DB::single=2 if !ref $attrs;
    $attrs->{alt} //= $page->{alt};

    $attrs = join ' ',
      map { qq{$_="$attrs->{$_}"} } grep { defined $attrs->{$_} } keys %$attrs;

    $attrs = " $attrs" if $attrs;

    sprintf '<a href="%s"%s>%s</a>', $page->{link}, $attrs, $page->{display};
}

sub add {
    my ( $self, $id, $config ) = @_;

    $id = [split /\./, $id]->[-1];

    my $page = $pages{$id} //= {};

    $page->{alt} = $config->{alt} // $id;

    $page->{link} = $config->{link} // "/$id";

    $page->{display} = $config->{display} // "\u$id";

    $page->{title} = $config->{title} // "\u$id";

    my $route = $config->{route} or return;

    my $method = $route->{method} // 'get';

    my $path = $config->{route}{path} // $page->{link};

    my $code = $config->{code};

    if ( $method eq 'get' && !$code ) {
        if ( $page->{_final} ) {
            die "'@$path' is finaled and can't be added anymore"
        }

        my $tt_file = $config->{template} // $id;

        $tt_file .= '.tt';

        my $theme = $config->{theme} // $self->theme // '';

        $tt_file = "$theme/$tt_file" if $theme;

        $code = sub {
            template $tt_file => {
                Page => {
                    id      => $id,
                    path    => vars->{page}{link}    // $page->{link},
                    title   => vars->{page}{title}   // $page->{title},
                    display => vars->{page}{display} // $page->{display},
                },
            };
        };

        $page->{_final} = 1;
    }

    die "$method '$path' is missing code" if !$code;

    if ( UNIVERSAL::isa( $path, 'ARRAY' ) ) {
        eval $method . ' $_ => $code for @$path';
    }
    else {
        eval $method . ' $path => $code';
    }

    die "adding '$method $path' has an error: $@" if $@;

    return ( $id, $config );
}

1;
