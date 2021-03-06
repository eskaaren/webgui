package WebGUI::Definition::Meta::Property::Asset;

=head1 LEGAL

 -------------------------------------------------------------------
  WebGUI is Copyright 2001-2012 Plain Black Corporation.
 -------------------------------------------------------------------
  Please read the legal notices (docs/legal.txt) and the license
  (docs/license.txt) that came with this distribution before using
  this software.
 -------------------------------------------------------------------
  http://www.plainblack.com                     info@plainblack.com
 -------------------------------------------------------------------

=cut

use 5.010;
use Moose::Role;
use namespace::autoclean;
no warnings qw(uninitialized);

our $VERSION = '0.0.1';

=head1 NAME

Package WebGUI::Definition::Meta::Property::Asset

=head1 DESCRIPTION

Extends WebGUI::Definition::Meta::Property to provide Asset properties with
specific methods.  The tableName and fieldType class properties must be defined.

=head1 METHODS

The following methods are added.

=cut

has 'tableName' => (
    is       => 'ro',
    required => 1,
);

has 'fieldType' => (
    is       => 'ro',
    required => 1,
);

has 'noFormPost' => (
    is => 'ro',
);

#-------------------------------------------------------------------

=head2 tableName ( )

Previously, properties were storied in arrays of definitions, with each definition
providing its own attributes like table.  This Moose based implementation stores
the properties flat, so the tableName attribute is copied into the property so we
know where to store it.

=cut

#-------------------------------------------------------------------

=head2 fieldType ( )

The type of HTML form field that this property should use to generate its UI
and validate its data.

=cut

#-------------------------------------------------------------------

=head2 noFormPost ( )

This is boolean which indicates that no data from HTML forms should be validated
and stored for this property.

=cut

1;

