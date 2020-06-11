package Pod::Weaver::Plugin::BorderStyle;

# AUTHORITY
# DATE
# DIST
# VERSION

use 5.010001;
use Moose;
with 'Pod::Weaver::Role::AddTextToSection';
with 'Pod::Weaver::Role::Section';

use Data::Dmp  ();
use Data::Dump ();

sub weave_section {
    no strict 'refs';

    my ($self, $document, $input) = @_;

    my $filename = $input->{filename};

    my $package;
    if ($filename =~ m!^lib/(.+)\.pm$!) {
        $package = $1;
        $package =~ s!/!::!g;

        my $package_pm = $package;
        $package_pm =~ s!::!/!g;
        $package_pm .= ".pm";

        if ($package =~ /(?:\A|::)BorderStyles::/) {

            {
                local @INC = ("lib", @INC);
                require $package_pm;
            }
            my %borderstyles;
            # collect border style modules
            {
                require Module::List;
                my $res;
                {
                    local @INC = ("lib");
                    $res = Module::List::list_modules(
                        "", {list_modules=>1});
                }
                for my $mod (keys %$res) {
                    next unless $mod =~ /(?:\A|::)BorderStyle::/;
                    $borderstyles{$mod} = \%{"$mod\::BORDER"};
                }
            }

            # add POD section: BORDER STYLES
            {
                last unless keys %borderstyles;
                require Markdown::To::POD;
                my @pod;
                push @pod, "=over\n\n";
                for my $name (sort keys %borderstyles) {
                    my $bstyle_struct = $borderstyles{$name};
                    push @pod, "=item * L<$name>\n\n";
                    if (defined $bstyle_struct->{summary}) {
                        require String::PodQuote;
                        push @pod, String::PodQuote::pod_quote($bstyle_struct->{summary}), ".\n\n";
                    }
                    if ($bstyle_struct->{description}) {
                        my $pod = Markdown::To::POD::markdown_to_pod(
                            $bstyle_struct->{description});
                        push @pod, $pod, "\n\n";
                    }
                }
                push @pod, "=back\n\n";
                $self->add_text_to_section(
                    $document, join("", @pod), 'BORDER STYLES',
                    {after_section => ['DESCRIPTION']},
                );
            }

            # add POD section: SEE ALSO
            {
                # XXX don't add if current See Also already mentions it
                my @pod = (
                    "L<BorderStyle> - specification\n\n",
                    "L<App::BorderStyleUtils> - CLIs\n\n",
                    "L<Text::Table::TinyBorderStyle>, L<Text::ANSITable> - some table renderers that can use border styles\n\n",
                );
                $self->add_text_to_section(
                    $document, join('', @pod), 'SEE ALSO',
                    {after_section => ['DESCRIPTION']},
                );
            }

            $self->log(["Generated POD for '%s'", $filename]);

        } elsif ($package =~ /^(?:\A|::)BorderStyle::/) {

            {
                local @INC = ("lib", @INC);
                require $package_pm;
            }
            my $bstyle_struct = \%{"$package\::BORDER"};

            # add POD section: Synopsis
            {
                my @pod;

                my $rows = [[qw/colA colB colC/], [qw/row1A row1B row1C/], [qw/row2A row2B row2C/], [qw/row3A row3B row3C/], ];
                my $q_rows = Data::Dump::dump($rows); $q_rows = s/^/   /gm;

                my $bstyle = $package;
                my $q_bstyle = Data::Dmp::dmp($bstyle);


                require Text::Table::TinyBorderStyle;
                my $q_output = Text::Table::TinyBorderStyle::generate_table(rows=>$rows, header_row=>1, separate_rows=>1, border_style=>$bstyle) . "\n"; $q_output =~ s/^/ /gm;

              EXAMPLE:
                {
                    # TODO: use the first valid example from border style
                    # structure, if available

                    push @pod, <<"_";
To use with L<Text::Table::TinyBorderStyle>:

 use Text::Table::TinyBorderStyle qw/generate_table/;
 my \$rows =
$q_rows;
 generate_table(rows=>\$rows, header_row=>1, separate_rows=>1, border_style=>$q_bstyle);

Sample output:

$q_output

_
                    push @pod, <<"_";
To use with L<Text::ANSITable>:

 # TODO

_
                }
            }

            # add POD section: DESCRIPTION
            {
                last unless $bstyle_struct->{description};
                require Markdown::To::POD;
                my @pod;
                push @pod, Markdown::To::POD::markdown_to_pod(
                    $bstyle_struct->{description}), "\n\n";
                $self->add_text_to_section(
                    $document, join("", @pod), 'DESCRIPTION',
                    {ignore => 1},
                );
            }

            $self->log(["Generated POD for '%s'", $filename]);

        } # BorderStyle::*
    }
}

1;
# ABSTRACT: Plugin to use when building distribution which has BorderStyle::* modules

=for Pod::Coverage weave_section

=head1 SYNOPSIS

In your F<weaver.ini>:

 [-BorderStyle]


=head1 DESCRIPTION

This plugin is used when building a distribution which has BorderStyle::*
modules. It does the following to each F<BorderStyles::*> Perl source code:

=over

=item * Create "BORDER STYLES" POD section from list of BorderStyle::* modules in the distribution

=item * Mention some modules in See Also section

e.g. L<BorderStyle>, L<App::BorderStyleUtils>.

=back

It does the following to each F<BorderStyle::*> Perl source code:

=over

=item * Add "DESCRIPTION" POD section from border style structure's description

=back


=head1 SEE ALSO

L<BorderStyle>

L<Dist::Zilla::Plugin::BorderStyle>
