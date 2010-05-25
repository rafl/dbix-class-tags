package DBIx::Class::Tags::TagParser;

use Moose;
use Text::Trim;
use namespace::autoclean;

sub parse {
    my ($self, $tag_str) = @_;
    return map {
        +{ name => $_ }
    } trim split /,/, $tag_str;
}

__PACKAGE__->meta->make_immutable;

1;
