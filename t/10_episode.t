#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 23;

use_ok('WWW::TV::Episode');

{   # Create a blank episode with a name but don't check anything else
    # because that would hit up the interwebs.
    diag("Testing with generic episode prepopulated with name only")
        unless $ENV{HARNESS_ACTIVE};
    isa_ok(
        my $episode = WWW::TV::Episode->new(
            id   => 1,
            name => 'foo',
        ),
        'WWW::TV::Episode'
    );
    is($episode->id, 1, 'id');
    is($episode->name, 'foo', 'name');
}

{   # Pilot episode for Prison Break
    diag("Testing by ID using pilot episode for Prison Break")
        unless $ENV{HARNESS_ACTIVE};
    isa_ok(
        my $episode = WWW::TV::Episode->new(id => 423504),
        'WWW::TV::Episode',
    );
    ok($episode->summary =~ /Fox River/, 'summary includes: Fox River');
    ok($episode->summary !~ /Watch Video/, 'summary does not include: Watch Video');
    is($episode->name, 'Pilot', 'title is: Pilot');
    is($episode->season_number, 1, 'season number is 1');
    is($episode->episode_number, 1, 'episode_number is 1');
    ok($episode->stars =~ /\bWentworth Miller\b/, 'stars include: Wentworth Miller');
    ok($episode->guest_stars =~ /\bJeff Parker\b/, 'guest_stars include: Jeff Parker');
    ok($episode->recurring_roles =~ /\bStacy Keach\b/, 'recurring_roles include: Stacy Keach');
    is($episode->directors, 'Brett Ratner', 'directors is: Brett Ratner');
    is($episode->writers, 'Paul T. Scheuring', 'writers is: Paul T. Scheuring');
    is($episode->first_aired, '2005-08-29', 'first_aired is: 2005-08-29');

    is(
        $episode->format_details,
        'Prison Break.s01e01 - Pilot',
        'format_details with default settings'
    );
    is(
        $episode->format_details('Series %I: %N, Episode %i: %n (%d)'),
        'Series 31635: Prison Break, Episode 423504: Pilot (2005-08-29)',
        'format_details with crazy string'
    );

    diag('Checking $episode->series') unless $ENV{HARNESS_ACTIVE};
    my $series = $episode->series;
    isa_ok($series, 'WWW::TV::Series');

    diag('Checking $episode->season') unless $ENV{HARNESS_ACTIVE};

    my @season_eps = $episode->season;
    is(scalar(@season_eps), 23, '23 episodes for season 1');
}

{   # Get the last episode of the Mr. Bean animated series which never aired
    # and check to make sure the first aired date comes back ok.
    diag('Testing an episode that never aired') unless $ENV{HARNESS_ACTIVE};
    isa_ok(
        my $episode = WWW::TV::Episode->new(id => 331173),
        'WWW::TV::Episode',
    );
    is(
        $episode->name,
        'Egg & Bean / Hopping Mad',
        'got the right Mr Bean ep'
    );
    is($episode->first_aired, 'n/a', 'first aired is n/a');
}

exit 0;
