package WebGUI::Wobject::FileManager;

#-------------------------------------------------------------------
# WebGUI is Copyright 2001-2002 Plain Black LLC.
#-------------------------------------------------------------------
# Please read the legal notices (docs/legal.txt) and the license
# (docs/license.txt) that came with this distribution before using
# this software.
#-------------------------------------------------------------------
# http://www.plainblack.com                     info@plainblack.com
#-------------------------------------------------------------------

use strict;
use Tie::CPHash;
use WebGUI::DateTime;
use WebGUI::HTMLForm;
use WebGUI::Icon;
use WebGUI::International;
use WebGUI::Paginator;
use WebGUI::Privilege;
use WebGUI::Search;
use WebGUI::Session;
use WebGUI::SQL;
use WebGUI::URL;
use WebGUI::Utility;
use WebGUI::Wobject;

our @ISA = qw(WebGUI::Wobject);
our $namespace = "FileManager";
our $name = WebGUI::International::get(1,$namespace);

#-------------------------------------------------------------------
sub _sortByColumn {
        if ($session{scratch}{$namespace.".".$_[0]->get("wobjectId").".sortDirection"} eq "asc") {
                return WebGUI::URL::append($_[2],'sort='.$_[1]."&sortDirection=desc");
        } else {
                return WebGUI::URL::append($_[2],'sort='.$_[1]."&sortDirection=asc");
        }
}


#-------------------------------------------------------------------
sub duplicate {
        my ($file, $w, %row, $sth, $newDownloadId);
	tie %row, 'Tie::CPHash';
        $w = $_[0]->SUPER::duplicate($_[1]);
        $w = WebGUI::Wobject::FileManager->new({wobjectId=>$w,namespace=>$namespace});
        $w->set({
		paginateAfter=>$_[0]->get("paginateAfter"),
		templateId=>$_[0]->get("templateId")
		});
        $sth = WebGUI::SQL->read("select * from FileManager_file where wobjectId=".$_[0]->get("wobjectId"));
        while (%row = $sth->hash) {
                $newDownloadId = getNextId("FileManager_fileId");
		$file = WebGUI::Attachment->new($row{downloadFile},$_[0]->get("wobjectId"),$row{FileManager_fileId});
		$file->copy($w->get("wobjectId"),$newDownloadId);
                $file = WebGUI::Attachment->new($row{alternateVersion1},$_[0]->get("wobjectId"),$row{FileManager_fileId});
                $file->copy($w->get("wobjectId"),$newDownloadId);
                $file = WebGUI::Attachment->new($row{alternateVersion2},$_[0]->get("wobjectId"),$row{FileManager_fileId});
                $file->copy($w->get("wobjectId"),$newDownloadId);
                WebGUI::SQL->write("insert into FileManager_file values ($newDownloadId, ".$w->get("wobjectId").", ".
			quote($row{fileTitle}).", ".quote($row{downloadFile}).", $row{groupToView}, ".
			quote($row{briefSynopsis}).", $row{dateUploaded}, $row{sequenceNumber}, ".
			quote($row{alternateVersion1}).", ".quote($row{alternateVersion2}).")");
        }
	$sth->finish;
}

#-------------------------------------------------------------------
sub purge {
	WebGUI::SQL->write("delete from FileManager_file where wobjectId=".$_[0]->get("wobjectId"));
	$_[0]->SUPER::purge();
}

#-------------------------------------------------------------------
sub set {
        $_[0]->SUPER::set($_[1],[qw(paginateAfter templateId)]);
}

#-------------------------------------------------------------------
sub uiLevel {
        return 4;
}

#-------------------------------------------------------------------
sub www_deleteFile {
	return WebGUI::Privilege::insufficient() unless (WebGUI::Privilege::canEditPage());
	$_[0]->setCollateral("FileManager_file","FileManager_fileId",
		{$session{form}{file}=>'',FileManager_fileId=>$session{form}{did}},0,0);
       	return $_[0]->www_editDownload();
}

#-------------------------------------------------------------------
sub www_deleteDownload {
	return WebGUI::Privilege::insufficient() unless (WebGUI::Privilege::canEditPage());
	return $_[0]->confirm(WebGUI::International::get(12,$namespace),
		WebGUI::URL::page('func=deleteDownloadConfirm&wid='.$session{form}{wid}.'&did='.$session{form}{did}));
}

#-------------------------------------------------------------------
sub www_deleteDownloadConfirm {
	return WebGUI::Privilege::insufficient() unless (WebGUI::Privilege::canEditPage());
        my ($output, $file);
        $file = WebGUI::Attachment->new("",$session{form}{wid},$session{form}{did});
        $file->deleteNode;
	$_[0]->deleteCollateral("FileManager_file","FileManager_fileId",$session{form}{did});
        $_[0]->reorderCollateral("FileManager_file","FileManager_fileId");
        return "";
}

#-------------------------------------------------------------------
sub www_download {
	my (%download, $file);
	tie %download,'Tie::CPHash';
	%download = WebGUI::SQL->quickHash("select * from FileManager_file where FileManager_fileId=$session{form}{did}");
	if (WebGUI::Privilege::isInGroup($download{groupToView})) {
		if ($session{form}{alternateVersion} == 1) {
                        $file = WebGUI::Attachment->new($download{alternateVersion1},
                                $session{form}{wid},
                                $session{form}{did});
		} elsif ($session{form}{alternateVersion} == 2) {
                        $file = WebGUI::Attachment->new($download{alternateVersion2},
                                $session{form}{wid},
                                $session{form}{did});
		} else {
			$file = WebGUI::Attachment->new($download{downloadFile},
				$session{form}{wid},
				$session{form}{did});
		}
		$session{header}{redirect} = WebGUI::Session::httpRedirect($file->getURL);
		return "";
	} else {
		return WebGUI::Privilege::insufficient();
	}
}

#-------------------------------------------------------------------
sub www_edit {
	return WebGUI::Privilege::insufficient() unless (WebGUI::Privilege::canEditPage());
        my ($output, $f, $paginateAfter, $proceed);
        if ($_[0]->get("wobjectId") eq "new") {
                $proceed = 1;
        }
        $output .= helpIcon(1,$namespace);
        $output .= '<h1>'.WebGUI::International::get(9,$namespace).'</h1>';
	$paginateAfter = $_[0]->get("paginateAfter") || 50;
	$f = WebGUI::HTMLForm->new;
	$f->template(
                -name=>"templateId",
                -value=>$_[0]->get("templateId"),
                -namespace=>$namespace,
                -afterEdit=>'func=edit&wid='.$_[0]->get("wobjectId")
                );
	$f->integer("paginateAfter",WebGUI::International::get(20,$namespace),$paginateAfter);
	if ($_[0]->get("wobjectId") eq "new") {
                $f->whatNext(
                        -options=>{
                                addFile=>WebGUI::International::get(74,$namespace),
                                backToPage=>WebGUI::International::get(745)
                                },
                        -value=>"addFile"
                        );
        }
	$output .= $_[0]->SUPER::www_edit($f->printRowsOnly);
        return $output;
}

#-------------------------------------------------------------------
sub www_editSave {
	return WebGUI::Privilege::insufficient() unless (WebGUI::Privilege::canEditPage());
	$_[0]->SUPER::www_editSave({
		paginateAfter=>$session{form}{paginateAfter},
		templateId=>$session{form}{templateId}
		});
        if ($session{form}{proceed} eq "addFile") {
		$session{form}{did} = "new";
                return $_[0]->www_editDownload();
        } else {
                return "";
        }
}

#-------------------------------------------------------------------
sub www_editDownload {
	return WebGUI::Privilege::insufficient() unless (WebGUI::Privilege::canEditPage());
        my ($output, $file, $f);
	$file = $_[0]->getCollateral("FileManager_file","FileManager_fileId",$session{form}{did});
        $output .= helpIcon(2,$namespace);
        $output .= '<h1>'.WebGUI::International::get(10,$namespace).'</h1>';
	$f = WebGUI::HTMLForm->new;
        $f->hidden("wid",$_[0]->get("wobjectId"));
        $f->hidden("did",$file->{FileManager_fileId});
        $f->hidden("func","editDownloadSave");
	$f->text("fileTitle",WebGUI::International::get(5,$namespace),$file->{fileTitle});
	if ($file->{downloadFile} ne "") {
		$f->readOnly('<a href="'.WebGUI::URL::page('func=deleteFile&file=downloadFile&wid='.
			$_[0]->get("wobjectId").'&did='.$file->{FileManager_fileId}).'">'.WebGUI::International::get(391).
			'</a>',WebGUI::International::get(6,$namespace));
        } else {
		$f->file("downloadFile",WebGUI::International::get(6,$namespace));
        }
        if ($file->{alternateVersion1} ne "") {
		$f->readOnly('<a href="'.WebGUI::URL::page('func=deleteFile&file=alternateVersion1&wid='.
			$_[0]->get("wobjectId").'&did='.$file->{FileManager_fileId}).'">'.
			WebGUI::International::get(391).'</a>',WebGUI::International::get(17,$namespace));
        } else {
		$f->file("alternateVersion1",WebGUI::International::get(17,$namespace));
        }
        if ($file->{alternateVersion2} ne "") {
		$f->readOnly('<a href="'.WebGUI::URL::page('func=deleteFile&file=alternateVersion1&wid='.
			$_[0]->get("wobjectId").'&did='.$file->{FileManager_fileId}).'">'.
			WebGUI::International::get(391).'</a>',WebGUI::International::get(18,$namespace));
        } else {
		$f->file("alternateVersion2",WebGUI::International::get(18,$namespace));
        }
        $f->text("briefSynopsis",WebGUI::International::get(8,$namespace),$file->{briefSynopsis});
        $f->group("groupToView",WebGUI::International::get(7,$namespace),[$file->{groupToView}]);
	if ($file->{FileManager_fileId} eq "new") {
                $f->whatNext(
                        -options=>{
                                addFile=>WebGUI::International::get(74,$namespace),
                                backToPage=>WebGUI::International::get(745)
                                },
                        -value=>"backToPage"
                        );
        }
	$f->submit;
	$output .= $f->print;
        return $output;
}

#-------------------------------------------------------------------
sub www_editDownloadSave {
	return WebGUI::Privilege::insufficient() unless (WebGUI::Privilege::canEditPage());
        my ($file, %files);
	$files{FileManager_fileId} = $_[0]->setCollateral("FileManager_file", "FileManager_fileId", {
        	FileManager_fileId => $session{form}{did},
                fileTitle => $session{form}{fileTitle},
                briefSynopsis => $session{form}{briefSynopsis},
                dateUploaded => time(),
                groupToView => $session{form}{groupToView}
                });
	$_[0]->reorderCollateral("FileManager_file","FileManager_fileId");
        $file = WebGUI::Attachment->new("",$_[0]->get("wobjectId"),$files{FileManager_fileId});
	$file->save("downloadFile");
	if ($file->getFilename ne "") {
		$files{downloadFile} = $file->getFilename;
		$files{fileTitle} = $files{downloadFile} if ($session{form}{fileTitle} eq "");
	}
        $file = WebGUI::Attachment->new("",$_[0]->get("wobjectId"),$files{FileManager_fileId});
	$file->save("alternateVersion1");
	if ($file->getFilename ne "") {
		$files{alternateVersion1} = $file->getFilename;
	}
	$file = WebGUI::Attachment->new("",$_[0]->get("wobjectId"),$files{FileManager_fileId});
	$file->save("alternateVersion2");
	if ($file->getFilename ne "") {
		$files{alternateVersion2} = $file->getFilename;
	}
	$_[0]->setCollateral("FileManager_file", "FileManager_fileId", \%files);
        if ($session{form}{proceed} eq "addFile") {
        	$session{form}{did} = "new";
        	return $_[0]->www_editDownload();
        } else {
                return "";
        }
}

#-------------------------------------------------------------------
sub www_moveDownloadDown {
	return WebGUI::Privilege::insufficient() unless (WebGUI::Privilege::canEditPage());
	$_[0]->moveCollateralDown("FileManager_file","FileManager_fileId",$session{form}{did});
	return "";
}

#-------------------------------------------------------------------
sub www_moveDownloadUp {
	return WebGUI::Privilege::insufficient() unless (WebGUI::Privilege::canEditPage());
	$_[0]->moveCollateralUp("FileManager_file","FileManager_fileId",$session{form}{did});
	return "";
}

#-------------------------------------------------------------------
sub www_view {
        my ($sortDirection, %var, @fileloop, $files, $sort, $file, $p, $file1, $file2, $file3, $constraints, 
		$url, $numResults, $sql, $flag);
	$url = WebGUI::URL::page("func=view&wid=".$_[0]->get("wobjectId"));
	WebGUI::Session::setScratch($namespace.".".$_[0]->get("wobjectId").".sortDirection",$session{form}{sortDirection});
	WebGUI::Session::setScratch($namespace.".".$_[0]->get("wobjectId").".sort",$session{form}{sort});
	$numResults = $_[0]->get("paginateAfter") || 25;
	$var{"titleColumn.label"} = WebGUI::International::get(14,$namespace);
	$var{"titleColumn.url"} = $_[0]->_sortByColumn("fileTitle",$url);
        $var{"descriptionColumn.label"} = WebGUI::International::get(15,$namespace);
        $var{"descriptionColumn.url"} = $_[0]->_sortByColumn("briefSynopsis",$url);
        $var{"dateColumn.label"} = WebGUI::International::get(16,$namespace);
        $var{"dateColumn.url"} = $_[0]->_sortByColumn("dateUploaded",$url);
	$session{form}{sort} = "sequenceNumber" if ($session{form}{sort} eq "");
	$var{"search.form"} = WebGUI::Search::form();
	$var{"search.url"} = WebGUI::Search::toggleURL();
	$var{"search.label"} = WebGUI::International::get(364);
        $var{"addfile.url"} = WebGUI::URL::page('func=editDownload&did=new&wid='.$_[0]->get("wobjectId"));
        $var{"addfile.label"} = WebGUI::International::get(11,$namespace);
	$sql = "select * from FileManager_file where wobjectId=".$_[0]->get("wobjectId")." ";
	if ($session{scratch}{search}) {
		$numResults = $session{scratch}{numResults};
		$constraints = WebGUI::Search::buildConstraints(
			[qw(fileTitle downloadFile alternateVersion1 alternateVersion2 briefSynopsis)]);
		$sql .= " and ".$constraints if ($constraints ne "");
	}
	$sort = $session{scratch}{$namespace.".".$_[0]->get("wobjectId").".sort"} || "dateUploaded";
	$sortDirection = $session{scratch}{$namespace.".".$_[0]->get("wobjectId").".sortDirection"} || "desc";
	$sql .= " order by $sort $sortDirection";
	$p = WebGUI::Paginator->new($url,[],$numResults);
	$p->setDataByQuery($sql);
	$files = $p->getPageData;
	foreach $file (@$files) {
		$file1 = WebGUI::Attachment->new($file->{downloadFile},$_[0]->get("wobjectId"),$file->{FileManager_fileId});
		$file2 = WebGUI::Attachment->new($file->{alternateVersion1},$_[0]->get("wobjectId"),$file->{FileManager_fileId});
		$file3 = WebGUI::Attachment->new($file->{alternateVersion2},$_[0]->get("wobjectId"),$file->{FileManager_fileId});
		push (@fileloop,{
			"file.canView"=>WebGUI::Privilege::isInGroup($file->{groupToView}),
			"file.controls"=>deleteIcon('func=deleteDownload&wid='.$_[0]->get("wobjectId")
				.'&did='.$file->{FileManager_fileId}).editIcon('func=editDownload&wid='.$_[0]->get("wobjectId")
				.'&did='.$file->{FileManager_fileId}).moveUpIcon('func=moveDownloadUp&wid='
				.$_[0]->get("wobjectId")
				.'&did='.$file->{FileManager_fileId}).moveDownIcon('func=moveDownloadDown&wid='
				.$_[0]->get("wobjectId").'&did='.$file->{FileManager_fileId}),
			"file.title"=>$file->{fileTitle},
			"file.version1.name"=>$file1->getFilename,
			"file.version1.url"=>$file1->getURL,
			"file.version1.icon"=>$file1->getIcon,
			"file.version1.size"=>$file1->getSize,
			"file.version1.type"=>$file1->getType,
			"file.version1.thumbnail"=>$file1->getThumbnail,
			"file.version1.isImage"=>$file1->isImage,
                        "file.version2.name"=>$file2->getFilename,
                        "file.version2.url"=>$file2->getURL,
                        "file.version2.icon"=>$file2->getIcon,
                        "file.version2.size"=>$file2->getSize,
                        "file.version2.type"=>$file2->getType,
                        "file.version2.thumbnail"=>$file2->getThumbnail,
                        "file.version2.isImage"=>$file2->isImage,
                        "file.version3.name"=>$file3->getFilename,
                        "file.version3.url"=>$file3->getURL,
                        "file.version3.icon"=>$file3->getIcon,
                        "file.version3.size"=>$file3->getSize,
                        "file.version3.type"=>$file3->getType,
                        "file.version3.thumbnail"=>$file3->getThumbnail,
                        "file.version3.isImage"=>$file3->isImage,
			"file.description"=>$file->{briefSynopsis},
			"file.date"=>epochToHuman($file->{dateUploaded},"%z"),
			"file.time"=>epochToHuman($file->{dateUploaded},"%Z")
			});
		$flag = 1;
	}
	$var{"noresults.message"} = WebGUI::International::get(19,$namespace);
	$var{noresults} = !$flag;
        $var{file_loop} = \@fileloop;
        $var{firstPage} = $p->getFirstPageLink;
        $var{lastPage} = $p->getLastPageLink;
        $var{nextPage} = $p->getNextPageLink;
        $var{pageList} = $p->getPageLinks;
        $var{previousPage} = $p->getPreviousPageLink;
        $var{multiplePages} = ($p->getNumberOfPages > 1);
        return $_[0]->processMacros($_[0]->processTemplate($_[0]->get("templateId"),\%var));
}


1;


