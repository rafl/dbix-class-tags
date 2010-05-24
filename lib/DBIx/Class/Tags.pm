use strict;
use warnings;

package DBIx::Class::Tags;

use parent 'DBIx::Class';

__PACKAGE__->mk_classdata('_tags_data' => []);

sub setup_tags {
    my ($class, $args) = @_;
    push @{ $class->_tags_data }, $args;
    ();
}


1;
