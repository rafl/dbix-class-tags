use strict;
use warnings;

package TestSchema::Result::Foo;

use parent 'DBIx::Class::Core';

__PACKAGE__->load_components(qw(Tags));

__PACKAGE__->table('foo');
__PACKAGE__->add_columns(
    id => {
        data_type         => 'integer',
        is_nullable       => 0,
        is_auto_increment => 1,
    },
    foo => {
        data_type   => 'text',
        is_nullable => 0,
    },
);

__PACKAGE__->set_primary_key('id');

__PACKAGE__->setup_tags({
    rel      => 'labels',
    back_rel => 'foos',
    moniker  => 'Labels',
});

1;
