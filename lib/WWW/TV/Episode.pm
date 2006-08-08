=head1 NAME

WWW::TV::Episode - Parse TV.com for TV Episode information.

=head1 SYNOPSIS

  use WWW::TV::Episode qw();
  my $episode = WWW::TV::Series->new(id => '475567');

  print $episode->summary;

=head1 DESCRIPTION

The L<WWW::TV::Episode> module parses TV.com episode information using
L<LWP::UserAgent>. Unfortunately I can't see a way to search for an episode
by name, so I haven't implemented it. It is probably possible to do so if you
populate a series object and grep $series->episodes for the episode name you
are searching for.

=head1 METHODS

=cut

package WWW::TV::Episode;
use strict;
use warnings;

our $VERSION = '0.02';

use Carp qw(croak);
use LWP::UserAgent qw();

=head2 new

    The new() method is the constructor. It takes the id of the show
    assuming you have previously looked that up.

        my $episode = WWW::TV::Episode->new(id => 475567);

    It also (optionally) takes the name of the episode. This is not used
    in any way to search for the episode, but is used as initial data
    population for that field so that the html isn't parsed if you only
    want an object with the name. This is used by the L<WWW::TV::Series>
    object to populate a big array of episodes that have names without
    needing to fetch any pages.

=cut

sub new {
    my $class = ref $_[0] ? ref(shift) : shift;

    ## golfed by Shane Hanna
    my ($id, $name) = @_ % 2 ? shift : @{{@_}}{qw(id name)};
    croak 'Invalid id' unless defined $id and $id =~ /^\d+$/;

    return bless {
        id     => $id,
        name   => $name,
        filled => {
            id => 1,
            $name
                ? (name => 1)
                : (),
        },
    }, $class;
}

=head2 id

    The ID of this episode, according to TV.com

=cut

sub id {
    return shift->{id};
}

=head2 name

    Returns a string containing the name of the episode.

=cut

sub name {
    my ($self) = @_;
    return $self->{name} if exists $self->{filled}->{name};
    $self->{filled}->{name} = 1;

    ($self->{name}) = $self->_html =~ m{
        <td\svalign="top"\sclass="pr-10\spl-10">\n
        \s*<h1>(.*?)</h1>\n
    }x;

    return $self->{name};
}

=head2 summary

    Returns a string containing basic information about this series.

=cut

sub summary {
    my ($self) = @_;
    return $self->{summary} if exists $self->{filled}->{summary};
    $self->{filled}->{summary} = 1;

    ($self->{summary}) = $self->_html =~ m{
      <div\sid="full-col-wrap">\n
      \n
      <div\sid="main-col">\n
      \n
      <div>\n
      (.*?)
      <div\sclass="ta-r\smt-10\sf-bold">\n
    }sx;

    $self->{summary} =~ s{<br(?: /)?>}{}g;

    return $self->{summary};
}

=head2 season_number

    Returns the season number that this episode appeared in.

=cut

sub season_number {
    my ($self) = @_;
    return $self->{season_number} if exists $self->{filled}->{season_number};
    $self->_fill_vitals;
    return $self->{season_number};
}

=head2 episode_number

    Returns the overall number of this episode. Note, this is not
    necessarily the production order of the episodes, but is the order
    in which they aired.

=cut

sub episode_number {
    my ($self) = @_;
    return $self->{episode_number} if exists $self->{filled}->{episode_number};
    $self->_fill_vitals;
    return $self->{episode_number};
}

=head2 first_aired

    Returns a string of the date this episode first aired.

=cut

sub first_aired {
    my ($self) = @_;
    return $self->{first_aired} if exists $self->{filled}->{first_aired};
    $self->_fill_vitals;
    return $self->{first_aired};
}

=head2 stars

    Returns a comma delimited string of the stars that appeared in this episode

=cut

sub stars {
    my ($self) = @_;
    return $self->{stars} if exists $self->{filled}->{stars};
    $self->{filled}->{stars} = 1;

    my ($stars) = $self->_html =~ m{
            Star:\n
        </td>\n
        <td>\n
            (<a\shref=.*)
    }x;

    my @stars;
    for my $star (split /,&nbsp;/, $stars) {
        next unless $star =~ m{<a href="[^"]+">(.*?)</a> \(.*?\)};
        push @stars, $1;
    }

    $self->{stars} = join(', ', @stars);
    return $self->{stars};
}

=head2 guest_stars

    Returns a comma delimited string of the guest stars that appeared in this
    episode

=cut

sub guest_stars {
    my ($self) = @_;
    return $self->{guest_stars} if exists $self->{filled}->{guest_stars};
    $self->{filled}->{guest_stars} = 1;

    my ($stars) = $self->_html =~ m{
            Guest\sStar:\n
        </td>\n
        <td>\n
            (<a\shref=.*)
    }x;

    my @stars;
    for my $star (split /,&nbsp;/, $stars) {
        next unless $star =~ m{<a href="[^"]+">(.*?)</a> \(.*?\)};
        push @stars, $1;
    }

    $self->{guest_stars} = join(', ', @stars);
    return $self->{guest_stars};
}

=head2 recurring_roles

    Returns a comma delimited string of the people who have recurring roles
    that appeared in this episode

=cut

sub recurring_roles {
    my ($self) = @_;
    return $self->{recurring_roles} if exists $self->{filled}->{recurring_roles};
    $self->{filled}->{recurring_roles} = 1;

    my ($stars) = $self->_html =~ m{
            Recurring\sRole:\n
        </td>\n
        <td>\n
            (<a\shref=.*)
    }x;

    my @stars;
    for my $star (split /,&nbsp;/, $stars) {
        next unless $star =~ m{<a href="[^"]+">(.*?)</a> \(.*?\)};
        push @stars, $1;
    }

    $self->{recurring_roles} = join(', ', @stars);
    return $self->{recurring_roles};
}

=head2 writer

    Returns a comma delimited string of the people that wrote this episode

=cut

sub writer {
    my ($self) = @_;
    return $self->{writer} if exists $self->{filled}->{writer};
    $self->{filled}->{writer} = 1;

    ($self->{writer}) = $self->_html =~ m{
            Writer:\n
        </td>\n
        <td>\n
            <a\shref="[^"]+">(.*?)</a>
    }x;

    return $self->{writer};
}

=head2 director

    Returns a comma delimited string of the people that directed this episode

=cut

sub director {
    my ($self) = @_;
    return $self->{director} if exists $self->{filled}->{director};
    $self->{filled}->{director} = 1;

    ($self->{director}) = $self->_html =~ m{
            Director:\n
        </td>\n
        <td>\n
            <a\shref="[^"]+">(.*?)</a>
    }x;

    return $self->{director};
}

=head2 url

    Returns the url that was used to create this object.

=cut

sub url {
    return sprintf('http://www.tv.com/episode/%d/summary.html', shift->id);
}

=head2 series

    Returns an L<WWW::TV::Series> object which is the series that this
    episode is a part of.

=cut

sub series {
    my ($self) = @_;
    return $self->{series} if exists $self->{filled}->{series};
    $self->{filled}->{series} = 1;

    my ($id) = $self->_html =~ m{
        <a\shref=".*/show/(\d+)/episode_listings\.html">Episodes</a>
    }sx;

    require WWW::TV::Series;
    $self->{series} = WWW::TV::Series->new(id => $id);

    return $self->{series};
}

sub _fill_vitals {
    my ($self) = @_;

    ($self->{episode_number}, $self->{season_number}, $self->{first_aired})
        = $self->_html
        =~ m{
            <span\sclass="f-bold\sf-666">
            Episode\sNumber:\s(\d+)
            \s&nbsp;&nbsp;\s
            Season\sNum:\s(\d+)
            \s&nbsp;&nbsp;\s
            First\sAired:\s\w+\s(\w+\s\d\d?,\s\d{4})
        }sx;

    $self->{filled}->{$_} = 1 for qw(episode_number season_number first_aired);

    return $self->_parse_first_aired;
}

sub _parse_first_aired {
    my ($self) = @_;
    my ($month, $day, $year) = $self->{first_aired} =~ m{^
        (\w+)
        \s*(\d+),
        \s*(\d+)
    $}x;
    $month = {
        January   => 1,
        February  => 2,
        March     => 3,
        April     => 4,
        May       => 5,
        June      => 6,
        July      => 7,
        August    => 8,
        September => 9,
        October   => 10,
        November  => 11,
        December  => 12,
    }->{$month};
    $self->{first_aired} = sprintf('%04d-%02d-%02d', $year, $month, $day);
    return 1;
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

1;

__END__

=head1 SEE ALSO

L<WWW::TV::Series>

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
