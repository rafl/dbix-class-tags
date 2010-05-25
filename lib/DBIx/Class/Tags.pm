use strict;
use warnings;

package DBIx::Class::Tags;

use Class::MOP;
use Carp qw(confess);
use Carp::Clan qw/^DBIx::Class/;
use aliased 'DBIx::Class::Tags::TagParser';

use parent 'DBIx::Class';

__PACKAGE__->mk_classdata(_tags_data => []);
__PACKAGE__->mk_classdata('_tag_parser');

__PACKAGE__->_tag_parser(TagParser->new);

sub setup_tags {
    my ($class, $args) = @_;
    $args = [$args] unless ref $args eq 'ARRAY';
    $class->_tags_data($args);

    for my $tag (@{ $args }) {
        my $rel = $tag->{rel};

        my $moniker = exists $tag->{moniker}
            ? $tag->{moniker}
            : 'Tags';

        my $tags_class = exists $tag->{class}
            ? $tag->{class}
            : join q{::} => $class, $moniker;

        my $tags_m_class = exists $tag->{m_class}
            ? $tag->{m_class}
            : join q{::} => $class, 'M' . $moniker;

        my $m_rel = join q{_} => 'm', $rel;

        my @pk = $class->primary_columns;
        $class->has_many(
            $m_rel => $tags_m_class,
            { map { ("foreign.l_${_}" => "self.${_}") } @pk },
        );

        $class->many_to_many(
            $rel => $m_rel,
            'tag',
        );

        my $meta = Class::MOP::Class->initialize($class);

        $meta->add_around_method_modifier("add_to_${rel}" => sub {
            my ($orig, $self, @args) = @_;

            return $self->$orig(@args)
                unless @args == 1 && !ref $args[0];

            return $self->result_source->schema->txn_do(sub {
                $self->$orig($_) for $self->_tag_parser->parse($args[0]);
            });
        });

        $meta->add_around_method_modifier("set_${rel}" => sub {
            my ($orig, $self, @args) = @_;

            @args = [$self->_tag_parser->parse($args[0])]
                if @args == 1 && !ref $args[0];

            return $self->$orig(@args);
        });

        $meta->add_around_method_modifier("remove_from_${rel}" => sub {
            my ($orig, $self, @args) = @_;

            return $self->$orig(@args)
                unless @args == 1 && !ref $args[0];

            my $rs = $self->result_source->resultset;
            my $tag_rs = $rs->search_related($m_rel)->search_related('tag');
            my @tags = grep defined, map { $tag_rs->find($_) }
                $self->_tag_parser->parse($args[0]);

            return $self->result_source->schema->txn_do(sub {
                $self->$orig($_) for @tags;
            });
        });
    }

    ();
}

1;
