use strict;
use warnings;

package DBIx::Class::Tags;
# ABSTRACT: A simple way of adding "tags" to your DBIx::Class rows

use Class::MOP;
use Carp qw(confess);
use Carp::Clan qw/^DBIx::Class/;
use aliased 'DBIx::Class::Tags::TagParser';

use parent 'DBIx::Class';

__PACKAGE__->mk_classdata(_tags_data => []);
__PACKAGE__->mk_classdata('tag_parser');

__PACKAGE__->tag_parser(TagParser->new);

=head1 SYNOPSIS

    package MySchema;
    __PACKAGE__->load_components(qw(Schema::Tags));
    # regular schema setup goes here
    __PACKAGE__->setup_tags;

    package MySchema::Result::Foo;
    __PACKAGE__->load_components(qw(Tags));
    # regular result source setup goes here
    __PACKAGE__->setup_tags([
        rel      => 'labels',
        back_rel => 'foos',
        moniker  => 'Labels',
    ]);

    # later on, in the code using MySchema
    $foo_row->add_to_labels('bar, baz, moo');
    my @foos_labeled_bar = $schema->resultset('FooLabels')->find({ name => 'bar' })->foos;

=head1 DESCRIPTION

This module is intended to make adding tag-like data to your dbic
results as easy as possible. It can provide a tags table as, a link
table to your existing results, as well as helper methods for
modifying tags.

=method setup_tags (\@tag_specs | \%tag_spec)

This method sets up tags for a result source. It takes either a tag
specification, C<\%tag_spec>, or a list of tag specifications,
C<\@tag_specs>.

A tag specification is a hash reference of the following structure:

=for :list
* rel
The name of the many_to_many relation to the tag table
* back_rel
The name of the many_to_many relation back from the tag table
* moniker?
The name that will be used to build the name of the generated result
sources from. If unspecified, it defaults to C<Tags>.

B<NOTE:> calling C<setup_tags> in your result source is not enough to
set everything up. You will also need to
L<DBIx::Class::Schema::Tags/setup_tags> in your schema using your
result source.

In addition to set up the required relations for your tags, this will
also install helper methods to make modifying tags easy. These methods
are:

=begin :list

* add_to_${rel}

This is exactly like the C<add_to_${rel}> method provided by
L<DBIx::Class::Relationship/many_to_many>, except you may additionally
call it with with a string as its only argument. This string will be
parsed using your result's C<tag_parser>, and each result of the
parsing will be passed to the original C<add_to_${rel}> implementation
as provided by L<DBIx::Class::Relationship/many_to_many>.

* remove_from_${rel}

This behaves just like the C<add_to_${rel}> method described above,
but will call the C<remove_from_${rel}> method as provided by
L<DBIx::Class::Relationship/many_to_many>.

* set_${rel}

This is exactly like the C<set_${rel}> method provided by
L<DBIx::Class::Relationship/many_to_many>, except you may additionally
call it with a string as its only argument. THis string will be parsed
using your result's C<tag_parser>. The list of parse results will be
passed to the original C<set_${rel}> from
L<DBIx::CLass::Relationship/many_to_many>.

=end :list

=method tag_parser

This method is called to retrieve the tag parser used to parse tag
strings in the helper methods installed by C<setup_tags>. By default,
an instance of L<DBIx::Class::Tags::TagParser> is returned.

=cut

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
                $self->$orig($_) for $self->tag_parser->parse($args[0]);
            });
        });

        $meta->add_around_method_modifier("set_${rel}" => sub {
            my ($orig, $self, @args) = @_;

            @args = [$self->tag_parser->parse($args[0])]
                if @args == 1 && !ref $args[0];

            return $self->result_source->schema->txn_do(sub {
                $self->$orig(@args);
            });
        });

        $meta->add_around_method_modifier("remove_from_${rel}" => sub {
            my ($orig, $self, @args) = @_;

            return $self->$orig(@args)
                unless @args == 1 && !ref $args[0];

            my $rs = $self->result_source->resultset;
            my $tag_rs = $rs->search_related($m_rel)->search_related('tag');
            my @tags = grep defined, map { $tag_rs->find($_) }
                $self->tag_parser->parse($args[0]);

            return $self->result_source->schema->txn_do(sub {
                $self->$orig($_) for @tags;
            });
        });
    }

    ();
}

1;
