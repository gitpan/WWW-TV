=head1 NAME

WWW::TV::Series - Parse TV.com for TV Series information.

=head1 SYNOPSIS

  use WWW::TV::Series qw();
  my $series = WWW::TV::Series->new(name => 'Prison Break');

  my @episodes = $series->episodes;
  print $series->summary;

=head1 DESCRIPTION

The L<WWW::TV::Series> module parses TV.com series information using
L<LWP::UserAgent>.

=head1 METHODS

=cut

package WWW::TV::Series;
use strict;
use warnings;

our $VERSION = '0.05';

use Carp qw(croak);
use LWP::UserAgent qw();

=head2 new

    The new() method is the constructor. It takes the id of the show if
    you have previously looked that up, or the name of the show which
    will be used to perform a search and the id will be taken from the
    first result.

        my $series = WWW::TV::Series->new(name => 'Prison Break');
        my $series = WWW::TV::Series->new(id => 31635);

    It is recommended that you lookup the show first and use the ID,
    otherwise you just don't know what will be returned.

    The constructor also takes a single scalar as an argument and does
    it's best to figure out what you want. But due to some shows being
    all digits as a name (e.g. "24"), use of this is not recommended
    (and in future may be deprecated).

=cut

sub new {
    my $class = ref $_[0] ? ref(shift) : shift;

    my %data;
    if (@_ == 1) {
        # If they gave us a plain scalar argument, try our best to figure out
        # what it is. Of course this dies in the arse if you want to search
        # for a program with a name like '24'.
        if ($_[0] =~ /^\d+$/) {
            $data{id} = shift;
        }
        else {
            $data{name} = shift;
        }
    }
    elsif (scalar(@_) % 2 == 0) {
        %data = @_;
    }

    $data{id} = $class->_get_first_search_result($data{name})
        if exists $data{name};

    croak 'No id or name given to constructor' unless exists $data{id};
    croak "Invalid id: $data{id}" unless $data{id} =~ /^\d+$/;

    return bless {
        id     => $data{id},
        filled => { id => 1 },
    }, $class;
}

sub _get_first_search_result {
    my ($class, $name) = @_;

    my $rc = LWP::UserAgent->new->get(
        "http://www.tv.com/search.php?stype=program&qs=$name"
    );
    croak "Unable to get search results for $name" unless $rc->is_success;

    for (split /\n/, $rc->content) {
        next unless m#
            ^
            \s+
            <a\s.*?\shref="http://www.tv.com/.*?show/(\d+)/summary.html
            \?q=.*?&tag=search_results
        #x;
        return $1;
    }
    croak 'Unable to find a show in the search results.';
}

=head2 summary

    Returns a string containing basic information about this series.

=cut

sub summary {
    my ($self) = @_;
    return $self->{summary} if exists $self->{filled}->{summary};
    $self->{filled}->{summary} = 1;

    ($self->{summary}) = $self->_html =~ m{
            <div\sclass="mt-10">\n
            (?:
                <a\sclass="default-image\smore"\shref=.*?>\n
                <img\ssrc=.*?\s/>More\sPictures\s*</a>\n
            )?
            (.*?)\n
            </div>\n
    }sx;

    return $self->{summary};
}

=head2 genres

    Returns a string containing a comma delimited list of all the genres
    that TV.com have categorised this series as.

        my $genres = $series->genres;
        my @genres = split(/,/, $series->genres);

=cut

sub genres {
    my ($self) = @_;
    return $self->{genres} if exists $self->{filled}->{genres};
    $self->{filled}->{genres} = 1;

    my ($genres_row) = $self->_html =~ m{
        Show\sCategories:\n
        (<a\shref=.*</a>)
    }x;

    $self->{genres} =
        join(
            ', ',
            map { s/\s*<a href="[^"]+">(.*?)<\/a>\s*/$1/; $_ }
            split(/,/, $genres_row)
        );

    return $self->{genres};
}

=head2 cast

    A comma delimited string of the cast members. The order is the same
    as they appear on TV.com, which is most likely nothing to go by, but
    in most cases is the main cast order.

=cut

sub cast {
    my ($self) = @_;
    return $self->{cast} if exists $self->{filled}->{cast};
    $self->{filled}->{cast} = 1;

    my @cast;
    for my $line (split /\n/, $self->_html) {
        next unless $line =~ m{
            <a\s.*?href="http://www\.tv\.com/.*?person/\d+/summary\.html
            \?.*?tag=cast;name;\d+">(.*?)</a>
        }x;
        push @cast, $1;
    }
    $self->{cast} = join(', ', @cast);

    return $self->{cast};
}

=head2 name

    Returns a string containing the name of the series.

=cut

sub name {
    my ($self) = @_;
    return $self->{name} if exists $self->{filled}->{name};
    $self->{filled}->{name} = 1;

    ($self->{name}) = $self->_html =~ m{
        <div\sid="content-head".*?>\n\n?
        <h1>(.*?)</h1>\n
    }x;

    return $self->{name};
}

=head2 image

    Returns the url of an image that can be used to identify this series.

=cut

sub image {
    my ($self) = @_;
    return $self->{image} if exists $self->{filled}->{image};
    $self->{filled}->{image} = 1;

    ($self->{image}) = $self->_html =~ m{
        <a\sclass="default-image\smore"\shref=".+;image">\n
        <img\ssrc="(.+)"\salt=".+"\s/>More\sPictures\s+</a>\n
    }x;

    return $self->{image};
}

=head2 episodes

    Returns an array of L<WWW::TV::Episode> objects in order.

=cut

sub episodes {
    my ($self) = @_;
    return @{$self->{episodes}} if $self->{filled}->{episodes};
    $self->{filled}->{episodes} = 1;

    my $rc = LWP::UserAgent->new->get($self->episode_url);
    croak sprintf('Unable to fetch episodes for series %s', $self->id)
        unless $rc->is_success;

    require WWW::TV::Episode;
    my @episodes =
        grep { defined }
        map {
            my $ep;
            if (m#<a href=".*/episode/(\d+)/summary\.html[^"]*">(.*)</a>#) {
                $ep = WWW::TV::Episode->new(id => $1, name => $2);
            }
            $ep;
        } split /\n/, $rc->content;

    $self->{episodes} = \@episodes;
    return @episodes;
}

sub _html {
    my ($self) = @_;
    return $self->{html} if $self->{filled}->{html};
    $self->{filled}->{html} = 1;

    my $rc = LWP::UserAgent->new->get($self->url);
    croak sprintf('Unable to fetch page for series %s', $self->id)
        unless $rc->is_success;

    $self->{html} =
        join(
            "\n",
            map { s/^\s*//; s/\s*$//; $_ }
            split /\n/, $rc->content
        );

    return shift->{html};
}

=head2 id

    The ID of this series, according to TV.com

=cut

sub id {
    return shift->{id};
}

=head2 url

    Returns the url that was used to create this object.

=cut

sub url {
    return sprintf('http://www.tv.com/show/%d/summary.html', shift->id);
}

=head2 episode_url

    Returns the url that is used to get the episode listings for this
    series.

=cut

sub episode_url {
    return sprintf(
        'http://www.tv.com/show/%d/episode_listings.html?season=0',
        shift->id
    );
}

1;

__END__

=head1 SEE ALSO

L<WWW::TV::Episode>

=head1 KNOWN ISSUES

There isn't yet any caching support. I don't see a need for it, but if you feel
the need to implement it then don't let me stop you.

There also isn't support for proxy servers yet. LWP should use it from your
environment if you really need it, but who still uses them anyway? Isn't it all
done transparently these days.

=head1 BUGS

Please report any bugs or feature requests to
C<bug-WWW-TV@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 AUTHOR

Danial Pearce C<cpan@tigris.id.au>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2006, Danial Pearce C<cpan@tigris.id.au>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.
