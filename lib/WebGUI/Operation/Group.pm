package WebGUI::Operation::Group;

#-------------------------------------------------------------------
# WebGUI is Copyright 2001-2002 Plain Black Software.
#-------------------------------------------------------------------
# Please read the legal notices (docs/legal.txt) and the license
# (docs/license.txt) that came with this distribution before using
# this software.
#-------------------------------------------------------------------
# http://www.plainblack.com                     info@plainblack.com
#-------------------------------------------------------------------

use Exporter;
use strict;
use Tie::CPHash;
use WebGUI::DateTime;
use WebGUI::Form;
use WebGUI::International;
use WebGUI::Privilege;
use WebGUI::Session;
use WebGUI::Shortcut;
use WebGUI::SQL;
use WebGUI::Utility;

our @ISA = qw(Exporter);
our @EXPORT = qw(&www_addGroup &www_addGroupSave &www_deleteGroup &www_deleteGroupConfirm &www_editGroup &www_editGroupSave &www_listGroups);

#-------------------------------------------------------------------
sub www_addGroup {
        my ($output);
        if (WebGUI::Privilege::isInGroup(3)) {
                $output .= helpLink(17);
		$output .= '<h1>'.WebGUI::International::get(83).'</h1>';
		$output .= formHeader();
                $output .= WebGUI::Form::hidden("op","addGroupSave");
                $output .= '<table>';
                $output .= tableFormRow(WebGUI::International::get(84),WebGUI::Form::text("groupName",20,30));
                $output .= tableFormRow(WebGUI::International::get(85),WebGUI::Form::textArea("description",''));
                $output .= tableFormRow(WebGUI::International::get(367),WebGUI::Form::text("expireAfter",20,30,314496000));
                $output .= formSave();
                $output .= '</table>';
                $output .= '</form> ';
        } else {
                $output = WebGUI::Privilege::adminOnly();
        }
        return $output;
}

#-------------------------------------------------------------------
sub www_addGroupSave {
        my ($output);
        if ($session{var}{sessionId}) {
                WebGUI::SQL->write("insert into groups values (".getNextId("groupId").", ".quote($session{form}{groupName}).", ".quote($session{form}{description}).", '$session{form}{expireAfter}')");
                $output = www_listGroups();
        } else {
                $output = WebGUI::Privilege::adminOnly();
        }
        return $output;
}

#-------------------------------------------------------------------
sub www_deleteGroup {
        my ($output);
        if ($session{form}{gid} < 26) {
                return WebGUI::Privilege::vitalComponent();
        } elsif (WebGUI::Privilege::isInGroup(3)) {
                $output .= helpLink(15);
		$output .= '<h1>'.WebGUI::International::get(42).'</h1>';
                $output .= WebGUI::International::get(86).'<p>';
                $output .= '<div align="center"><a href="'.$session{page}{url}.'?op=deleteGroupConfirm&gid='.$session{form}{gid}.'">'.WebGUI::International::get(44).'</a>';
                $output .= '&nbsp;&nbsp;&nbsp;&nbsp;<a href="'.$session{page}{url}.'?op=listGroups">'.WebGUI::International::get(45).'</a></div>';
                return $output;
        } else {
                return WebGUI::Privilege::adminOnly();
        }
}

#-------------------------------------------------------------------
sub www_deleteGroupConfirm {
        if ($session{form}{gid} < 26) {
                return WebGUI::Privilege::vitalComponent();
        } elsif (WebGUI::Privilege::isInGroup(3)) {
                WebGUI::SQL->write("delete from groups where groupId=$session{form}{gid}");
                WebGUI::SQL->write("delete from groupings where groupId=$session{form}{gid}");
                return www_listGroups();
        } else {
                return WebGUI::Privilege::adminOnly();
        }
}

#-------------------------------------------------------------------
sub www_editGroup {
        my ($output, $sth, %group, %hash);
	tie %group, 'Tie::CPHash';
	tie %hash, 'Tie::CPHash';
        if (WebGUI::Privilege::isInGroup(3)) {
                %group = WebGUI::SQL->quickHash("select * from groups where groupId=$session{form}{gid}");
                $output .= helpLink(17);
		$output .= '<h1>'.WebGUI::International::get(87).'</h1>';
		$output .= formHeader();
                $output .= WebGUI::Form::hidden("op","editGroupSave");
                $output .= WebGUI::Form::hidden("gid",$session{form}{gid});
                $output .= '<table>';
		$output .= tableFormRow(WebGUI::International::get(379),$session{form}{gid});
                $output .= tableFormRow(WebGUI::International::get(84),WebGUI::Form::text("groupName",20,30,$group{groupName}));
                $output .= tableFormRow(WebGUI::International::get(85),WebGUI::Form::textArea("description",$group{description}));
                $output .= tableFormRow(WebGUI::International::get(367),WebGUI::Form::text("expireAfter",20,30,$group{expireAfter}));
                $output .= formSave();
                $output .= '</table>';
                $output .= '</form> ';
		$output .= '<h1>'.WebGUI::International::get(88).'</h1>';
                $output .= '<table><tr><td class="tableHeader">&nbsp;</td><td class="tableHeader">'.WebGUI::International::get(50).'</td><td class="tableHeader">'.WebGUI::International::get(369).'</td></tr>';
                $sth = WebGUI::SQL->read("select users.username,users.userId,groupings.expireDate from groupings,users where groupings.groupId=$session{form}{gid} and groupings.userId=users.userId order by users.username");
                while (%hash = $sth->hash) {
                        $output .= '<tr><td><a href="'.$session{page}{url}.'?op=deleteGrouping&uid='.$hash{userId}.'&gid='.$session{form}{gid}.'"><img src="'.$session{setting}{lib}.'/delete.gif" border=0></a><a href="'.$session{page}{url}.'?op=editGrouping&uid='.$hash{userId}.'&gid='.$session{form}{gid}.'"><img src="'.$session{setting}{lib}.'/edit.gif" border=0></a></td>';
                        $output .= '<td class="tableData"><a href="'.$session{page}{url}.'/op=editUser&uid='.$hash{userId}.'">'.$hash{username}.'</a></td>';
                        $output .= '<td class="tableData">'.epochToHuman($hash{expireDate},"%M/%D/%y").'</td></tr>';
                }
                $sth->finish;
                $output .= '</table>';
        } else {
                $output = WebGUI::Privilege::adminOnly();
        }
        return $output;
}

#-------------------------------------------------------------------
sub www_editGroupSave {
        if (WebGUI::Privilege::isInGroup(3)) {
                WebGUI::SQL->write("update groups set groupName=".quote($session{form}{groupName}).", description=".quote($session{form}{description}).", expireAfter='$session{form}{expireAfter}' where groupId=".$session{form}{gid});
                return www_listGroups();
        } else {
                return WebGUI::Privilege::adminOnly();
        }
}

#-------------------------------------------------------------------
sub www_listGroups {
        my ($output, $dataRows, $prevNextBar, $sth, @data, @row, $i);
        if (WebGUI::Privilege::isInGroup(3)) {
                $output = helpLink(10);
		$output .= '<h1>'.WebGUI::International::get(89).'</h1>';
		$output .= '<div align="center"><a href="'.$session{page}{url}.'?op=addGroup">'.WebGUI::International::get(90).'</a></div>';
                $output .= '<table border=1 cellpadding=5 cellspacing=0 align="center">';
                $sth = WebGUI::SQL->read("select groupId,groupName,description from groups where groupName<>'Reserved' order by groupName");
                while (@data = $sth->array) {
                        $row[$i] = '<tr><td valign="top" class="tableData"><a href="'.$session{page}{url}.'?op=deleteGroup&gid='.$data[0].'"><img src="'.$session{setting}{lib}.'/delete.gif" border=0></a><a href="'.$session{page}{url}.'?op=editGroup&gid='.$data[0].'"><img src="'.$session{setting}{lib}.'/edit.gif" border=0></a></td>';
                        $row[$i] .= '<td valign="top" class="tableData">'.$data[1].'</td>';
                        $row[$i] .= '<td valign="top" class="tableData">'.$data[2].'</td></tr>';
                        $i++;
                }
		$sth->finish;
                ($dataRows, $prevNextBar) = paginate(50,$session{page}{url}.'?op=listGroups',\@row);
                $output .= '<table border=1 cellpadding=5 cellspacing=0 align="center">';
                $output .= $dataRows;
                $output .= '</table>';
                $output .= $prevNextBar;
                return $output;
        } else {
                return WebGUI::Privilege::adminOnly();
        }
}


1;
