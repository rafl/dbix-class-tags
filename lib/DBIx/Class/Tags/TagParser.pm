package DBIx::Class::Tags::TagParser;

use Moose;
use namespace::autoclean;

sub parse {
    my ($self, $tag_str) = @_;
    return map {
        +{ name => $_ }
    } split /\s*,\s*/, $tag_str;
}

__PACKAGE__->meta->make_immutable;

1;
