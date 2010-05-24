use strict;
use warnings;

package TestSchema;

use parent 'DBIx::Class::Schema';

__PACKAGE__->load_namespaces;

__PACKAGE__->load_components(qw(Schema::Tags));

__PACKAGE__->setup_tags({
});

1;
