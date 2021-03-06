#-------------------------------------------------------------------
# WebGUI is Copyright 2001-2012 Plain Black Corporation.
#-------------------------------------------------------------------
# Please read the legal notices (docs/legal.txt) and the license
# (docs/license.txt) that came with this distribution before using
# this software.
#-------------------------------------------------------------------
# http://www.plainblack.com                     info@plainblack.com
#-------------------------------------------------------------------

## Test that trashing a post works, and checking side effects like updating
## lastPost information in the Thread, and CS.

use strict;
use WebGUI::Test;
use WebGUI::Session;
use Test::More tests => 13; # increment this value for each test you create
use WebGUI::Asset::Wobject::Collaboration;
use WebGUI::Asset::Post;
use WebGUI::Asset::Post::Thread;

my $session = WebGUI::Test->session;

# Do our work in the import node
my $node = WebGUI::Asset->getImportNode($session);

# Grab a named version tag
my $versionTag = WebGUI::VersionTag->getWorking($session);
$versionTag->set({name=>"Collab setup"});

# Need to create a Collaboration system in which the post lives.
my $addArgs = { skipAutoCommitWorkflows => 1, skipNotification => 1 };

my $collab = $node->addChild({className => 'WebGUI::Asset::Wobject::Collaboration', }, );

# finally, add posts and threads to the collaboration system

my $first_thread = $collab->addChild(
    { className   => 'WebGUI::Asset::Post::Thread', },
    undef, 
    WebGUI::Test->webguiBirthday, 
    $addArgs,
);

my $second_thread = $collab->addChild(
    { className   => 'WebGUI::Asset::Post::Thread', },
    undef, 
    WebGUI::Test->webguiBirthday, 
    $addArgs,
);

##Thread 1, Post 1 => t1p1
my $t1p1 = $first_thread->addChild(
    { className   => 'WebGUI::Asset::Post', },
    undef, 
    WebGUI::Test->webguiBirthday, 
    $addArgs,
);

my $t1p2 = $first_thread->addChild(
    { className   => 'WebGUI::Asset::Post', },
    undef, 
    WebGUI::Test->webguiBirthday + 1, 
    $addArgs,
);

my $past = time()-15;

my $t2p1 = $second_thread->addChild(
    { className   => 'WebGUI::Asset::Post', },
    undef, 
    $past, 
    $addArgs,
);

my $t2p2 = $second_thread->addChild(
    { className   => 'WebGUI::Asset::Post', },
    undef, undef,
    $addArgs,
);

foreach my $asset ($t1p1, $t1p2, $t2p1, $t2p2, $first_thread, $second_thread, ) {
    $asset->setSkipNotification;
}

$versionTag->commit();
WebGUI::Test->addToCleanup($versionTag);

foreach my $asset ($collab, $t1p1, $t1p2, $t2p1, $t2p2, $first_thread, $second_thread, ) {
    $asset = $asset->cloneFromDb;
}

is $collab->getChildCount, 2, 'collab has correct number of children';

is $collab->get('lastPostId'),   $t2p2->getId, 'lastPostId set in collab';
is $collab->get('lastPostDate'), $t2p2->get('creationDate'), 'lastPostDate, too';

$t2p2->trash;
is $t2p2->get('state'), 'trash', 'cut set the post to be in the clipboard';

$second_thread = $second_thread->cloneFromDb;
is $second_thread->get('lastPostId'),   $t2p1->getId, '.. updated lastPostId in the thread';
is $second_thread->get('lastPostDate'), $t2p1->get('creationDate'), '... lastPostDate, too';

$collab = $collab->cloneFromDb;
is $collab->get('lastPostId'),   $t2p1->getId, '.. updated lastPostId in the CS';
is $collab->get('lastPostDate'), $t2p1->get('creationDate'), '... lastPostDate, too';

$t2p2->restore;
is $t2p2->get('state'), 'published', 'publish sets the post normal';

$second_thread = $second_thread->cloneFromDb;
is $second_thread->get('lastPostId'),   $t2p2->getId, '.. updated lastPostId in the thread';
is $second_thread->get('lastPostDate'), $t2p2->get('creationDate'), '... lastPostDate, too';

$collab = $collab->cloneFromDb;
is $collab->get('lastPostId'),   $t2p2->getId, '.. updated lastPostId in the CS';
is $collab->get('lastPostDate'), $t2p2->get('creationDate'), '... lastPostDate, too';

#vim:ft=perl
