insert into webguiVersion values ('6.3.0','upgrade',unix_timestamp());

delete from template where templateId='tinymce' and namespace='richEditor';
INSERT INTO template VALUES ('tinymce','TinyMCE','^JavaScript(\"<tmpl_var session.config.extrasURL>/tinymce/jscripts/tiny_mce/tiny_mce.js\");\r\n<script language=\"javascript\" type=\"text/javascript\">\r\n	  tinyMCE.init({\r\n    theme : \"advanced\",\r\n    mode : \"specific_textareas\",\r\n    plugins : \"collateral,emotions,insertImage,iespell,pagetree\",\r\n    theme_advanced_buttons2_add : \"insertImage,pagetree,collateral\",     \r\n    theme_advanced_buttons3_add : \"emotions,iespell\"     \r\n  });\r\n</script>\r\n\r\n<tmpl_var textarea>','richEditor',1,1);
delete from template where templateId='1' and namespace='richEditor/pagetree';
INSERT INTO template VALUES ('1','Rich Editor Page Tree','<html>\r\n\r\n<script language=\"javascript\" src=\"<tmpl_var session.config.extrasURL>/tinymce/jscripts/tiny_mce/tiny_mce_popup.js\"></script>\r\n\r\n<script language=\"javascript\">\r\n\r\nfunction setLink(page) {\r\n    document.getElementById(\"url\").value=\"^\" + \"/\" + \";\" + page;\r\n}\r\n\r\nfunction createLink() {\r\n    if (window.opener) {        \r\n        if (document.getElementById(\"url\").value == \"\") {\r\n           alert(\"You must enter a link url\");\r\n           document.getElementById(\"url\").focus();\r\n        }\r\n\r\ntinyMCE.insertLink(document.getElementById(\"url\").value,document.getElementById(\"target\").value);\r\n     window.close();\r\n    }\r\n}\r\n\r\n</script>\r\n\r\n<body>\r\n\r\n<fieldset>\r\n<legend>Insert/Edit Link</legend>\r\n\r\n  <fieldset>\r\n  <legend>Link Settings</legend>\r\n	<form name=\"linkchooser\">\r\n	<table border=\"0\">\r\n    <tr>\r\n    	<td>Link URL:</td>\r\n    	<td><input id=\"url\" name=\"url\" type=\"text value=\"\" style=\"width: 200px\"></td>\r\n    </tr>\r\n    <tr>\r\n        <td>Link Target:</td>\r\n        <td><select id=\"target\" name=\"target\" style=\"width: 200px\">\r\n                <option value=\"_self\">Open link in same window</option>\r\n                <option value=\"_blank\">Open link in new window</option>\r\n             </select>\r\n	    </td>\r\n    </tr>\r\n    <tr><td colspan=\"2\">&nbsp;</td></tr>\r\n	<tr>\r\n	   	<td colspan=\"2\" align=\"right\"><input type=\"button\" value=\"Cancel\" onClick=\"window.close()\"><input type=\"button\" value=\"Create Link\" onClick=\"createLink()\"></td>\r\n	</tr>\r\n	</table>\r\n	</form>\r\n	\r\n\r\n  </fieldset>  \r\n<br>\r\n\r\n\r\n  <fieldset>\r\n  <legend>Available Page Tree</legend>\r\n\r\n<tmpl_loop page_loop>\r\n  <tmpl_var indent><a href=\"#\" onClick=\"setLink(\'<tmpl_var url>\')\"><tmpl_var title></a><br />\r\n</tmpl_loop>\r\n\r\n </fieldset>\r\n  \r\n</fieldset>\r\n</body>\r\n</html>','richEditor/pagetree',1,1);
UPDATE template set template = '<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.01 Transitional//EN\">\r\n		<html>\r\n		<head>\r\n			<title><tmpl_var session.page.title> - <tmpl_var session.setting.companyName></title>\r\n			<tmpl_var head.tags>\r\n		<style type=\"text/css\">\r\nTD { font: 8pt \'MS Shell Dlg\', Helvetica, sans-serif; }\r\nTD.delete { font: italic 7pt \'MS Shell Dlg\', Helvetica, sans-serif; }\r\nTD.label { font: 8pt \'MS Shell Dlg\', Helvetica, sans-serif; background-color: #c0c0c0; }\r\nTD.none { font: italic 12pt \'MS Shell Dlg\', Helvetica, sans-serif; }\r\n\r\n</style>\r\n\r\n		</head>\r\n		<script language=\"javascript\">\r\n</script>\r\n<script language=\"javascript\">\r\n\r\nfunction actionComplete(action, path, error, info) {\r\n\r\n    if (window.parent && window.parent.resetForm) {\r\n        window.parent.resetForm();\r\n    }\r\n\r\n}\r\n</script>\r\n\r\n<script language=\"javascript\">\r\nfunction deleteCollateral(options) {\r\n   var lister = window.parent.document.getElementById(\"lister\");\r\n\r\n   if(lister && confirm(\"Are you sure you want to delete this item ?\"))\r\n      lister.src=\'^/;?op=htmlAreaDelete&\' + options;\r\n}\r\n</script>\r\n</head>\r\n<body leftmargin=\"0\" topmargin=\"0\" marginwidth=\"0\" marginheight=\"0\">\r\n\r\n			<tmpl_var body.content>\r\n		\r\n</body>\r\n		</html>\r\n		' where templateId = '10' and namespace='style';
delete from userProfileField where fieldName='richEditor';
INSERT INTO userProfileField VALUES ('richEditor','WebGUI::International::get(496)',1,0,'selectList','{5=>WebGUI::International::get(880),\r\nnone=>WebGUI::International::get(881),\r\n\'tinymce\'=>WebGUI::International::get(\"tinymce\")\n}','[\'tinymce\']',11,'4',0,1);
update userProfileData set fieldData='tinyMCE' where fieldName='richEditor';
UPDATE template set template = '<html>\r\n\r\n<script language=\"javascript\" src=\"<tmpl_var session.config.extrasURL>/tinymce/jscripts/tiny_mce/tiny_mce_popup.js\"></script>\r\n\r\n<script language=\"javascript\">\r\n\r\nfunction setLink(page) {\r\n document.getElementById(\"url\").value=\"^/;\" + page;\r\n}\r\n\r\nfunction createLink() {\r\n if (window.opener) { \r\n if (document.getElementById(\"url\").value == \"\") {\r\n alert(\"You must enter a link url\");\r\n document.getElementById(\"url\").focus();\r\n }\r\n\r\ntinyMCE.insertLink(document.getElementById(\"url\").value,document.getElementById(\"target\").value);\r\n window.close();\r\n }\r\n}\r\n\r\n</script>\r\n\r\n<body>\r\n\r\n<fieldset>\r\n<legend>Insert/Edit Link</legend>\r\n\r\n <fieldset>\r\n <legend>Link Settings</legend>\r\n <form name=\"linkchooser\">\r\n <table border=\"0\">\r\n <tr>\r\n <td>Link URL:</td>\r\n <td><input id=\"url\" name=\"url\" type=\"text value=\"\" style=\"width: 200px\"></td>\r\n </tr>\r\n <tr>\r\n <td>Link Target:</td>\r\n <td><select id=\"target\" name=\"target\" style=\"width: 200px\">\r\n <option value=\"_self\">Open link in same window</option>\r\n <option value=\"_blank\">Open link in new window</option>\r\n </select>\r\n </td>\r\n </tr>\r\n <tr><td colspan=\"2\">&nbsp;</td></tr>\r\n <tr>\r\n <td colspan=\"2\" align=\"right\"><input type=\"button\" value=\"Cancel\" onClick=\"window.close()\"><input type=\"button\" value=\"Create Link\" onClick=\"createLink()\"></td>\r\n </tr>\r\n </table>\r\n </form>\r\n \r\n\r\n </fieldset> \r\n<br>\r\n\r\n\r\n <fieldset>\r\n <legend>Available Page Tree</legend>\r\n<div id=\"pagetree\" style=\"overflow: auto; height: 280; width: 441\">\r\n<tmpl_loop page_loop>\r\n <tmpl_var indent><a href=\"#\" onClick=\"setLink(\'<tmpl_var url>\')\"><tmpl_var title></a><br />\r\n</tmpl_loop>\r\n</div>\r\n </fieldset>\r\n \r\n</fieldset>\r\n</body>\r\n</html>' where namespace='richEditor/pagetree' && templateId = '1';

INSERT INTO template VALUES ('adminConsole','Admin Console','<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Strict//EN\"\r\n        \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd\">\r\n<html xmlns=\"http://www.w3.org/1999/xhtml\">\r\n<head>\r\n        <title>WebGUI <tmpl_var session.webgui.version>-<tmpl_var session.webgui.status> Admin Console</title>\r\n        <tmpl_var head.tags> \r\n</head>\r\n<body>\r\n<tmpl_var body.content>\r\n</body>\r\n</html>\r\n','style',1,0);
INSERT INTO template VALUES ('1','Admin Console','^StyleSheet(^Extras;/adminConsole/adminConsole.css);\r\n^JavaScript(^Extras;/adminConsole/adminConsole.js);\r\n\r\n<div id=\"application_help\">\r\n  <tmpl_if help.url>\r\n    <a href=\"<tmpl_var help.url>\" target=\"_blank\"><img src=\"^Extras;/adminConsole/help-small.gif\" alt=\"?\" border=\"0\" /></a>\r\n  </tmpl_if>\r\n</div>\r\n<div id=\"application_icon\">\r\n    <img src=\"<tmpl_var application.icon>\" border=\"0\" title=\"<tmpl_var application.title>\" alt=\"<tmpl_var application.title>\" />\r\n</div>\r\n<div id=\"console_icon\">\r\n     <img src=\"<tmpl_var console.icon>\" border=\"0\" title=\"<tmpl_var console.title>\" alt=\"<tmpl_var console.title>\" />\r\n</div>\r\n<div id=\"application_title\">\r\n       <tmpl_var application.title>\r\n</div>\r\n<div id=\"console_title\">\r\n       <tmpl_var console.title>\r\n</div>\r\n<div id=\"application_workarea\">\r\n       <tmpl_var application.workArea>\r\n</div>\r\n<div id=\"console_workarea\">\r\n        <div class=\"adminConsoleSpacer\">\r\n            &nbsp;\r\n        </div>\r\n        <tmpl_loop application_loop>\r\n                <tmpl_if canUse>\r\n                     <div class=\"adminConsoleApplication\">\r\n                           <a href=\"<tmpl_var url>\"><img src=\"<tmpl_var icon>\" border=\"0\" title=\"<tmpl_var title>\" alt=\"<tmpl_var title>\" /></a><br />\r\n                           <a href=\"<tmpl_var url>\"><tmpl_var title></a>\r\n                     </div>\r\n               </tmpl_if>\r\n       </tmpl_loop>\r\n        <div class=\"adminConsoleSpacer\">\r\n            &nbsp;\r\n        </div>\r\n</div>\r\n<div class=\"adminConsoleMenu\">\r\n        <div id=\"adminConsoleMainMenu\" class=\"adminConsoleMainMenu\">\r\n                <div id=\"console_toggle_on\">\r\n                        <a href=\"#\" onClick=\"toggleAdminConsole()\"><tmpl_var toggle.on.label></a><br />\r\n                </div>\r\n                <div id=\"console_toggle_off\">\r\n                        <a href=\"#\" onClick=\"toggleAdminConsole()\"><tmpl_var toggle.off.label></a><br />\r\n                </div>\r\n        </div>\r\n        <div id=\"adminConsoleApplicationSubmenu\"  class=\"adminConsoleApplicationSubmenu\">\r\n              <tmpl_loop submenu_loop>\r\n                        <a href=\"<tmpl_var url>\"><tmpl_var label></a><br />\r\n              </tmpl_loop>\r\n        </div>\r\n        <div id=\"adminConsoleUtilityMenu\" class=\"adminConsoleUtilityMenu\">\r\n                <a href=\"^\;\"><tmpl_var backtosite.label></a><br />\r\n                ^AdminToggle;<br />\r\n                ^LoginToggle;<br />\r\n        </div>\r\n</div>\r\n<script lang=\"JavaScript\">\r\n  initAdminConsole(<tmpl_if application.title>true<tmpl_else>false</tmpl_if>,<tmpl_if submenu_loop>true<tmpl_else>false</tmpl_if>);\r\n</script>\r\n','AdminConsole',1,1);
delete from settings where name='adminStyleId';
delete from settings where name='useAdminStyle';


ALTER TABLE SQLReport CHANGE preprocessMacros preprocessMacros1 INT DEFAULT 0;
ALTER TABLE SQLReport CHANGE dbQuery dbQuery1 TEXT;
ALTER TABLE SQLReport CHANGE databaseLinkId  databaseLinkId1 varchar(22) DEFAULT NULL;
ALTER TABLE SQLReport ADD placeholderParams1 TEXT;

ALTER TABLE SQLReport ADD preprocessMacros2 INT DEFAULT 0;
ALTER TABLE SQLReport ADD dbQuery2 TEXT;
ALTER TABLE SQLReport ADD placeholderParams2 TEXT;
ALTER TABLE SQLReport ADD databaseLinkId2 VARCHAR(22);

ALTER TABLE SQLReport ADD preprocessMacros3 INT DEFAULT 0;
ALTER TABLE SQLReport ADD dbQuery3 TEXT;
ALTER TABLE SQLReport ADD placeholderParams3 TEXT;
ALTER TABLE SQLReport ADD databaseLinkId3 VARCHAR(22);

ALTER TABLE SQLReport ADD preprocessMacros4 INT DEFAULT 0;
ALTER TABLE SQLReport ADD dbQuery4 TEXT;
ALTER TABLE SQLReport ADD placeholderParams4 TEXT;
ALTER TABLE SQLReport ADD databaseLinkId4 VARCHAR(22);

ALTER TABLE SQLReport ADD preprocessMacros5 INT DEFAULT 0;
ALTER TABLE SQLReport ADD dbQuery5 TEXT;
ALTER TABLE SQLReport ADD placeholderParams5 TEXT;
ALTER TABLE SQLReport ADD databaseLinkId5 VARCHAR(22);

UPDATE template set template = '<tmpl_if displayTitle>\r\n    <h1><tmpl_var title></h1>\r\n</tmpl_if>\r\n\r\n<tmpl_if description>\r\n    <tmpl_var description><p />\r\n</tmpl_if>\r\n\r\n<tmpl_if debugMode>\r\n	<ul>\r\n	<tmpl_loop debug_loop>\r\n		<li><tmpl_var debug.output></li>\r\n	</tmpl_loop>\r\n	</ul>\r\n</tmpl_if>\r\n\r\n<table width=\"100%\" cellspacing=0 cellpadding=0 style=\"border: 1px solid black;\">\r\n<tr>\r\n   <tmpl_loop columns_loop>\r\n	<td class=\"tableHeader\"><tmpl_var column.name></td>\r\n   </tmpl_loop>\r\n</tr>\r\n\r\n<tmpl_loop rows_loop>\r\n   <tr>\r\n   <tmpl_loop row.field_loop>\r\n	<td class=\"tableData\"><tmpl_var field.value></td>\r\n   </tmpl_loop>\r\n   </tr>\r\n   <!-- Handle nested query2 -->\r\n   <tmpl_if hasNest>\r\n	<tr>\r\n	<td colspan=\"<tmpl_var columns.count>\">\r\n	<table width=\"100%\" cellspacing=0 cellpadding=0>\r\n	<tr>\r\n	<td width=\"20\">\r\n	   &nbsp;\r\n	</td>\r\n	<td>\r\n	   <table width=\"100%\" cellspacing=0 cellpadding=0 style=\"border: 1px solid black;\">\r\n	   <tr>\r\n	   <tmpl_loop query2.columns_loop>\r\n		<td class=\"tableHeader\"><tmpl_var column.name></td>\r\n	   </tmpl_loop>\r\n	   </tr>\r\n	   <tmpl_loop query2.rows_loop>\r\n	   <tr>\r\n	   <tmpl_loop query2.row.field_loop>\r\n		<td class=\"tableData\"><tmpl_var field.value></td>\r\n	   </tmpl_loop>\r\n	   </tr>\r\n	   <!-- Handle nested query3 -->\r\n	   <tmpl_if query2.hasNest>\r\n		<tr>\r\n		<td colspan=\"<tmpl_var query2.columns.count>\">\r\n		<table width=\"100%\" cellspacing=0 cellpadding=0>\r\n		<tr>\r\n		<td width=\"20\">\r\n		   &nbsp;\r\n		</td>\r\n		<td>\r\n		   <table width=\"100%\" cellspacing=0 cellpadding=0 style=\"border: 1px solid black;\">\r\n		   <tr>\r\n		   <tmpl_loop query3.columns_loop>\r\n			<td class=\"tableHeader\"><tmpl_var column.name></td>\r\n		   </tmpl_loop>\r\n		   </tr>\r\n		   <tmpl_loop query3.rows_loop>\r\n		   <tr>\r\n		   <tmpl_loop query3.row.field_loop>\r\n			<td class=\"tableData\"><tmpl_var field.value></td>\r\n		   </tmpl_loop>\r\n		   </tr>\r\n	   		<!-- Handle nested query4 -->\r\n			   <tmpl_if query3.hasNest>\r\n				<tr>\r\n				<td colspan=\"<tmpl_var query3.columns.count>\">\r\n				<table width=\"100%\" cellspacing=0 cellpadding=0>\r\n				<tr>\r\n				<td width=\"20\">\r\n				   &nbsp;\r\n				</td>\r\n				<td>\r\n				   <table width=\"100%\" cellspacing=0 cellpadding=0 style=\"border: 1px solid black;\">\r\n				   <tr>\r\n				   <tmpl_loop query4.columns_loop>\r\n					<td class=\"tableHeader\"><tmpl_var column.name></td>\r\n				   </tmpl_loop>\r\n				   </tr>\r\n				   <tmpl_loop query4.rows_loop>\r\n				   <tr>\r\n				   <tmpl_loop query4.row.field_loop>\r\n					<td class=\"tableData\"><tmpl_var field.value></td>\r\n				   </tmpl_loop>\r\n			   		<!-- Handle nested query5 -->\r\n					   <tmpl_if query4.hasNest>\r\n						<tr>\r\n						<td colspan=\"<tmpl_var query4.columns.count>\">\r\n						<table width=\"100%\" cellspacing=0 cellpadding=0>\r\n						<tr>\r\n						<td width=\"20\">\r\n						   &nbsp;\r\n						</td>\r\n						<td>\r\n						   <table width=\"100%\" cellspacing=0 cellpadding=0 style=\"border: 1px solid black;\">\r\n						   <tr>\r\n						   <tmpl_loop query5.columns_loop>\r\n							<td class=\"tableHeader\"><tmpl_var column.name></td>\r\n						   </tmpl_loop>\r\n						   </tr>\r\n						   <tmpl_loop query5.rows_loop>\r\n						   <tr>\r\n						   <tmpl_loop query5.row.field_loop>\r\n							<td class=\"tableData\"><tmpl_var field.value></td>\r\n						   </tmpl_loop>\r\n						   </tr>\r\n						   </tmpl_loop>\r\n						   </table>\r\n						</td>\r\n						</tr>\r\n						</table>\r\n					        </td>\r\n			        		</tr>\r\n					   </tmpl_if>\r\n				   </tr>\r\n				   </tmpl_loop>\r\n				   </table>\r\n				</td>\r\n				</tr>\r\n				</table>\r\n			        </td>\r\n			        </tr>\r\n			   </tmpl_if>\r\n		   </tmpl_loop>\r\n		   </table>\r\n		</td>\r\n		</tr>\r\n		</table>\r\n	        </td>\r\n	        </tr>\r\n	   </tmpl_if>\r\n	   </tmpl_loop>\r\n	   </table>\r\n	</td>\r\n	</tr>\r\n	</table>\r\n   </td>\r\n</tr>\r\n</tmpl_if>\r\n</tmpl_loop>\r\n</table>\r\n\r\n<tmpl_if pagination.pageCount.isMultiple>\r\n  <div class=\"pagination\">\r\n    <tmpl_var pagination.previousPage>   <tmpl_var pagination.pageList.upTo20>  <tmpl_var pagination.nextPage>\r\n  </div>\r\n</tmpl_if>' where templateId="1" and namespace="SQLReport";

create table asset (
	assetId varchar(22) not null primary key,
	parentId varchar(22) not null,
	lineage varchar(255) not null,
	state varchar(35) not null,
	className varchar(255) not null,
	boundToId varchar(22),
	title varchar(255) not null default 'untitled',
	menuTitle varchar(255) not null default 'untitled',
	url varchar(255) not null,
	startDate bigint not null default 997995720,
	endDate bigint not null default 9223372036854775807,
	ownerUserId varchar(22) not null,
	groupIdView varchar(22) not null,
	groupIdEdit varchar(22) not null,
	synopsis text,
	newWindow int not null default 0,
	isHidden int not null default 0,
	isSystem int not null default 0,
	encryptPage int not null default 0,
	unique index (lineage asc),
	unique index (url),
	index (parentId)
);

insert into asset (assetId, parentId, lineage, state, className, title, menuTitle, url, isSystem, ownerUserId, groupIdView, groupIdEdit) values ('theroot', 'infinity', '000001','published','WebGUI::Asset','Root','Root','root',1,'3','3','3');

create table assetHistory (
	assetId varchar(22) not null,
	userId varchar(22) not null,
	dateStamp bigint not null default 0,
	actionTaken varchar(255) not null
);

create table redirect (
	assetId varchar(22) not null primary key,
	redirectUrl text
);

create table layout (
	assetId varchar(22) not null primary key, 
	styleTemplateId varchar(22) not null, 
	layoutTemplateId varchar(22) not null, 
	printableStyleTemplateId varchar(22) not null
);

INSERT INTO settings VALUES ('commerceCheckoutCanceledTemplateId','1');
INSERT INTO settings VALUES ('commerceConfirmCheckoutTemplateId','1');
INSERT INTO settings VALUES ('commercePaymentPlugin','PayFlowPro');
INSERT INTO settings VALUES ('commerceSendDailyReportTo','');
INSERT INTO settings VALUES ('commerceTransactionErrorTemplateId','1');
INSERT INTO template VALUES ('1','Subscription code redemption','<tmpl_if batchDescription>\r\nBatch: <tmpl_var batchDescription>\r\n</tmpl_if>\r\n\r\n<tmpl_var message><br>\r\n<tmpl_var codeForm>','Operation/RedeemSubscription',1,1);
INSERT INTO template VALUES ('1','Subscriptionitem default template','<h2><tmpl_var name></h2>\r\n<tmpl_var description><br>\r\n<br>\r\n<br>\r\n$ <tmpl_var price><br>\r\n<a href=\"<tmpl_var url>\">Subscribe now</a><br>','Macro/SubscriptionItem',1,1);
INSERT INTO template VALUES ('1','Default transaction error template','<table border=\"1\" cellpadding=\"5\" cellspacing=\"0\">\r\n  <tr>\r\n    <th>Transaction description</th>\r\n    <th>Price</th>\r\n    <th>Status</th>\r\n    <th>Error</th>\r\n  </tr>\r\n<tmpl_loop resultLoop>\r\n  <tr>\r\n    <td align=\"left\"><tmpl_var purchaseDescription></td>\r\n    <td align=\"right\"><tmpl_var purchaseAmount></td>\r\n    <td><tmpl_var status></td>\r\n    <td align=\"left\"><tmpl_var error> (<tmpl_var errorCode>)</td>\r\n  </tr>\r\n</tmpl_loop>\r\n</table><br>\r\n<br>\r\n\r\n<tmpl_var statusExplanation>','Commerce/TransactionError',1,1);
INSERT INTO template VALUES ('1','Default checkout confirmation template','<tmpl_var title><br>\r\n<br>\r\n<ul>\r\n<tmpl_loop errorLoop>\r\n<li><tmpl_var message></li>\r\n</tmpl_loop>\r\n</ul>\r\n\r\n<tmpl_if recurringItems>\r\n<table border=\"0\" cellpadding=\"5\">\r\n<tmpl_loop recurringLoop>\r\n  <tr>\r\n    <td align=\"left\"><b>Subscription \"<tmpl_var name>\"</b></td>\r\n    <td> : </td>\r\n    <td align=\"left\">$ <tmpl_var price> every <tmpl_var period></td>\r\n  </tr>\r\n</tmpl_loop>\r\n</table><br>\r\n<br>\r\n</tmpl_if>\r\n<tmpl_var form>','Commerce/ConfirmCheckout',1,1);
INSERT INTO template VALUES ('1','Default view purchase history template','<table border=\"0\">\r\n<tmpl_loop purchaseHistoryLoop>\r\n	<tr>\r\n		<td><b><tmpl_var initDate></b></td>\r\n		<td><b><tmpl_var completionDate></b></td>\r\n		<td align=\"right\"><b>$ <tmpl_var amount></b></td>\r\n		<td><b><tmpl_var status></b></td>\r\n		<td><tmpl_if canCancel><a href=\"<tmpl_var cancelUrl>\">Cancel</a></tmpl_if></td>\r\n	</tr>\r\n	<tmpl_loop itemLoop>\r\n	<tr>\r\n		<td \"align=right\"><tmpl_var quantity> x </td>\r\n		<td \"align=left\"><tmpl_var itemName></td>\r\n		<td \"align=right\">$ <tmpl_var amount></td>\r\n	</tr>\r\n	</tmpl_loop>\r\n</tmpl_loop>\r\n</table>','Commerce/ViewPurchaseHistory',1,1);
INSERT INTO template VALUES ('1','Default cancel checkout template','<tmpl_var message>','Commerce/CheckoutCanceled',1,1);
CREATE TABLE shoppingCart (
  sessionId varchar(22) NOT NULL default '',
  itemId varchar(64) NOT NULL default '',
  itemType varchar(40) NOT NULL default '',
  quantity int(4) NOT NULL default '0',
  PRIMARY KEY  (sessionId,itemId,itemType)
) TYPE=MyISAM;
CREATE TABLE subscription (
  subscriptionId varchar(22) NOT NULL default '',
  name varchar(128) default NULL,
  price float default '0',
  description mediumtext,
  subscriptionGroup varchar(22) NOT NULL default '',
  duration varchar(12) NOT NULL default 'Monthly',
  executeOnSubscription varchar(128) default NULL,
  karma int(4) default '0',
  deleted int(1) default '0',
  PRIMARY KEY  (subscriptionId)
) TYPE=MyISAM;
CREATE TABLE subscriptionCodeBatch (
  batchId varchar(22) NOT NULL default '',
  name varchar(128) default NULL,
  description mediumtext NOT NULL,
  subscriptionId varchar(22) NOT NULL default '',
  PRIMARY KEY  (batchId)
) TYPE=MyISAM;
CREATE TABLE subscriptionCode (
  batchId varchar(22) NOT NULL default '',
  code varchar(64) NOT NULL default '',
  status varchar(10) NOT NULL default 'Unused',
  dateCreated int(11) NOT NULL default '0',
  dateUsed int(11) NOT NULL default '0',
  expires int(11) NOT NULL default '0',
  usedBy varchar(22) NOT NULL default '0',
  PRIMARY KEY  (code)
) TYPE=MyISAM;
CREATE TABLE subscriptionCodeSubscriptions (
  code varchar(64) NOT NULL default '',
  subscriptionId varchar(22) NOT NULL default '',
  UNIQUE KEY code (code,subscriptionId)
) TYPE=MyISAM;
CREATE TABLE transaction (
  transactionId varchar(22) NOT NULL default '',
  userId varchar(22) NOT NULL default '',
  amount float NOT NULL default '0',
  gatewayId varchar(128) default NULL,
  gateway varchar(64) NOT NULL default '',
  recurring tinyint(1) NOT NULL default '0',
  initDate int(11) NOT NULL default '0',
  completionDate int(11) default '0',
  status varchar(10) NOT NULL default 'Pending',
  lastPayedTerm int(6) NOT NULL default '0',
  PRIMARY KEY  (transactionId)
) TYPE=MyISAM;
CREATE TABLE transactionItem (
  transactionId varchar(22) NOT NULL default '',
  itemName varchar(64) NOT NULL default '',
  amount float NOT NULL default '0',
  quantity int(4) NOT NULL default '0',
  itemId varchar(64) NOT NULL default '',
  itemType varchar(40) NOT NULL default ''
) TYPE=MyISAM;
CREATE TABLE commerceSettings (
  fieldName varchar(64) NOT NULL default '',
  fieldValue varchar(255) NOT NULL default '',
  namespace varchar(64) NOT NULL default '',
  type varchar(10) NOT NULL default ''
) TYPE=MyISAM;

