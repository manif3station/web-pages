package Web::Pages;

use Moo;

use Dancer2 appname => 'Web';

hook before_template_render => sub {
    my ($stash) = @_;
    $stash->{page}{link} = sub { __PACKAGE__->link(@_) };
};

has theme => ( is => 'ro' );

my %pages;

sub link {
    my ( $class, $id, $attrs ) = @_;

    my $page = $pages{$id} or die "Page '$id' is not defined";

    $attrs->{alt} //= $page->{alt_text};

    $attrs = join ' ',
      map { qq{$_="$attrs->{$_}"} } grep { defined $attrs->{$_} } keys %$attrs;

    $attrs = " $attrs" if $attrs;

    sprintf '<a href="%s"%s>%s</a>', $page->{link}, $attrs, $page->{title};
}

sub add {
    my ( $self, $id, $config ) = @_;

    $pages{$id} = $config;

    my $suffix = $self->suffix // '';

    my $link = $config->{link} // '';

    my $title = $config->{title} // "\u$id";

    my $template = $config->{template} // $id;

    my $theme = $self->theme // '';

    $template = "$theme/$template.tt" if $theme;

    my $routes = $config->{routes} or die "Missing routes for '$id'";

    foreach my $route (@$routes) {
        my ( $method, $path, $before ) = @_;

        $method->(
            $path => sub {
                $before->() if $before;

                template $template => {
                    page => {
                        id    => $id,
                        link  => vars->{page}{link} // $link,
                        title => var->{page}{title} // $title,
                    },
                };
            }
        );
    }

    return $config;
}

1;
