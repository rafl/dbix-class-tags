package DBIx::Class::Schema::Tags;

use parent 'DBIx::Class::Schema';

use aliased 'DBIx::Class::ResultSource::Table';

sub setup_tags {
    my ($class, $args) = @_;
    my %sources = map { ($_ => $class->source($_)) } $class->sources;
    for my $source_name (keys %sources) {
        my $source = $sources{$source_name};
        my @tags = @{ $source->result_class->_tags_data || [] };
        next unless @tags;
        $class->setup_tags_for_source($source_name, $source, $_) for @tags;
    }
}

sub setup_tags_for_source {
    my ($class, $source_name, $source, $tag) = @_;

    my $tags_name = sprintf 'tags_%s_%s', $source->{name}, $tag->{rel};
    my $tags = Table->new({ name => $tags_name });

    $tags->add_columns(
        (@{ $tag->{columns} || [] }),
        id => {
            data_type         => 'integer',
            is_nullable       => 0,
            is_auto_increment => 1,
        },
        name => {
            data_type   => 'text',
            is_nullable => 0,
        },
    );

    $tags->set_primary_key('id');
    $tags->add_unique_constraint(['name']);

    my $tags_m_name = sprintf 'tags_%s_to_%s', $source->{name}, $tag->{rel};
    my $tags_m = Table->new({ name => $tags_m_name });

    $tags_m->add_columns(
        tag => {
            data_type         => 'integer',
            is_nullable       => 0,
            is_auto_increment => 0,
            is_foreign_key    => 1,
        },
        (map {
            ($_ => {
                %{ $source->column_info($_) || {} },
                is_foreign_key    => 1,
                is_auto_increment => 0,
            })
        } $source->primary_columns),
    );

    $tags_m->set_primary_key(qw(tag));

    $tags_m->add_relationship(
        tag => $tags_name,
        { 'foreign.id' => 'me.tag' },
        { accessor => 'single', is_foreign_key_constraint => 1 },
    );

    $tags_m->add_relationship(
        $tag->{thingy} => $source_name,
        { 'foreign.id' => 'me.id' },
        { accessor => 'single', is_foreign_key_constraint => 1 },
    );

    $source->add_relationship(
        $tag->{rel} => $tags_m_name,
        { },
        { },
    );

    use Data::Dump 'pp';
    pp $source;

    $class->register_source($tags_name => $tags);
    $class->register_source($tags_m_name => $tags_m);
    $class->register_source($source_name => $source);

    ();
}

1;
