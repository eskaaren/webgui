#!/usr/bin/perl

use lib "../../lib";
use File::Path;
use Getopt::Long;
use strict;
use WebGUI::Asset;
use WebGUI::Session;
use WebGUI::SQL;

my $configFile;
my $quiet;

GetOptions(
    'configFile=s'=>\$configFile,
	'quiet'=>\$quiet
);

WebGUI::Session::open("../..",$configFile);

#--------------------------------------------
print "\tDeleting old templates\n" unless ($quiet);
my $asset = WebGUI::Asset->newByDynamicClass("PBtmpl0000000000000035");
$asset->purge;

#--------------------------------------------
print "\tUpdating config file.\n" unless ($quiet);
my $pathToConfig = '../../etc/'.$configFile;
my $conf = Parse::PlainConfig->new('DELIM' => '=', 'FILE' => $pathToConfig, 'PURGE'=>1);
my %newConfig;
foreach my $key ($conf->directives) {
	unless ($key eq "logfile" || $key eq "passwordChangeLoggingEnabled" || $key eq "emailRecoveryLoggingEnabled") {
		$newConfig{$key} = $conf->get($key);
	}
}
my @newAssetList;
foreach my $asset (@{$newConfig{assets}}) {
	push(@newAssetList, $asset) unless ($asset eq "WebGUI::Asset::Template");
}
$newConfig{utilityAssets} = ["WebGUI::Asset::Template","WebGUI::Asset::RichEdit"];
$newConfig{assets} = \@newAssetList;
$newConfig{shippingPlugins} = ['ByPrice', 'ByWeight', 'PerTransaction'];

$conf->purge;
$conf->set(%newConfig);
$conf->write;

#--------------------------------------------
print "\tAdding default product template\n" unless ($quiet);
my $import = WebGUI::Asset->newByUrl('templates');
my $folder = $import->addChild({
	title=>"Commerce/Product",
	menuTitle=>"Commerce/Product",
	url=>"Commerce/Product",
	className=>"WebGUI::Asset::Wobject::Folder"
	});
$folder->addChild({
	namespace=>'Commerce/Product',
	title=>'Default Product Template',
	menuTitle=>'Default Product Template',
	url=>'Default Produuct Template',
	showInForms=>1,
	isEditable=>1,
	className=>"WebGUI::Asset::Template",
	template=>'<h1><tmpl_var title></h1>
<tmpl_var description><br>
<br>
<tmpl_var variants.message><br>

<table>
	<tmpl_loop variantLoop>
	<tr>
		<td style="indent: 40px">
		<tmpl_loop variant.compositionLoop>
			<tmpl_var parameter>: <tmpl_var value><tmpl_unless __LAST__>,</tmpl_unless>
		</tmpl_loop>
		</td>
		<td>$ <tmpl_var variant.price></td>
		<td><a href="<tmpl_var variant.addToCart.url>"><tmpl_var variant.addToCart.label></a></td>
	</tr>
	</tmpl_loop>
</table>' },'PBtmplCP00000000000001');

#--------------------------------------------
print "\tAdding default select shipping method template\n" unless ($quiet);
$folder  = $import->addChild({
	title=>"Commerce/SelectShippingMethod",
	menuTitle=>"Commerce/SelectShippingMethod",
	url=>"Commerce/SelectShippingMethod",
	className=>"WebGUI::Asset::Wobject::Folder"
	});
$folder->addChild({
	namespace=>'Commerce/SelectShippingMethod',
	title=>'Default Select Shipping Method Template',
	menuTitle=>'Default Select Shipping Method Template',
	url=>'Default Select Shipping Method Template',
	showInForms=>1,
	isEditable=>1,
	className=>"WebGUI::Asset::Template",
	template=>'<tmpl_if pluginsAvailable>
   <tmpl_var message><br>
    <tmpl_var formHeader>
       <table border="0" cellspacing="0" cellpadding="5">
    <tmpl_loop pluginLoop>
            <tr>
                        <td><tmpl_var formElement></td>
                     <td align="left"><tmpl_var name></td>
           </tr>
       </tmpl_loop>
        </table>
    <tmpl_var formSubmit>
    <tmpl_var formFooter>
<tmpl_else>
 <tmpl_var noPluginsMessage>
</tmpl_if>'}, 'PBtmplCSSM000000000001');

#--------------------------------------------
print "\tAdding default shopping cart template\n" unless ($quiet);
my $folder = $import->addChild({
	title=>"Commerce/ViewShoppingCart",
	menuTitle=>"Commerce/ViewShoppingCart",
	url=>"Commerce/ViewShoppingCart",
	className=>"WebGUI::Asset::Wobject::Folder"
	});
$folder->addChild({
	namespace=>'Commerce/ViewShoppingCart',
	title=>'Default Shopping Cart Template',
	menuTitle=>'Default Shopping Cart Template',
	url=>'Default ShoppingCart Template',
	showInForms=>1,
	isEditable=>1,
	className=>"WebGUI::Asset::Template",
	template=>'<tmpl_if cartEmpty>
<tmpl_var cartEmpty.message>
<tmpl_else>

<tmpl_var updateForm.header>
<table>	
	<tr align="left">
		<th></th>
		<th style="border-bottom: 2px solid black">Product</th>
		<th style="border-bottom: 2px solid black">Quantity</th>
		<th style="border-bottom: 2px solid black">Price</th>
	</tr>

	<tmpl_if normalItems>
	</tmpl_if>

	<tmpl_loop normalItemsLoop>
	<tr>
		<td><tmpl_var deleteIcon></td>
		<td align="left"><tmpl_var name></td>
		<td align="center"><tmpl_var quantity.form></td>
		<td align="right"><tmpl_var totalPrice></td>
	</tr>
	</tmpl_loop>

	<tmpl_loop recurringItemsLoop>
	<tr>
		<td><tmpl_var deleteIcon></td>
		<td align="left"><tmpl_var name></td>
		<td align="center"><tmpl_var quantity.form></td>
		<td align="right"><tmpl_var totalPrice></td>
	</tr>
</tmpl_loop>
	<tr style="border-top: 1px solid black">
		<td></td>
		<td style="border-top: 1px solid black">&nbsp;</td>
		<td align="right" style="border-top: 1px solid black"><b>Total</b></td>
		<td align="right" colspan="3" style="border-top: 1px solid black"><b><tmpl_var total></b></td>
	</tr>

</table>

<tmpl_var updateForm.button>
<tmpl_var updateForm.footer>

<tmpl_var checkoutForm.header>
<tmpl_var checkoutForm.button>
<tmpl_var checkoutForm.footer> 

</tmpl_if>' },'PBtmplVSC0000000000001');


#--------------------------------------------
print "\tAdding several settings\n" unless ($quiet);
WebGUI::SQL->write("insert into settings values ('commerceSelectShippingMethodTemplateId', 'PBtmplCSSM000000000001')");
WebGUI::SQL->write("insert into settings values ('commerceViewShoppingCartTemplateId', 'PBtmplVSC0000000000001')");


#--------------------------------------------
print "\tAdding product managers group\n" unless ($quiet);
WebGUI::SQL->write("insert into groups (groupId, groupName, description) values (14, 'Product Managers', 'The group that is allowed to edit, delete and create products.')");


WebGUI::Session::close();

