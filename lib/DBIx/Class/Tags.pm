use strict;
use warnings;

package DBIx::Class::Tags;

use parent 'DBIx::Class';

__PACKAGE__->mk_classdata('_tags_data' => []);

sub setup_tags {
    my ($class, $args) = @_;
    $args = [$args] unless ref $args eq 'ARRAY';
    $class->_tags_data($args);

    for my $tag (@{ $args }) {
        my $moniker = exists $tag->{moniker}
            ? $tag->{moniker}
            : 'Tags';

        my $tags_class = exists $tag->{class}
            ? $tag->{class}
            : join q{::} => $class, $moniker;

        my $tags_m_class = exists $tag->{m_class}
            ? $tag->{m_class}
            : join q{::} => $class, 'M', $moniker;

        my $m_rel = join q{_} => 'm', $tag->{rel};

        my @pk = $class->primary_columns;
        $class->has_many(
            $m_rel => $tags_m_class,
            { map { ("foreign.l_${_}" => "self.${_}") } @pk },
        );

        $class->many_to_many(
            $tag->{rel} => $m_rel,
            'tag',
        );
    }

    ();
}


1;
