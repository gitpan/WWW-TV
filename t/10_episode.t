#! /usr/bin/perl
use strict;
use warnings;

use Test::More qw(no_plan);

use_ok('WWW::TV::Episode');

{   # Create a blank episode with a name but don't check anything else
    # because that would hit up the interwebs.
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
    isa_ok(
        my $episode = WWW::TV::Episode->new(id => 423504),
        'WWW::TV::Episode',
    );
    ok($episode->summary =~ /Fox River/, 'summary');
    is($episode->season_number, 1, 'season number');
    is($episode->episode_number, 1, 'episode_number');
    is($episode->first_aired, 'August 29, 2005', 'first_aired');
}

exit 0;
