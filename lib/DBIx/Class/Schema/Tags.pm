package DBIx::Class::Schema::Tags;

use parent 'DBIx::Class::Schema';

use aliased 'DBIx::Class::ResultSource::Table';

use Class::MOP;

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

    my $moniker = exists $tag->{moniker}
        ? $tag->{moniker}
        : 'Tags';

    my $tags_class = exists $tag->{class}
        ? $tag->{class}
        : join q{::} => $source->result_class, $moniker;

    my $tags_m_class = exists $tag->{m_class}
        ? $tag->{m_class}
        : join q{::} => $source->result_class, 'M' . $moniker;

    Class::MOP::Class->create(
        $_,
        superclasses => ['DBIx::Class::Core'],
    ) for $tags_class, $tags_m_class;

    $tags_class->table( join q{_} => $source->name, $tag->{rel} );
    $tags_class->add_columns(
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

    $tags_class->set_primary_key('id');
    $tags_class->add_unique_constraint(['name']);

    my $m_rel = join q{_} => 'm', $tag->{rel};
    $tags_class->has_many(
        $m_rel => $tags_m_class,
        { 'foreign.r_id' => 'self.id' },
    );

    $tags_class->many_to_many($tag->{back_rel} => $m_rel, $source->name);


    $tags_m_class->table( join q{_} => $source->name, 'm', $tag->{rel} );

    my @l_pk = $source->primary_columns;
    my %ml_pk = map {
        ("l_${_}" => {
            %{ $source->column_info($_) || {} },
            is_foreign_key    => 1,
            is_auto_increment => 0,
        })
    } @l_pk;

    $tags_m_class->add_columns(
        'r_id' => {
            data_type         => 'integer',
            is_nullable       => 0,
            is_foreign_key    => 1,
            is_auto_increment => 0,
        },
        %ml_pk,
    );

    $tags_m_class->set_primary_key('r_id', keys %ml_pk);

    $tags_m_class->belongs_to(
        tag => $tags_class,
        { 'foreign.id' => 'self.r_id' },
    );

    $tags_m_class->belongs_to(
        $source->name => $source->result_class,
        { map { ("foreign.${_}" => "self.l_${_}") } @l_pk },
    );

    my $tags_moniker = join q{} => $source->source_name, $moniker;
    $tags_class->result_source_instance->source_name($tags_moniker);

    my $tags_m_moniker = join q{} => $source->source_name, 'M', $moniker;
    $tags_m_class->result_source_instance->source_name($tags_m_moniker);

    $class->register_source($tags_moniker => $tags_class->result_source_instance);
    $class->register_source($tags_m_moniker => $tags_m_class->result_source_instance);

    ();
}

1;
