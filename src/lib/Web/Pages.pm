package Web::Pages;

use Moo;
use TagAttrs;

use Dancer2 appname => 'Web';

hook before_template_render => sub {
    my ($stash) = @_;
    $stash->{Page}{link} = \&link;
};

has theme => ( is => 'ro' );

my %pages;

sub pages { \%pages }

sub link {
    my ($id, $options) = @_;

    $options //= {};

    $id = [ split /\./, $id ]->[-1];

    my $page = $pages{$id} or die "Page '$id' is not defined";

    my ( $attrs, $args ) = attrs { alt => $page->{alt}, %$options };

    my $tag = sprintf '<a href="%s"%s>', $page->{link}, $attrs;
    $tag .= $page->{display} if $args->{display} // 1;
    $tag .= '</a>'           if $args->{endtag}  // 1;
    return $tag;
}

sub add {
    my ( $self, $id, $config ) = @_;

    $id = [ split /\./, $id ]->[-1];

    my $page = $pages{$id} //= {};

    $page->{alt} = $config->{alt} // $id;

    $page->{link} = $config->{link} // "/$id";

    $page->{display} = $config->{display} // "\u$id";

    $page->{title} = $config->{title} // "\u$id";

    my $route = $config->{route} or return;

    my $method = $route->{method} // 'get';

    my $path = $config->{route}{path} // $page->{link};

    my $code = $config->{route}{code};

    if ( $method eq 'get' && !$code ) {
        if ( $page->{_final} ) {
            die "$method '$page->{link}' is finaled and can't be added anymore";
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
