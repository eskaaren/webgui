package WebGUI::Wizard::HomePage;

use strict;
use base 'WebGUI::Wizard';

=head1 NAME

WebGUI::Wizard::HomePage - Create or replace a Home Page with new content

=cut

sub _get_steps {
    return [ qw(
            pickStyle
            chooseContent
            finalize
            )
    ];
}

#-------------------------------------------------------------------

=head2 addAsset ( parent, properties ) 

A helper to add assets with less code.

=head3 parent

The parent asset to add to.

=head3 properties

A hash ref of properties to attach to the asset. One must be className.

=cut

sub addAsset {
    my $parent     = shift;
    my $properties = shift;
    $properties->{url}                      = $parent->get("url") . "/" . $properties->{title};
    $properties->{groupIdEdit}              = $parent->get("groupIdEdit");
    $properties->{groupIdView}              = $parent->get("groupIdView");
    $properties->{ownerUserId}              = $parent->get("ownerUserId");
    $properties->{styleTemplateId}          = $parent->get("styleTemplateId");
    $properties->{printableStyleTemplateId} = $parent->get("styleTemplateId");
    return $parent->addChild($properties);
}

#-------------------------------------------------------------------

=head2 addPage ( parent, title ) 

Adds a page to a parent page.

=head3 parent

A parent page asset.

=head3 title

The title of the new page.

=cut

sub addPage {
    my $parent = shift;
    my $title  = shift;
    return addAsset( $parent, { title => $title, className => "WebGUI::Asset::Wobject::Layout", displayTitle => 0 } );
}

sub wrapStyle { 
    return WebGUI::Wizard::Setup::wrapStyle( @_ );
}

sub www_pickStyle {
    my ( $self ) = @_;
    my $session = $self->session;
    my $f       = $self->getForm;
    my $i18n = WebGUI::International->new( $session, "WebGUI" );

    my $output  = '<h1>' . $i18n->get('1073') . '</h1>';

    my @styleIds
        = $session->db->buildArray( 
            q{SELECT DISTINCT(assetId) FROM template WHERE namespace="style"}
        );

    # Verboten:
    #   PBtmpl0000000000000060
    #   PBtmpl0000000000000111
    #   PBtmpl0000000000000137
    #   PBtmpl0000000000000132

    # Blank style: 
    #   PBtmplBlankStyle000001
    my @skipStyleIds    = qw( PBtmpl0000000000000060 PBtmpl0000000000000111 PBtmpl0000000000000137
                            PBtmpl0000000000000132 PBtmplBlankStyle000001 );

    # Instantiate the objects
    my @styles;
    for my $styleId ( @styleIds ) {
        next if grep { $_ eq $styleId } @skipStyleIds;
        my $style   = WebGUI::Asset->newByDynamicClass( $session, $styleId );
        push @styles, $style;
    }

    for my $style ( sort { $a->getTitle cmp $b->getTitle } @styles ) {
        $f->raw(
            '<div class="stylePicker"><label><input type="radio" name="styleTemplateId" value="' . $style->getId . '"/>'
            . '<img src="' . $style->getExampleImageUrl . '" height="150" />' 
            . '<div class="title">' . $style->getTitle . '</div>'
            . '<div class="synopsis">' . $style->get('synopsis') . '</div></label>'
            . '</div>'
        );
    }
    $f->submit;

    $output .= $f->print;

    return $output . '<div style="clear: both;">&nbsp;</div>';
}

sub www_pickStyleSave {
    my ( $self ) = @_;
    my $session = $self->session;
    my ( $form ) = $session->quick(qw( form ));

    # Coming from initial setup:
    if ( $form->get('initialSetup') ) {
        $self->set({ initialSetup => 1 });
    }

    $self->set({ "styleTemplateId", $form->get('styleTemplateId') });

    return;
}

sub www_chooseContent {
    my ($self)  = @_;
    my $session = $self->session;
    my $form    = $session->form;
    $session->http->setCacheControl("none");
    my $i18n = WebGUI::International->new( $session, "WebGUI" );

    my $output = '<h1>' . $i18n->get('Initial Pages') . '</h1>';

    my $f = $self->getForm;
    $f->yesNo( name => "contactUs", label => $i18n->get('Contact Us') );
    $f->yesNo( name => "calendar",  label => $i18n->get( "assetName", 'Asset_Calendar' ) );
    $f->yesNo( name => "wiki",      label => $i18n->get( 'assetName', 'Asset_WikiMaster' ) );
    $f->yesNo( name => "search",    label => $i18n->get( "assetName", 'Asset_Search' ) );
    $f->yesNo( name => "aboutUs",   label => $i18n->get("About Us") );
    $f->HTMLArea(
        name       => "aboutUsContent",
        richEditId => "PBrichedit000000000002",
        value      => $i18n->get("Put your about us content here.")
    );

    if ( exists $session->config->get('assets')->{"WebGUI::Asset::Wobject::Collaboration"} ) {
        $f->yesNo( name => "news",   label => $i18n->get(357) );
        $f->yesNo( name => "forums", label => $i18n->get("Forums") );
        $f->textarea(
            name    => "forumNames",
            subtext => $i18n->get("One forum name per line"),
            value   => $i18n->get("Support") . "\n" . $i18n->get("General Discussion")
        );
    }
    $f->submit;
    $output .= $f->print;

    return $output;
} ## end sub www_chooseContent

sub www_chooseContentSave {
    my ($self)  = @_;
    my $session = $self->session;
    my $form    = $session->form;
    my $i18n = WebGUI::International->new( $session, "WebGUI" );

    my $home;
    if ( $self->get('initialSetup') ) {
        $home = WebGUI::Asset->getDefault($session);
    }
    else {
        my $root = WebGUI::Asset->getRoot($session);
        $home = addPage( $root, "New Home Page" );
    }

    # update default site style
    foreach my $asset ( @{ $home->getLineage( [ "self", "descendants" ], { returnObjects => 1 } ) } ) {
        if ( defined $asset ) {
            $asset->update( { styleTemplateId => $self->get("styleTemplateId") } );
        }
    }

    # add new pages
    if ( $form->get("aboutUs") ) {
        my $page = addPage( $home, $i18n->get("About Us") );
        addAsset(
            $page, {
                title       => $i18n->get("About Us"),
                isHidden    => 1,
                className   => "WebGUI::Asset::Wobject::Article",
                description => $form->get("aboutUsContent"),
            }
        );
    }

    # add forums
    if ( $form->get("forums") ) {
        my $page = addPage( $home, $i18n->get("Forums") );
        my $board = addAsset(
            $page, {
                title       => $i18n->get("Forums"),
                isHidden    => 1,
                className   => "WebGUI::Asset::Wobject::MessageBoard",
                description => $i18n->get("Discuss your ideas and get help from our community."),
            }
        );
        my $forumNames = $form->get("forumNames");
        $forumNames =~ s/\r//g;
        foreach my $forumName ( split "\n", $forumNames ) {
            next if $forumName eq "";
            addAsset(
                $board, {
                    title     => $forumName,
                    isHidden  => 1,
                    className => "WebGUI::Asset::Wobject::Collaboration"
                }
            );
        }
    } ## end if ( $form->get("forums"...))

    # add news
    if ( $form->get("news") ) {
        my $page = addPage( $home, $i18n->get(357) );
        addAsset(
            $page, {
                title                   => $i18n->get(357),
                isHidden                => 1,
                className               => "WebGUI::Asset::Wobject::Collaboration",
                collaborationTemplateId => "PBtmpl0000000000000112",
                allowReplies            => 0,
                attachmentsPerPost      => 5,
                postFormTemplateId      => "PBtmpl0000000000000068",
                threadTemplateId        => "PBtmpl0000000000000067",
                description             => $i18n->get("All the news you need to know."),
            }
        );
    } ## end if ( $form->get("news"...))

    # add wiki
    if ( $form->get("wiki") ) {
        my $page = addPage( $home, $i18n->get( "assetName", 'Asset_WikiMaster' ) );
        addAsset(
            $page, {
                title            => $i18n->get( "assetName", 'Asset_WikiMaster' ),
                isHidden         => 1,
                allowAttachments => 5,
                className        => "WebGUI::Asset::Wobject::WikiMaster",
                description => $i18n->get("Welcome to our wiki. Here you can help us keep information up to date."),
            }
        );
    }

    # add calendar
    if ( $form->get("calendar") ) {
        my $page = addPage( $home, $i18n->get( 'assetName', "Asset_Calendar" ) );
        addAsset(
            $page, {
                title       => $i18n->get( 'assetName', "Asset_Calendar" ),
                isHidden    => 1,
                className   => "WebGUI::Asset::Wobject::Calendar",
                description => $i18n->get("Check out what is going on."),
            }
        );
    }

    # add contact us
    if ( $form->get("contactUs") ) {
        my $page = addPage( $home, $i18n->get("Contact Us") );
        my $i18n2 = WebGUI::International->new( $session, "Asset_DataForm" );
        my @fieldConfig = ( {
                name        => "from",
                label       => $i18n2->get( "Your Email Address", 'WebGUI' ),
                status      => "required",
                isMailField => 1,
                width       => 0,
                type        => "email",
            }, {name         => "to",
                label        => $i18n2->get(11),
                status       => "hidden",
                isMailField  => 1,
                width        => 0,
                type         => "email",
                defaultValue => $session->setting->get("companyEmail"),
            }, {name        => "cc",
                label       => $i18n2->get(12),
                status      => "hidden",
                isMailField => 1,
                width       => 0,
                type        => "email",
            }, {name        => "bcc",
                label       => $i18n2->get(13),
                status      => "hidden",
                isMailField => 1,
                width       => 0,
                type        => "email",
            }, {name         => "subject",
                label        => $i18n2->get(14),
                status       => "hidden",
                isMailField  => 1,
                width        => 0,
                type         => "text",
                defaultValue => $i18n->get(2),
            }, {name    => "comments",
                label   => $i18n->get( "comments", 'VersionTag' ),
                status  => "required",
                type    => "textarea",
                subtext => $i18n->get("Tell us how we can assist you."),
            },
        );
        my $dataForm = addAsset(
            $page, {
                title       => $i18n->get("Contact Us"),
                isHidden    => 1,
                className   => "WebGUI::Asset::Wobject::DataForm",
                description => $i18n->get("We welcome your feedback."),
                acknowledgement =>
                    $i18n->get("Thanks for for your interest in ^c;. We will review your message shortly."),
                mailData           => 1,
                fieldConfiguration => JSON->new->encode( \@fieldConfig ),
            }
        );
    } ## end if ( $form->get("contactUs"...))

    # add search
    if ( $form->get("search") ) {
        my $page = addPage( $home, $i18n->get( 'assetName', "Asset_Search" ) );
        addAsset(
            $page, {
                title       => $i18n->get( 'assetName', "Asset_Search" ),
                isHidden    => 1,
                className   => "WebGUI::Asset::Wobject::Search",
                description => $i18n->get("Cannot find what you are looking for? Try our search."),
                searchRoot  => $home->getId,
            }
        );
    }

    # commit the working tag
    my $working = WebGUI::VersionTag->getWorking($session);
    $working->set( { name => "Home Page Wizard" } );
    $working->commit;

    return;
} ## end sub www_chooseContentSave

sub www_finalize {
    my ($self) = @_;
    my $session = $self->session;
    $session->http->setCacheControl("none");
    $session->http->setRedirect( $session->url->gateway );
    return "redirect";
}

1;
