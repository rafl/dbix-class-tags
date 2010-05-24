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

$foo->add_to_labels({ name => 'bar' });
$foo->add_to_labels({ name => 'baz' });

done_testing;
