package WebGUI;
our $VERSION = "3.0.1";

#-------------------------------------------------------------------
# WebGUI is Copyright 2001-2002 Plain Black Software.
#-------------------------------------------------------------------
# Please read the legal notices (docs/legal.txt) and the license
# (docs/license.txt) that came with this distribution before using
# this software.
#-------------------------------------------------------------------
# http://www.plainblack.com                     info@plainblack.com
#-------------------------------------------------------------------

use strict qw(vars subs);
use Tie::CPHash;
use Tie::IxHash;
use WebGUI::ErrorHandler;
use WebGUI::International;
use WebGUI::Operation;
use WebGUI::Privilege;
use WebGUI::Session;
use WebGUI::SQL;
use WebGUI::Style;
use WebGUI::Template;
use WebGUI::Template::Default;
use WebGUI::Utility;

#-------------------------------------------------------------------
sub _displayAdminBar {
	my ($widgetName, $key, %hash2, $miscSelect, $adminSelect, $clipboardSelect, $widget, @widgetArray, %hash, $output, $contentSelect);
	tie %hash, "Tie::IxHash";
	tie %hash2, "Tie::IxHash";
  #--content adder
	@widgetArray = @_;
	$hash{$session{page}{url}} = WebGUI::International::get(1);
	$hash{$session{page}{url}.'?op=addPage'} = WebGUI::International::get(2);
	$hash{$session{page}{url}.'?op=selectPackageToDeploy'} = WebGUI::International::get(376);
	foreach $widget (@widgetArray) {
		$widgetName = "WebGUI::Widget::".$widget."::widgetName";
		$hash2{$session{page}{url}.'?func=add&widget='.$widget} = &$widgetName;
	}
	%hash2 = sortHash(%hash2);
	%hash = (%hash, %hash2);
	$contentSelect = WebGUI::Form::selectList("contentSelect",\%hash,"","","","goContent()");
  #--clipboard paster
	%hash2 = ();
	$hash2{$session{page}{url}} = WebGUI::International::get(3);
	%hash = WebGUI::SQL->buildHash("select pageId,title from page where parentId=2 order by title");
	foreach $key (keys %hash) {
		$hash2{$session{page}{url}.'?op=pastePage&pageId='.$key} = $hash{$key};
	}
        %hash = WebGUI::SQL->buildHash("select widgetId,title from widget where pageId=2 order by title");
        foreach $key (keys %hash) {
                $hash2{$session{page}{url}.'?func=paste&wid='.$key} = $hash{$key};
        }
        $clipboardSelect = WebGUI::Form::selectList("clipboardSelect",\%hash2,"","","","goClipboard()");
   #--admin functions
	%hash = ();
	if (WebGUI::Privilege::isInGroup(3,$session{user}{userId})) {
        	%hash = ( 
			$session{page}{url}.'?op=listGroups'=>WebGUI::International::get(5), 
			$session{page}{url}.'?op=manageSettings'=>WebGUI::International::get(4), 
			$session{page}{url}.'?op=listUsers'=>WebGUI::International::get(7),
			$session{env}{SCRIPT_NAME}.'/page_not_found'=>WebGUI::International::get(8),
			$session{env}{SCRIPT_NAME}.'/trash'=>WebGUI::International::get(10),
			$session{page}{url}.'?op=purgeTrash'=>WebGUI::International::get(11),
			$session{page}{url}.'?op=viewStatistics'=>WebGUI::International::get(144)
		);
	}
	if (WebGUI::Privilege::isInGroup(4,$session{user}{userId})) {
        	%hash = ( 
			$session{env}{SCRIPT_NAME}.'/clipboard'=>WebGUI::International::get(9),
			%hash
		);
	}
        if (WebGUI::Privilege::isInGroup(5,$session{user}{userId})) {
                %hash = (
			$session{page}{url}.'?op=listStyles'=>WebGUI::International::get(6), 
			%hash
                );
        }
        if (WebGUI::Privilege::isInGroup(6,$session{user}{userId})) {
                %hash = (
			$session{env}{SCRIPT_NAME}.'/packages'=>WebGUI::International::get(374),
                        %hash
                );
        }
        %hash = (  
		$session{page}{url}.'?op=viewHelpIndex'=>WebGUI::International::get(13),
		%hash
	);
	%hash = sortHash(%hash);
        %hash = ( 
		$session{page}{url}.'?'=>WebGUI::International::get(82), 
		$session{page}{url}.'?op=switchOffAdmin'=>WebGUI::International::get(12),
		%hash
	);
        $adminSelect = WebGUI::Form::selectList("adminSelect",\%hash,"","","","goAdmin()");
  #--output admin bar
	$output = '
	<div class="adminBar"><table class="adminBar" width="100%" cellpadding="3" cellspacing="0" border="0"><tr>
	<script language="JavaScript" type="text/javascript">	<!--
	function goContent(){
		location = document.content.contentSelect.options[document.content.contentSelect.selectedIndex].value
	}
        function goAdmin(){
                location = document.admin.adminSelect.options[document.admin.adminSelect.selectedIndex].value
        }
        function goClipboard(){
                location = document.clipboard.clipboardSelect.options[document.clipboard.clipboardSelect.selectedIndex].value
        }
	//-->	</script>
	<form name="content"> <td>'.$contentSelect.'</td> </form>
	<form name="clipboard"> <td align="center">'.$clipboardSelect.'</td> </form>
        <form name="admin"> <td align="center">'.$adminSelect.'</td> </form> 
	</tr></table></div>
	';
	return $output;
}

#-------------------------------------------------------------------
sub _loadWidgets {
	my ($widgetDir, @files, $file, $use, @widget, $i);
        if ($^O =~ /Win/i) {
                $widgetDir = "\\lib\\WebGUI\\Widget";
        } else {
                $widgetDir = "/lib/WebGUI/Widget";
        }
	opendir (DIR,$session{config}{webguiRoot}.$widgetDir) or WebGUI::ErrorHandler::fatalError("Can't open widget directory!");
	@files = readdir(DIR);
	foreach $file (@files) {
        	if ($file =~ /(.*?)\.pm$/) {
			$widget[$i] = $1;
                        $use = "use WebGUI::Widget::".$widget[$i];
                        eval($use);
			$i++;
		}
	}
	closedir(DIR);
	return @widget;
}

#-------------------------------------------------------------------
sub page {
	my (%contentHash, $cmd, $pageEdit, $widgetType, $functionOutput, @availableWidgets, @widgetList, $sth, $httpHeader, $header, $footer, $content, $operationOutput, $adminBar);
	WebGUI::Session::open($_[0]);
	# For some reason we have to pre-cache the templates when running under mod_perl
	# so that's what we're doing with this next command.
	WebGUI::Template::loadTemplates();
	@availableWidgets = _loadWidgets();
	if (exists $session{form}{op}) {
		$cmd = "WebGUI::Operation::www_".$session{form}{op};
		$operationOutput = &$cmd();
	}
	if (exists $session{form}{func}) {
		if (exists $session{form}{widget}) {
			$widgetType = $session{form}{widget};
		} else {
			($widgetType) = WebGUI::SQL->quickArray("select widgetType from widget where widgetId='$session{form}{wid}'");
		}
       		$cmd = "WebGUI::Widget::".$widgetType."::www_".$session{form}{func};
               	$functionOutput = &$cmd();
	}
	if ($operationOutput ne "") {
		$contentHash{A} = $operationOutput;
		$content = WebGUI::Template::Default::generate(\%contentHash);
	} elsif ($functionOutput ne "") {
		$contentHash{A} = $functionOutput;
		$content = WebGUI::Template::Default::generate(\%contentHash);
	} else {
		if (WebGUI::Privilege::canViewPage()) {
			if ($session{var}{adminOn}) {
                        	$pageEdit = '<br><img src="'.$session{setting}{lib}.'/page.gif" border=0 alt="Page Settings:"><a href="'.$session{page}{url}.'?op=editPage"><img src="'.$session{setting}{lib}.'/edit.gif" border=0 alt="Edit Page"></a><a href="'.$session{page}{url}.'?op=cutPage"><img src="'.$session{setting}{lib}.'/cut.gif" border=0 alt="Cut Page"></a><a href="'.$session{page}{url}.'?op=deletePage"><img src="'.$session{setting}{lib}.'/delete.gif" border=0 alt="Delete Page"></a><a href="'.$session{page}{url}.'?op=movePageUp"><img src="'.$session{setting}{lib}.'/pageUp.gif" border=0 alt="Move Page Up"></a><a href="'.$session{page}{url}.'?op=movePageDown"><img src="'.$session{setting}{lib}.'/pageDown.gif" border=0 alt="Move Page Down"></a></span>';
                	}	
			$sth = WebGUI::SQL->read("select widgetId, widgetType, templatePosition from widget where pageId=".$session{page}{pageId}." order by sequenceNumber, widgetId");
			while (@widgetList = $sth->array) {
				if ($session{var}{adminOn}) {
                       			$contentHash{$widgetList[2]} .= '<hr><a href="'.$session{page}{url}.'?func=edit&wid='.$widgetList[0].'"><img src="'.$session{setting}{lib}.'/edit.gif" border=0 alt="Edit"></a><a href="'.$session{page}{url}.'?func=cut&wid='.$widgetList[0].'"><img src="'.$session{setting}{lib}.'/cut.gif" border=0 alt="Cut"></a><a href="'.$session{page}{url}.'?func=copy&wid='.$widgetList[0].'"><img src="'.$session{setting}{lib}.'/copy.gif" border=0 alt="Copy"></a><a href="'.$session{page}{url}.'?wid='.$widgetList[0].'&func=delete"><img src="'.$session{setting}{lib}.'/delete.gif" border=0 alt="Delete"></a><a href="'.$session{page}{url}.'?func=moveUp&wid='.$widgetList[0].'"><img src="'.$session{setting}{lib}.'/upArrow.gif" border=0 alt="Move Up"></a><a href="'.$session{page}{url}.'?func=moveDown&wid='.$widgetList[0].'"><img src="'.$session{setting}{lib}.'/downArrow.gif" border=0 alt="Move Down"></a><a href="'.$session{page}{url}.'?func=jumpUp&wid='.$widgetList[0].'"><img src="'.$session{setting}{lib}.'/jumpUp.gif" border=0 alt="Move to Top"></a><a href="'.$session{page}{url}.'?func=jumpDown&wid='.$widgetList[0].'"><img src="'.$session{setting}{lib}.'/jumpDown.gif" border=0 alt="Move to Bottom"></a><br>';
				}
				$cmd = "WebGUI::Widget::".$widgetList[1]."::www_view";
				$contentHash{$widgetList[2]} .= &$cmd($widgetList[0])."<p>";
			}
			$sth->finish;
			$cmd = "use WebGUI::Template::".$session{page}{template};
			eval($cmd);
			$cmd = "WebGUI::Template::".$session{page}{template}."::generate";
			$content = &$cmd(\%contentHash);
		} else {
			$contentHash{A} = WebGUI::Privilege::noAccess();
			$content = WebGUI::Template::Default::generate(\%contentHash);
		}
	}
	if ($session{var}{adminOn}) {
		$adminBar = _displayAdminBar(@availableWidgets);
	}
	$httpHeader = WebGUI::Session::httpHeader();
	($header, $footer) = WebGUI::Style::getStyle();
	WebGUI::Session::close();
	return $httpHeader.$adminBar.$header.$pageEdit.$content.$footer;
}




1;


