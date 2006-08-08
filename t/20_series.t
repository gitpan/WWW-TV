#! /usr/bin/perl
use strict;
use warnings;

use Test::More qw(no_plan);

use_ok('WWW::TV::Series');

{ # MASH via id =>
    isa_ok(my $series = WWW::TV::Series->new(id => 119), 'WWW::TV::Series');
    is($series->name, 'M*A*S*H', 'name');
    is($series->url, 'http://www.tv.com/show/119/summary.html', 'url');
    ok($series->genres =~ /Comedy/, 'genres');
}

{ # Prison Break via name =>
    isa_ok(
        my $series = WWW::TV::Series->new(name => 'Prison Break'),
        'WWW::TV::Series',
    );
    ok($series->summary =~ /death row/, 'summary');
    ok($series->cast =~ /Wentworth Miller/, 'cast');
    ok($series->image =~ /\.jpg$/, 'image');
}

{ # Joey via id =>, and check episodes from both season 1 and 2
    isa_ok(my $series = WWW::TV::Series->new(id => 20952), 'WWW::TV::Series');
    is($series->name, 'Joey', 'name');
    isa_ok(
        my $episode_1 = ($series->episodes)[1], # Skip pilot episode
        'WWW::TV::Episode',
    );
    is($episode_1->name, 'Joey and the Student', 'episode name');
    is($episode_1->season_number, 1, 'episode season');
    isa_ok(
        my $episode_27 = ($series->episodes)[26], # From season 2
        'WWW::TV::Episode',
    );
    is($episode_27->name, 'Joey and the Spanking', 'episode name');
    is($episode_27->season_number, 2, 'episode season');
    isa_ok($episode_27->series, 'WWW::TV::Series');
    is($episode_27->series->name, 'Joey', 'episode series');
}

exit 0;
