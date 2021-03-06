package WebGUI::Operation::User;

#-------------------------------------------------------------------
# WebGUI is Copyright 2001-2012 Plain Black Corporation.
#-------------------------------------------------------------------
# Please read the legal notices (docs/legal.txt) and the license
# (docs/license.txt) that came with this distribution before using
# this software.
#-------------------------------------------------------------------
# http://www.plainblack.com                     info@plainblack.com
#-------------------------------------------------------------------

use strict qw(vars subs);
use Tie::IxHash;
use WebGUI::AdminConsole;
use WebGUI::Group;
use WebGUI::Form;
use WebGUI::Form::DynamicField;
use WebGUI::HTMLForm;
use WebGUI::International;
use WebGUI::Operation::Auth;
use WebGUI::Paginator;
use WebGUI::SQL;
use WebGUI::User;
use JSON;
use XML::Simple;
use Net::CIDR::Lite;

=head1 NAME

Package WebGUI::Operation::User

=head1 DESCRIPTION

Operation for creating, deleting, editing and many other user related functions.

=cut


#-------------------------------------------------------------------

=head2 _submenu ( session, properties )

Internal utility routine for setting up the Admin Console for User functions.

=head3 session

A reference to the current session.

=head3 properties

A hash reference containing all the properties to set in this submenu

workarea: content to render in admin console

userId: userId of user to be modified by submenu controls such as edit and delete

title: internationalization key from users for text to display as the admin consoles title

=cut

sub _submenu {
	my $session = shift;
	my $properties = shift;
	my $i18n = WebGUI::International->new($session);
	my $ac = WebGUI::AdminConsole->new($session,"users");
	my $userId = $properties->{userId} || $session->form->get("uid");
	my $workarea = $properties->{workarea};
	my $title;
	$title = $i18n->get($properties->{title}) if ($properties->{title});

	if (canEdit($session)) {
		$ac->addSubmenuItem($session->url->page("op=editUser;uid=new"), $i18n->get(169));
	}

    $ac->setFormUrl($session->url->page('op=editUser;uid='.$userId));
    my $formId = $ac->getSubmenuFormId;
	if (canEdit($session)) {
		unless ($session->form->process("op") eq "listUsers" 
			|| $session->form->process("op") eq "deleteUser"
			|| $userId eq "new") {
			$ac->addSubmenuItem($session->url->page("op=editUser;uid=$userId"), $i18n->get(457));
			$ac->addSubmenuItem($session->url->page('op=becomeUser;uid='.$userId), $i18n->get(751), qq|onclick="var thisForm=document.getElementById('$formId');thisForm.op.value='becomeUser';thisForm.submit(); return false;"|);
            my $user = WebGUI::User->new($session, $userId);
			$ac->addSubmenuItem($user->getProfileUrl(), $i18n->get('view profile'));
            my $confirm = $i18n->get(167);
            $confirm =~ s/([\\\'])/\\$1/g;
			$ac->addSubmenuItem($session->url->page('op=deleteUser;uid='.$userId), $i18n->get(750), qq|onclick="var ack = confirm('$confirm'); if (ack) { var thisForm=document.getElementById('$formId');thisForm.op.value='deleteUser';thisForm.submit();} return false;"|);
			if ($session->setting->get("useKarma")) {
				$ac->addSubmenuItem($session->url->page("op=editUserKarma;uid=$userId"), $i18n->get(555));
			}
		}
		$ac->addSubmenuItem($session->url->page("op=listUsers"), $i18n->get(456));
	}
        return $ac->render($workarea, $title);
}

#----------------------------------------------------------------------------

=head2 canAdd ( session [, user] )

Returns true if the user is allowed to add other users. user defaults to the
current user.

=cut

sub canAdd {
    my $session     = shift;
    my $user        = shift || $session->user;
    return $user->isInGroup( $session->setting->get("groupIdAdminUserAdd") )
        || canEdit($session, $user)
        ;
}

#----------------------------------------------------------------------------

=head2 canEdit ( session [, user] )

Returns true if the user is allowed to do everything in this module. user 
defaults to the current user.

=cut

sub canEdit {
    my $session     = shift;
    my $user        = shift || $session->user;
    return $user->isInGroup( $session->setting->get("groupIdAdminUser") );
}

#----------------------------------------------------------------------------

=head2 canUseService ( session )

Returns true if the current session is allowed to use the web service, i.e.
is in one of the configured CIDR subnets in the config file.

=cut

sub canUseService {
    my ( $session ) = @_;
    my $subnets = $session->config->get('serviceSubnets');
    return 1 if !$subnets || !@{$subnets};
    return 1 if Net::CIDR::Lite->new(@$subnets)->find($session->request->address);
    return 0; # Don't go away mad, just go away
}

#----------------------------------------------------------------------------

=head2 canView ( session [, user] )

Returns true if the user is allowed to see this module. user defaults to the
current user.

=cut

sub canView {
    my $session     = shift;
    my $user        = shift || $session->user;
    return canAdd($session, $user);
}

#-------------------------------------------------------------------

=head2 createServiceResponse ( format, data ) 

Create a string with the correct C<format> from the given C<data>.

Possible formats are "json" and "xml".

=cut

sub createServiceResponse {
    my ( $format, $data ) = @_;
    
    if ( lc $format eq "xml" ) {
        return XML::Simple::XMLout($data, NoAttr => 1, RootName => "response" );
    }
    else {
        return JSON->new->encode($data);
    }
}

#-------------------------------------------------------------------

=head2 doUserSearch ( session, op, returnPaginator, userFilter )

Subroutine that actually performs the SQL search for users.

=head3 session

A reference to the current session.

=head3 op

The name of the calling operation, passed so that pagination links work correctly.

=head3 returnPaginator

A boolean.  If true, a paginator object is returned.  Otherwise, a WebGUI::SQL
statement handler is returned.

=head3 userFilter

Array reference, used to screen out user names via a SQL "not in ()" clause.

=cut

sub doUserSearch {
	my $session = shift;
	my $op = shift;
	my $returnPaginator = shift;
	my $userFilter = shift;
	push(@{$userFilter},0);
	my $selectedStatus = '';
	if ($session->scratch->get("userSearchStatus")) {
		$selectedStatus = "status='".$session->scratch->get("userSearchStatus")."' and ";
	}
	my $keyword = $session->scratch->get("userSearchKeyword");
	if ($session->scratch->get("userSearchModifier") eq "startsWith") {
		$keyword .= "%";
	} elsif ($session->scratch->get("userSearchModifier") eq "contains") {
		$keyword = "%".$keyword."%";
	} else {
		$keyword = "%".$keyword;
	}
	my $sql = "select users.userId, users.username, users.status, users.dateCreated, users.lastUpdated,
                users.email from users 
                where $selectedStatus (users.username like ? or alias like ? or email like ? 
                    or firstName like ? or lastName like ? or CONCAT(firstName, ' ', lastName) LIKE ? ) 
                and users.userId not in (".$session->db->quoteAndJoin($userFilter).")  order by users.username";
	if ($returnPaginator) {
        	my $p = WebGUI::Paginator->new($session,$session->url->page("op=".$op));
		$p->setDataByQuery($sql, undef, undef, [$keyword, $keyword, $keyword, $keyword, $keyword, $keyword]);
		return $p;
	} else {
		my $sth = $session->dbSlave->read($sql, [$keyword, $keyword, $keyword, $keyword, $keyword, $keyword]);
		return $sth;
	}
}

#-------------------------------------------------------------------

=head2 getUserSearchForm ( session, op, params, noStatus )

Form front-end and display for searching for users.

=head3 session

A reference to the current session.

=head3 op

The name of the calling operation, passed so that pagination links work correctly.

=head3 params

Hashref.  A set of key,value pairs that will be hidden in the user search form.

=head3 noStatus

Don't display the status filter.

=cut

sub getUserSearchForm {
	my $session = shift;
	my $op = shift;
	my $params = shift;
	my $noStatus = shift;
	$session->scratch->set("userSearchKeyword",$session->form->process("keyword")) if defined($session->form->process("keyword"));
	$session->scratch->set("userSearchStatus",$session->form->process("status")) if defined($session->form->process("status"));
	$session->scratch->set("userSearchModifier",$session->form->process("modifier")) if defined($session->form->process("modifier"));
	my $i18n = WebGUI::International->new($session);
	my $output = '<div align="center">'
		.WebGUI::Form::formHeader($session,{ method => 'GET'}, )
		.WebGUI::Form::hidden($session,
			name => "op",
			value => $op
			);
	foreach my $key (keys %{$params}) {
		$output .= WebGUI::Form::hidden($session,
			name=>$key,
			value=>$params->{$key}
			);
	}
	$output .= WebGUI::Form::hidden($session,
		-name=>"doit",
		-value=>1
		)
	.WebGUI::Form::selectBox($session,
		-name=>"modifier",
		-value=>($session->scratch->get("userSearchModifier") || "contains"),
		-options=>{
			startsWith=>$i18n->get("starts with"),
			contains=>$i18n->get("contains"),
			endsWith=>$i18n->get("ends with")
			}
		)
	.WebGUI::Form::text($session,
		-name=>"keyword",
		-value=>$session->scratch->get("userSearchKeyword"),
		-size=>15
		);
	if ($noStatus) {	
		$output .= WebGUI::Form::hidden($session,
                        name => "status",
                        value => "Active"
                        );
	} else {
		$output .= WebGUI::Form::selectBox($session,
			-name	=> "status",
			-value	=> ($session->scratch->get("userSearchStatus") || "users.status like '%'"),
			-options=> { 
				""		=> $i18n->get(821),
				Active		=> $i18n->get(817),
				Deactivated	=> $i18n->get(818),
				Selfdestructed	=> $i18n->get(819)
				}
		);
	}
	$output .= WebGUI::Form::submit($session,value=>$i18n->get(170))
	.WebGUI::Form::formFooter($session,);
	$output .= '</div>';
	return $output;
}

#-------------------------------------------------------------------

=head2 www_ajaxCreateUser ( )

Create a user using a web service.

=cut

sub www_ajaxCreateUser {
    my ( $session ) = @_;

    ### Get desired output format first (for future error messages)
    my $outputFormat    = "json";
    my $mimeType        = "application/json";

    # Allow XML
    if ( lc $session->form->get('as') eq "xml" ) {
        $outputFormat   = "xml";
        $mimeType       = "application/xml";
    }

    $session->response->content_type( $mimeType ); 

    # Verify access
    if ( !canAdd($session) || !canUseService($session) ) {
        # We need an automatic way to send a request for an http basic auth
        $session->response->status(401);
        return createServiceResponse( $outputFormat, {
            error       => "WebGUI::Error::Unauthorized",
            message     => "",
        } );
    }

    ### Verify data
    # User data is <PROPERTY_NAME> in form
    my %userParam = (
        map { $_ => $session->form->get($_) }
        grep { !/^auth:/ && $_ ne "op" }
        ( $session->form->param )
    );

    # Auth data is auth:<AUTH_METHOD>:<PROPERTY_NAME> in form
    my %authParam    = ();
    for my $formParam ( grep { /^auth:[^:]+:.+$/ } $session->form->get ) {
        my ( $authMethod, $property ) = $formParam =~ /^auth:([^:]+):(.+)$/;
        $authParam{$authMethod}{$property} = $session->form->get($formParam);
    }

    # User must have a username
    if ( !$userParam{username} ) {
        return createServiceResponse( $outputFormat, {
            error       => "WebGUI::Error::InvalidParam",
            param       => "username",
            message     => "",
        } );
    }
    # User must not already exist
    if ( $session->db->quickScalar( "SELECT * FROM users WHERE username=?", [$userParam{username}] ) ) {
        return createServiceResponse( $outputFormat, {
            error       => "WebGUI::Error::InvalidParam",
            param       => "username",
            message     => "",
        } );
    }

    ### Create user
    my $user    = WebGUI::User->create( $session );
    $user->update( \%userParam );
    for my $authMethod ( keys %authParam ) {
        my $auth = WebGUI::Operation::Auth::getInstance($session,$authMethod,$user->getId);

        # XXX Special handling for WebGUI passwords. This should be removed when 
        # Auth is fixed in WebGUI 8
        if ( $authMethod eq 'WebGUI' && exists $authParam{$authMethod}{identifier} ) {
            $authParam{$authMethod}{identifier}
                = $auth->hashPassword( $authParam{$authMethod}{identifier} );
        }

        $auth->saveParams( $user->getId, $auth->authMethod, $authParam{$authMethod} );
    }

    ### Send new user's data
    return createServiceResponse( $outputFormat, {
        user        => $user->get,
    } );
}

#-------------------------------------------------------------------

=head2 www_confirmUserEmail ( )

Process links clicked from mails sent out by the WaitForUserConfmration
workflow activity.

=cut

sub www_confirmUserEmail {
    my $session    = shift;
    my $f          = $session->form;
    my $instanceId = $f->get('instanceId');
    my $token      = $f->get('token');
    my $actId      = $f->get('activityId');
    my $activity   = WebGUI::Workflow::Activity->new($session, $actId)
        or die;
    my $instance   = WebGUI::Workflow::Instance->new($session, $instanceId)
        or die;
    if ($activity->confirm($instance, $token)) {
        my $msg  = $activity->get('okMessage');
        unless ($msg) {
            my $i18n = WebGUI::International->new($session, 'WebGUI');
            $msg = $i18n->get('ok');
        }
        return $session->style->userStyle($msg);
    }
    else {
        return $session->privilege->noAccess;
    }
}

#-------------------------------------------------------------------

=head2 www_ajaxDeleteUser ( )

Delete a user using a web service.

=cut

sub www_ajaxDeleteUser {
    my ( $session ) = @_;
    
    ### Get desired output format first (for future error messages)
    my $outputFormat    = "json";
    my $mimeType        = "application/json";

    # Allow XML
    if ( lc $session->form->get('as') eq "xml" ) {
        $outputFormat   = "xml";
        $mimeType       = "application/xml";
    }

    $session->response->content_type( $mimeType ); 

    # Verify access
    if ( !canEdit($session) || !canUseService($session) ) {
        # We need an automatic way to send a request for an http basic auth
        $session->response->status(401);
        return createServiceResponse( $outputFormat, {
            error       => "WebGUI::Error::Unauthorized",
            message     => "",
        } );
    }

    # Verify data
    my $userId  = $session->form->get('userId');
    if ( !$userId ) {
        return createServiceResponse( $outputFormat, {
            error       => "WebGUI::Error::InvalidParam",
            param       => "userId",
            message     => "",
        } );
    }
    elsif ( $userId eq "1" || $userId eq "3" ) {
        $session->response->status(403);
        return createServiceResponse( $outputFormat, {
            error       => 'WebGUI::Error::InvalidParam',
            param       => 'userId',
            message     => 'Cannot delete system user',
        } );
    }
    elsif ( !WebGUI::User->validUserId( $session, $userId ) ) {
        return createServiceResponse( $outputFormat, {
            error       => 'WebGUI::Error::InvalidParam',
            param       => 'userId',
            message     => '',
        } );
    }

    ### Delete user
    my $user    = WebGUI::User->new( $session, $userId );
    $user->delete;
    
    return createServiceResponse( $outputFormat, {
        message         => 'User deleted',
    } );
}

#-------------------------------------------------------------------

=head2 www_ajaxUpdateUser ( )

Update a user using a web service.

=cut

sub www_ajaxUpdateUser {
    my ( $session ) = @_;
    
    ### Get desired output format first (for future error messages)
    my $outputFormat    = "json";
    my $mimeType        = "application/json";

    # Allow XML
    if ( lc $session->form->get('as') eq "xml" ) {
        $outputFormat   = "xml";
        $mimeType       = "application/xml";
    }

    $session->response->content_type( $mimeType ); 

    # Verify access
    if ( !canEdit($session) || !canUseService($session) ) {
        # We need an automatic way to send a request for an http basic auth
        $session->response->status(401);
        return createServiceResponse( $outputFormat, {
            error       => "WebGUI::Error::Unauthorized",
            message     => "",
        } );
    }

    ### Verify data
    # User data is <PROPERTY_NAME> in form
    my %userParam = (
        map { $_ => $session->form->get($_) }
        grep { !/^auth:/ && $_ ne "op" }
        ( $session->form->param )
    );

    # Auth data is auth:<AUTH_METHOD>:<PROPERTY_NAME> in form
    my %authParam    = ();
    for my $formParam ( grep { /^auth:[^:]+:.+$/ } $session->form->param ) {
        my ( $authMethod, $property ) = $formParam =~ /^auth:([^:]+):(.+)$/;
        $authParam{$authMethod}{$property} = $session->form->get($formParam);
    }

    # User must have a userId
    if ( !$userParam{userId} ) {
        return createServiceResponse( $outputFormat, {
            error       => "WebGUI::Error::InvalidParam",
            param       => "userId",
            message     => "",
        } );
    }
    # User must exist
    if ( !WebGUI::User->validUserId( $session, $userParam{userId} ) ) {
        return createServiceResponse( $outputFormat, {
            error       => "WebGUI::Error::InvalidParam",
            param       => "userId",
            message     => "",
        } );
    }

    ### Update user
    my $user    = WebGUI::User->new( $session, delete $userParam{userId} );
    $user->update( \%userParam );
    for my $authMethod ( keys %authParam ) {
        my $auth = WebGUI::Operation::Auth::getInstance($session,$authMethod,$user->getId);

        # XXX Special handling for WebGUI passwords. This should be removed when 
        # Auth is fixed in WebGUI 8
        if ( $authMethod eq 'WebGUI' && exists $authParam{$authMethod}{identifier} ) {
            $authParam{$authMethod}{identifier}
                = $auth->hashPassword( $authParam{$authMethod}{identifier} );
        }

        $auth->saveParams( $user->getId, $auth->authMethod, $authParam{$authMethod} );
    }

    ### Send user's data
    return createServiceResponse( $outputFormat, {
        user        => $user->get,
    } );
}

#-------------------------------------------------------------------

=head2 www_becomeUser ( )

Allows an administrator to assume another user.

=cut

sub www_becomeUser {
	my $session = shift;
	return $session->privilege->adminOnly() unless canEdit($session) && $session->form->validToken;
	return undef unless WebGUI::User->validUserId($session, $session->form->process("uid"));
	$session->end();
	$session->user({userId=>$session->form->process("uid")});
	return "";
}

#-------------------------------------------------------------------

=head2 www_deleteUser ( )

Deletes a user.  Only Admins are allowed to delete users.  The UID of the user
to delete is expected in a URL param named 'uid'.  www_listUsers is called
after this.

=cut

sub www_deleteUser {
	my $session = shift;
	return $session->privilege->adminOnly() unless canEdit($session) && $session->form->validToken;
    if ($session->form->process("uid") eq '1' || $session->form->process("uid") eq '3') {
        return WebGUI::AdminConsole->new($session,"users")->render($session->privilege->vitalComponent());
    }
    else {
        my $u = WebGUI::User->new($session,$session->form->process("uid"));
        $u->delete;
        return www_listUsers($session);
    }
}

#-------------------------------------------------------------------

=head2 www_editUser ( )

Provides a form for editing a user, or adding a new user.

=cut

sub www_editUser {

	my $session = shift;
	return $session->privilege->adminOnly() unless canAdd($session);
	my $error = shift;
	my $uid = shift || $session->form->process("uid");

	my $u = WebGUI::User->new($session,($uid eq 'new') ? '' : $uid); #Setting uid to '' when uid is 'new' so visitor defaults prefill field for new user
	my $username = ($u->isVisitor && $uid ne "1") ? '' : $u->username;

	my $i18n = WebGUI::International->new($session, "WebGUI");

    my $f = WebGUI::FormBuilder->new( $session, 
        action => $session->url->page,
        extras => 'autocomplete="off"',
    );

    # something, probably YUI, winds up striping the styling off of this, including the position, leaving this hanging awkwardly off to the left above the tabs
    # the Button class styles it up in YUI trappings; skip that; abuse the Control control to render raw HTML
    #$f->addField( 'Button',
    #    name    => 'submit',
    #    value   => 'Save',
    #    extras  => 'style="position: absolute; top: 10px; right: 10px; z-index: 50000;"',
    #);
    $f->addField( 'Control',
        name    => 'submit',
        value   => q{
            <div style="position: absolute; top: 10px; right: 10px; z-index: 50000;">
                <input type="submit" name="submit" value="Save"/>
                <input type="button" value="cancel" onclick="history.go(-1);" class="backwardButton" />
            </div>
        },
    );

    $f->addField( 'csrfToken', name => 'csrfToken' );
    $f->addField( "hidden",
        name => 'op',
        value => 'editUserSave',
    );
    $f->addField( "hidden", 
        name => "uid", 
        value => $uid,
    );
    my $account = $f->addTab( name => "account", label => $i18n->get('account') );
    my $profile = $f->addTab( name => "profile", label => $i18n->get('profile') );
    my $groups = $f->addTab( name => "groups", label => $i18n->get('89') );

    # Normal user fields
    $account->addField( "readOnly", 
        name => "uid", 
        value => $uid, 
        label => $i18n->get(378),
    );
    $account->addField( "readOnly", 
        name => "karma", 
        value => $u->karma,
        label => $i18n->get(537)
    ) if ($session->setting->get("useKarma"));
    $account->addField( "readOnly",
        name => "dateCreated",
        value=>$session->datetime->epochToHuman($u->dateCreated,"%z"),
        label=>$i18n->get(453)
    );
    $account->addField( "readOnly",
        name => "lastUpdated",
        value=>$session->datetime->epochToHuman($u->lastUpdated,"%z"),
        label=>$i18n->get(454)
    );
    $account->addField( "text",
        name=>"username",
        label=>$i18n->get(50),
        value=>$username,
        extras=>'autocomplete="off"',
    );

	if ($u->userId eq $session->user->userId) {
		$account->addField( "hidden",
			name => "status",
			value => $u->status
			);
	}
    else {
        tie my %status, 'Tie::IxHash', (
            Active		=>$i18n->get(817),
            Deactivated	=>$i18n->get(818),
            Selfdestructed	=>$i18n->get(819)
        );
		$account->addField( "selectBox",
			name => "status",
			options => \%status,
			label => $i18n->get(816),
			value => $u->status
			);
	}

    # Auth configurations
	my $options;
	foreach (@{$session->config->get("authMethods")}) {
		$options->{$_} = $_;
	}
	$account->addField( "selectBox",
	        name=>"authMethod",
		options=>$options,
		label=>$i18n->get(164),
		value=>$u->authMethod,
    );
	foreach my $auth (@{$session->config->get("authMethods")}) {
		my $authInstance = WebGUI::Operation::Auth::getInstance($session,$auth,$u->userId);
        my $editUserForm = $authInstance->editUserForm;
        next unless $editUserForm;
        $account->addFieldset( $editUserForm, name => $auth, label => $auth );
	}

    # Profile fields
	foreach my $category (@{WebGUI::ProfileCategory->getCategories($session)}) {
		my $fieldset = $profile->addFieldset( name => $category->getLabel, label => $category->getLabel );
		foreach my $field (@{$category->getFields}) {
			next if $field->getId =~ /contentPositions/;
			my $label = $field->getLabel . ($field->isRequired ? "*" : '');
			if ($u->isVisitor) {
				$fieldset->addField($field->formField({label=>$label},1,undef,undef,undef,1,'useFormDefault'));
			}
            else {
				$fieldset->addField($field->formField({label=>$label},1,$u,undef,undef,1));
			}
		}
	}

    # Groups
	my @groupsToAdd = $session->form->group("groupsToAdd");
	my @exclude = $session->db->buildArray("select groupId from groupings where userId=?",[$u->userId]);
	push @exclude,"1","2","7"; # Special groups cannot be left/joined
    my $secondaryAdmin = $session->user->isInGroup('11');
    if ($secondaryAdmin && !$session->user->isAdmin) {
        push @exclude, $session->db->buildArray('select groupId from groups where groupId not in (select groupId from groupings where userId=?)',[$session->user->userId]);
    }
	$groups->addField( "group",
		name=>"groupsToAdd",
		label=>$i18n->get("groups to add"),
		excludeGroups=>\@exclude,
		size=>15,
		multiple=>1,
		value=>\@groupsToAdd
		);
	my @include; 
	foreach my $group (@exclude) {
		unless (
			$group eq "1" || $group eq "2" || $group eq "7"     # can't remove user from magic groups 
			|| ($session->user->userId eq $uid  && $group eq 3) # cannot remove self from admin
			|| ($uid eq '3' && $group eq "3")                   # user Admin cannot be removed from admin group
			) {
			push(@include,$group);
		}
	}
	push (@include, "0");
	my @groupsToDelete = $session->form->group("groupsToDelete");
	$groups->addField( "selectList",
		name=>"groupsToDelete",
		options=>$session->db->buildHashRef("select groupId, groupName from groups 
			where groupId in (".$session->db->quoteAndJoin(\@include).") and showInForms=1 order by groupName"),
		label=>$i18n->get("groups to delete"),
		multiple=>1,
		size=>15,
		value=>\@groupsToDelete
		);

    # my $html = '<h1>' . $i18n->get(168) . '</h1>' . $error . $f->toHtml;  # skip the large header
    my $html = $error . $f->toHtml;

    return $session->style->process( 
        '<div class="yui-skin-sam">' . $html . '</div>',
        "PBtmpl0000000000000137"
    );


}

#-------------------------------------------------------------------

=head2 www_editUserSave ( )

Process the editUser form data.  Returns adminOnly unless the user has privileges
to add/edit users and the submitted form passes the validToken check.

=cut

sub www_editUserSave {
	my $session = shift;
	my $postedUserId = $session->form->process("uid"); #userId posted from www_editUser form
	my $isAdmin = canEdit($session);
	my $isSecondary;
	my $i18n = WebGUI::International->new($session);
	my ($existingUserId) = $session->db->quickArray("select userId from users where username=".$session->db->quote($session->form->process("username")));
	my $error;
	my $actualUserId;  #userId returned from the user object

	unless ($isAdmin) {
		$isSecondary = (canAdd($session) && $postedUserId eq "new");
	}

	return $session->privilege->adminOnly() unless ($isAdmin || $isSecondary) && $session->form->validToken;

    # Check to see if
	# 1) the userId associated with the posted username matches the posted userId (we're editing an account)
	# or that the userId is new and the username selected is unique (creating new account)
	# or that the username passed in isn't assigned a userId (changing a username)
	#
	# Also verify that the posted username is not blank (we need a username)
	#

	my $postedUsername = $session->form->process("username");
	$postedUsername = WebGUI::HTML::filter($postedUsername, "all");

    if (($existingUserId eq $postedUserId || ($postedUserId eq "new" && !$existingUserId) || $existingUserId eq '')
             && $postedUsername ne '') 
             {
        # Create a user object with the id passed in.  If the Id is 'new', the new method will return a new user,
        # otherwise return the existing users properties
	   	my $u = WebGUI::User->new($session,$postedUserId);
	   	$actualUserId = $u->userId;
	   	
		# Update the user properties with passed in values.  These methods will save changes to the db.
	   	$u->username($postedUsername);
	   	$u->authMethod($session->form->process("authMethod"));
	   	$u->status($session->form->process("status"));

        # Loop through all of this users authentication methods
        foreach (@{$session->config->get("authMethods")}) {
            # Instantiate each auth object and call it's save method.  These methods are responsible for
            # updating authentication information with values supplied by the www_editUser form.
                my $authInstance = WebGUI::Operation::Auth::getInstance($session, $_, $actualUserId);
                $authInstance->editUserFormSave();
        }
       		
        # Loop through all profile fields, and update them with new values.
        my $address          = {};
        my $address_mappings = WebGUI::Shop::AddressBook->getProfileAddressMappings;
        foreach my $field (@{WebGUI::ProfileField->getFields($session)}) {
			next if $field->getId =~ /contentPositions/;
            my $field_value = $field->formProcess($u);
			$u->update({ $field->getId => $field_value} );

            #set the shop address fields
            my $address_key          = $address_mappings->{$field->getId};
            $address->{$address_key} = $field_value if ($address_key);
		}

        #Update or create and update the shop address
        if ( keys %$address ) {
            $address->{'isProfile'        } = 1;

            #Get the address book for the user (one is created if it does not exist)
            my $addressBook     = WebGUI::Shop::AddressBook->newByUserId($session, $actualUserId,);
            my $profileAddress = eval { $addressBook->getProfileAddress() };

            my $e;
            if($e = WebGUI::Error->caught('WebGUI::Error::ObjectNotFound')) {
                #Get home address only mappings to avoid creating addresses with just firstName, lastName, email
                my %home_address_map = %{$address_mappings};
                delete $home_address_map{qw/firstName lastName email/};
                #Add the profile address for the user if there are homeAddress fields
                if( grep { $address->{$_} } values %home_address_map ) {
                    $address->{label} = "Profile Address";
                    my $new_address = $addressBook->addAddress($address);
                    #Set this as the default address if one doesn't already exist
                    my $defaultAddress = eval{ $addressBook->getDefaultAddress };
                    if(WebGUI::Error->caught('WebGUI::Error::ObjectNotFound')) {
                        $addressBook->update( {
                            defaultAddressId => $new_address->getId
                        } );
                    }
                    else {
                        $session->log->warn("The default address exists, and it should not.");
                    }
                }
            }
            elsif ($e = WebGUI::Error->caught) {
                #Bad stuff happened - log an error but don't fail since this isn't a vital function
                $session->log->error(
                    q{Could not update Shop Profile Address for user }
                        .$u->username.q{ : }.$e->error
                );
            }
            else {
                #Update the profile address for the user
                $profileAddress->update($address);
            }
        }
		
		# Update group assignements
		my @groups = $session->form->group("groupsToAdd");
		$u->addToGroups(\@groups);
		@groups = $session->form->group("groupsToDelete");
		$u->deleteFromGroups(\@groups);
	
        # trigger workflows	
        if ($postedUserId eq "new") {
	        if ($session->setting->get("runOnAdminCreateUser")) {
		        WebGUI::Workflow::Instance->create($session, {
			        workflowId=>$session->setting->get("runOnAdminCreateUser"),
			        methodName=>"new",
			        className=>"WebGUI::User",
			        parameters=>$u->userId,
			        priority=>1
			        })->start;
	        }
        }
        else {
	        if ($session->setting->get("runOnAdminUpdateUser")) {
		        WebGUI::Workflow::Instance->create($session, {
			        workflowId=>$session->setting->get("runOnAdminUpdateUser"),
			        methodName=>"new",
			        className=>"WebGUI::User",
			        parameters=>$u->userId,
			        priority=>1
			        })->start;
	        }
        }
	# Display an error telling them the username they are trying to use is not available and suggest alternatives	
	} else {
       		$error = '<ul>' . sprintf($i18n->get(77), $postedUsername, $postedUsername, $postedUsername, $session->datetime->epochToHuman(time(),"%y")).'</ul>';
	}
	if ($isSecondary) {
		return _submenu($session,{workarea => $i18n->get(978)});

	# Display updated user information
	} else {
		return www_editUser($session,$error,$actualUserId);
	}
}

#-------------------------------------------------------------------

=head2 www_editUserKarma ( )

Provides a form for directly editing the karma for a user.  Returns adminOnly
unless the current user can manage users.

=cut

sub www_editUserKarma {
	my $session = shift;
	return $session->privilege->adminOnly() unless canEdit($session);
        my ($output, $f, $a, %user, %data, $method, $values, $category, $label, $default, $previousCategory);
	my $i18n = WebGUI::International->new($session);
        $f = WebGUI::HTMLForm->new($session);
	$f->submit;
        $f->hidden(
		-name => "op",
		-value => "editUserKarmaSave",
        );
        $f->hidden(
		-name => "uid",
		-value => $session->form->process("uid"),
        );
	$f->integer(
		-name => "amount",
		-label => $i18n->get(556),
		-hoverHelp => $i18n->get('556 description'),
	);
	$f->text(
		-name => "description",
		-label => $i18n->get(557),
		-hoverHelp => $i18n->get('557 description'),
	);
        $f->submit;
        $output .= $f->print;
	my $submenu = _submenu(
                    $session,
                    { workarea => $output,
					  title    => 558, }
                  );  
        return $submenu;
}

#-------------------------------------------------------------------

=head2 www_editUserKarmaSave ( )

Processes the form submitted  by www_editUserKarma.  Returns adminOnly
unless the current user can manage users and the submitted from passes
the validToken check.

=cut

sub www_editUserKarmaSave {
	my $session = shift;
	return $session->privilege->adminOnly() unless canEdit($session) && $session->form->validToken;
        my ($u);
        $u = WebGUI::User->new($session,$session->form->process("uid"));
        $u->karma($session->form->process("amount"),$session->user->username." (".$session->user->userId.")",$session->form->process("description"));
        return www_editUser($session);
}

#-------------------------------------------------------------------

=head2 www_formUsers ( session )

Form helper to pick a user from the system.

=head3 session

A reference to the current session.

=cut

sub www_formUsers {
	my $session = shift;
	$session->response->setCacheControl("none");
	return $session->privilege->insufficient() unless $session->user->isInGroup(12);
	$session->style->useEmptyStyle("1");
    my $output = getUserSearchForm($session,"formUsers",{formId=>$session->form->process("formId")},1);
	my ($userCount) = $session->db->quickArray("select count(*) from users");
	return $output unless ($session->form->process("doit") || $userCount<250 || $session->form->process("pn") > 1);
	$output .= '<ul>';
	my $p = doUserSearch($session,"formUsers;formId=".$session->form->process("formId"),1);
	foreach my $data (@{$p->getPageData}) {
		$output .= '<li><a href="#" onclick="window.opener.document.getElementById(\''.$session->form->process("formId").'\').value=\''.$data->{userId}.'\';window.opener.document.getElementById(\''.$session->form->process("formId").'_display\').value=\''.$data->{username}.'\';window.close();">'.$data->{username}.'</a></li>';
	}
    $output .= '</ul>';
    $output .= $p->getBarTraditional;
	return $output;
}


#-------------------------------------------------------------------

=head2 www_listUsers ( )

Provides a paginated list of all users, and controls for adding a new user.  If the
current user is only allowed to add users, then it sends them directly to www_editUser.
If the current user is not allowed to edit or create users, it returns adminOnly.

=cut

sub www_listUsers {
	my $session = shift;

    # If the user is only allowed to add users, send them right there.
	unless (canEdit($session)) {
		if (canAdd($session)) {
			return www_editUser($session, undef, "new");
		}
        else {
		    return $session->privilege->adminOnly();
        }
	}

	my $i18n = WebGUI::International->new($session);
	my $output = getUserSearchForm($session,"listUsers");
	my ($userCount) = $session->db->quickArray("select count(*) from users");
    if($userCount > 250) {
        $output .= $i18n->get('high user count');
    }
    
	return _submenu($session,{workarea => $output}) unless ($session->form->process("doit") || $userCount<250 || $session->form->process("pn") > 1);
	my %status = (
		Active		=> $i18n->get(817),
		Deactivated	=> $i18n->get(818),
		Selfdestructed	=> $i18n->get(819)
	);
        $output .= '<table border="1" cellpadding="5" cellspacing="0" align="center">';
        $output .= '<tr>
                <td class="tableHeader">'.$i18n->get(816).'</td>
                <td class="tableHeader">'.$i18n->get(50).'</td>
                <td class="tableHeader">'.$i18n->get(56).'</td>
                <td class="tableHeader">'.$i18n->get(453).'</td>
                <td class="tableHeader">'.$i18n->get(454).'</td>
                <td class="tableHeader">'.$i18n->get(429).'</td>
                <td class="tableHeader">'.$i18n->get(434).'</td>
                <td class="tableHeader">'.$i18n->get(430).'</td>
                <td class="tableHeader">'.$i18n->get( "time recorded" ).'</td>
		</tr>';
	my $p = doUserSearch($session,"listUsers",1);
    my $user_loginlog = $session->db->prepare(
        q{
            select   status, timeStamp, lastPageViewed, sessionId
            from     userLoginLog
            where    userId = ?
            order by timeStamp desc
            limit    1
        },
    );
    my $last_page_view = $session->db->prepare(
        q{
            select lastPageView
            from   userSession
            where  sessionId = ?
        },
    );
    my $total_time = $session->db->prepare(
        q{
            select sum(lastPageViewed - timeStamp) 
            from   userLoginLog 
            where  userId = ?
        },
    );
	foreach my $data (@{$p->getPageData}) {
        $output .= '<tr class="tableData">';
        $output .= '<td>'.$status{$data->{status}}.'</td>';
        $output .= '<td><a href="'.$session->url->page('op=editUser;uid='.$data->{userId})
           .'">'.$data->{username}.'</a></td>';
        $output .= '<td class="tableData">'.$data->{email}.'</td>';
        $output .= '<td class="tableData">'.$session->datetime->epochToHuman($data->{dateCreated},"%z").'</td>';
        $output .= '<td class="tableData">'.$session->datetime->epochToHuman($data->{lastUpdated},"%z").'</td>';

        $user_loginlog->execute([$data->{userId}]);
        my ( $status, $lastLogin, $lastView, $lastSession ) = $user_loginlog->fetchrow_array;

        $last_page_view->execute([$lastSession]);
        my ($trueLastView) = $last_page_view->fetchrow_array();

        # format last page view, preferring session recorded view time
        $lastView   = $trueLastView || $lastView;
        $lastView &&= $session->datetime->epochToHuman($lastView);

        $lastLogin &&= $session->datetime->epochToHuman($lastLogin);

        $total_time->execute([$data->{userId}]);
        my ($totalTime) = $total_time->fetchrow_array();

        if ($totalTime) {
            my ($interval, $units) 
                = $session->datetime->secondsToInterval($totalTime);
            $totalTime = "$interval $units";
        }

        foreach my $cell ($lastLogin, $status, $lastView, $totalTime) {
            $cell  ||= ' - ';
            $output .= qq(<td class="tableData">$cell</td>);
        }

        $output .= '</tr>';
	}
    $output .= '</table>';
    $p->setAlphabeticalKey('username');
    $output .= $p->getBarTraditional;
    $user_loginlog->finish;
    $last_page_view->finish;
    $total_time->finish;
	my $submenu = _submenu(
                    $session,
                    { workarea => $output, }
                  );
	return $submenu;
}

1;

