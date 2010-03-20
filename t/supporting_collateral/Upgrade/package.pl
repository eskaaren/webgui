::addToCleanup(version_tag);

import_package('test-template.wgpkg');

my $assets = version_tag->getAssets;

::is scalar @$assets, 1, 'imported one asset with package';

::isa_ok $assets->[0], 'WebGUI::Asset::Template';


