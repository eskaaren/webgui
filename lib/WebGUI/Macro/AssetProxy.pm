package WebGUI::Macro::AssetProxy;

#-------------------------------------------------------------------
# WebGUI is Copyright 2001-2005 Plain Black Corporation.
#-------------------------------------------------------------------
# Please read the legal notices (docs/legal.txt) and the license
# (docs/license.txt) that came with this distribution before using
# this software.
#-------------------------------------------------------------------
# http://www.plainblack.com                     info@plainblack.com
#-------------------------------------------------------------------

use strict;
use WebGUI::Asset;
use WebGUI::Macro;
use WebGUI::Session;

#-------------------------------------------------------------------
sub process {
        my ($url) = WebGUI::Macro::getParams(shift);
	my $asset = WebGUI::Asset->newByUrl($url);
	#Sorry, you cannot proxy the notfound page.
	if (defined $asset && $asset->getId ne $session{setting}{notFoundPage}) {
		$asset->toggleToolbar;
		return $asset->canView ? $asset->view : undef;
	} else {
		return "Invalid Asset URL";
	}
}


1;


