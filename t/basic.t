use strict;
use warnings;
use Test::More;

use FindBin;
use lib "$FindBin::Bin/lib";

use TestSchema;

my $schema = TestSchema->connect('dbi:SQLite:dbname=:memory:');
isa_ok($schema, 'DBIx::Class::Schema');

$schema->deploy;

my $foos = $schema->resultset('Foo');

my $foo = $foos->create({
    foo => 42,
});

is_deeply([$foo->labels], []);

$foo->add_to_labels('bar,baz');

is_deeply(
    [sort map { $_->name } $foo->labels],
    [qw(bar baz)],
);

my $labels = $schema->resultset('FooLabels');
isa_ok($labels, 'DBIx::Class::ResultSet');

ok(my $baz = $labels->find({ name => 'baz' }));
isa_ok($baz, 'DBIx::Class::Row');

is_deeply(
    [map { $_->foo } $baz->foos],
    [42],
);

$baz->add_to_foos({ foo => 23 });
$baz->discard_changes;

is_deeply(
    [sort map { $_->foo } $baz->foos],
    [23, 42],
);

done_testing;
