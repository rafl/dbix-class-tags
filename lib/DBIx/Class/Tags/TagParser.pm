package DBIx::Class::Tags::TagParser;
# ABSTRACT: An extremely stupid and prejudiced tag string parser

use Moose;
use Text::Trim;
use namespace::autoclean;

=head1 SYNOPSIS

    my $parser = DBIx::Class::Tags::TagParser->new;
    my @tags = $parser->parse('foo, bar, baz');

=head1 DESCRIPTION

This is the default tag parser used by L<DBIx::Class::Tags>.

=method parse ($tag_str)

Parses the string of tags C<$tag_str>. Tags within the string are
separated by commas, which may be enclosed by whitespace. Whitespace
before and after tags is stripped.

A list of hash references describing each parsed tag is returned. Each
hash reference only has one key, C<name>. The value for that key is
the name of the parsed tag.

=cut

sub parse {
    my ($self, $tag_str) = @_;
    return map {
        +{ name => $_ }
    } trim split /,/, $tag_str;
}

__PACKAGE__->meta->make_immutable;

1;
