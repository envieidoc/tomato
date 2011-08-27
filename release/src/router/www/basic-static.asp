<!DOCTYPE HTML PUBLIC '-//W3C//DTD HTML 4.0//EN'>
<!--
	Tomato GUI
	Copyright (C) 2006-2010 Jonathan Zarate
	http://www.polarcloud.com/tomato/

	Enhancements by Teaman
	Copyright (C) 2011 Augusto Bott
	http://code.google.com/p/tomato-sdhc-vlan/

	For use with Tomato Firmware only.
	No part of this file may be used without permission.
-->
<html>
<head>
<meta http-equiv='content-type' content='text/html;charset=utf-8'>
<meta name='robots' content='noindex,nofollow'>
<title>[<% ident(); %>] Basic: Static DHCP</title>
<link rel='stylesheet' type='text/css' href='tomato.css'>
<% css(); %>
<script type='text/javascript' src='tomato.js'></script>

<!-- / / / -->
<style type='text/css'>
#bs-grid .co1,
#bs-grid .co2 {
	width: 120px;
}
#bs-grid .co3 {
	width: 80px;
	text-align: center;
}
#bs-grid .centered {
	text-align: center;
}
</style>

<script type='text/javascript' src='debug.js'></script>

<script type='text/javascript'>

//	<% nvram("lan_ipaddr,lan_netmask,dhcpd_static,dhcpd_startip,cstats_include"); %>

if (nvram.lan_ipaddr.match(/^(\d+\.\d+\.\d+)\.(\d+)$/)) ipp = RegExp.$1 + '.';
	else ipp = '?.?.?.';

autonum = aton(nvram.lan_ipaddr) & aton(nvram.lan_netmask);

var sg = new TomatoGrid();

sg.exist = function(f, v)
{
	var data = this.getAllData();
	for (var i = 0; i < data.length; ++i) {
		if (data[i][f] == v) return true;
	}
	return false;
}

sg.existMAC = function(mac)
{
	if (isMAC0(mac)) return false;
	return this.exist(0, mac) || this.exist(1, mac);
}

sg.existName = function(name)
{
	return this.exist(4, name);
}

sg.inStatic = function(n)
{
	return this.exist(2, n);
}

sg.dataToView = function(data) {
	var v = [];
	
	var s = data[0];
	if (!isMAC0(data[1])) s += '<br>' + data[1];
	v.push(s);

	v.push(escapeHTML('' + data[2]));
	v.push((data[3].toString() != '0') ? 'Enabled' : '');
	v.push(escapeHTML('' + data[4]));

	return v;
}

sg.dataToFieldValues = function (data) {
	return ([data[0],
			data[1],
			data[2],
			(data[3].toString() != '0') ? 'checked' : '',
			data[4]]);
}

sg.fieldValuesToData = function(row) {
	var f = fields.getAll(row);
	return ([f[0].value,
			f[1].value,
			f[2].value,
			f[3].checked ? '1' : '0',
			f[4].value]);
}

sg.sortCompare = function(a, b) {
	var da = a.getRowData();
	var db = b.getRowData();
	var r = 0;
	switch (this.sortColumn) {
	case 0:
		r = cmpText(da[0], db[0]);
		break;
	case 1:
		r = cmpIP(da[2], db[2]);
		break;
	}
	if (r == 0) r = cmpText(da[4], db[4]);
	return this.sortAscending ? r : -r;
}

sg.verifyFields = function(row, quiet)
{
	var f, s, i;

	f = fields.getAll(row);

	if (!v_macz(f[0], quiet)) return 0;
	if (!v_macz(f[1], quiet)) return 0;
	if (isMAC0(f[0].value)) {
		f[0].value = f[1].value;
		f[1].value = '00:00:00:00:00:00';
	}
	else if (f[0].value == f[1].value) {
		f[1].value = '00:00:00:00:00:00';
	}
	else if ((!isMAC0(f[1].value)) && (f[0].value > f[1].value)) {
		s = f[1].value;
		f[1].value = f[0].value;
		f[0].value = s;
	}
	for (i = 0; i < 2; ++i) {
		if (this.existMAC(f[i].value)) {
			ferror.set(f[i], 'Duplicate MAC address', quiet);
			return 0;
		}
	}	

	if (f[2].value.indexOf('.') == -1) {
		s = parseInt(f[2].value, 10)
		if (isNaN(s) || (s <= 0) || (s >= 255)) {
			ferror.set(f[2], 'Invalid IP address', quiet);
			return 0;
		}
		f[2].value = ipp + s;
	}

	if ((!isMAC0(f[0].value)) && (this.inStatic(f[2].value))) {
		ferror.set(f[2], 'Duplicate IP address', quiet);
		return 0;
	}

	if (!v_hostname(f[4], quiet, 5)) return 0;
	if (!v_nodelim(f[4], quiet, 'Hostname', 1)) return 0;
	s = f[4].value;
	if (s.length > 0) {
		if (this.existName(s)) {
			ferror.set(f[4], 'Duplicate name.', quiet);
			return 0;
		}
	}

	if (isMAC0(f[0].value)) {
		if (s == '') {
			s = 'Both MAC address and name fields must not be empty.';
			ferror.set(f[0], s, 1);
			ferror.set(f[4], s, quiet);
			return 0;
		}
	}

	return 1;
}

sg.resetNewEditor = function() {
	var f, c, n;

	f = fields.getAll(this.newEditor);
	ferror.clearAll(f);

	if ((c = cookie.get('addstatic')) != null) {
		cookie.set('addstatic', '', 0);
		c = c.split(',');
		if (c.length == 3) {
			f[0].value = c[0];
			f[1].value = '00:00:00:00:00:00';
			f[2].value = c[1];
			f[4].value = c[2];
			return;
		}
	}

	f[0].value = '00:00:00:00:00:00';
	f[1].value = '00:00:00:00:00:00';
	f[4].value = '';

	n = 10;
	do {
		if (--n < 0) {
			f[2].value = '';
			return;
		}
		autonum++;
	} while (((c = fixIP(ntoa(autonum), 1)) == null) || (c == nvram.lan_ipaddr) || (this.inStatic(c)));

	f[2].value = c;
}

sg.setup = function()
{
	this.init('bs-grid', 'sort', 140, [
		{ multi: [ { type: 'text', maxlen: 17 }, { type: 'text', maxlen: 17 } ] },
		{ type: 'text', maxlen: 15 },
		{ type: 'checkbox', prefix: '<div class="centered">', suffix: '</div>' },
		{ type: 'text', maxlen: 63 } ] );

	this.headerSet(['MAC Address', 'IP Address', 'IPTraffic', 'Hostname']);

	var ipt = nvram.cstats_include.split(',');
	var s = nvram.dhcpd_static.split('>');
	for (var i = 0; i < s.length; ++i) {
		var h = '0'
		var t = s[i].split('<');
		if (t.length == 3) {
			var d = t[0].split(',');
			var ip = (t[1].indexOf('.') == -1) ? (ipp + t[1]) : t[1];
			for (var j = 0; j < ipt.length; ++j) {
				if (ip == ipt[j]) {
					h = '1';
					break;
				}
			}
			this.insertData(-1, [d[0], (d.length >= 2) ? d[1] : '00:00:00:00:00:00',
				(t[1].indexOf('.') == -1) ? (ipp + t[1]) : t[1], h, t[2]]);
		}
	}
	this.sort(3);
	this.showNewEditor();
	this.resetNewEditor();
}

function save()
{
	if (sg.isEditing()) return;

	var data = sg.getAllData();
	var sdhcp = '';
	var ipt = '';
	var i;

	for (i = 0; i < data.length; ++i) {
		var d = data[i];
		sdhcp += d[0];
		if (!isMAC0(d[1])) sdhcp += ',' + d[1];
		sdhcp += '<' + d[2] + '<' + d[4] + '>';
		if (d[3] == '1') ipt += ((ipt.length > 0) ? ',' : '') + d[2];
	}

	var fom = E('_fom');
	fom.dhcpd_static.value = sdhcp;
	fom.cstats_include.value = ipt;

alert(ipt);

	form.submit(fom, 1);
}

function init()
{
	var c;
	if (((c = cookie.get('basic_static_notes_vis')) != null) && (c == '1')) {
		toggleVisibility("notes");
	}
	sg.recolor();
}

function toggleVisibility(whichone) {
	if(E('sesdiv' + whichone).style.display=='') {
		E('sesdiv' + whichone).style.display='none';
		E('sesdiv' + whichone + 'showhide').innerHTML='(Click here to show)';
		cookie.set('basic_static_' + whichone + '_vis', 0);
	} else {
		E('sesdiv' + whichone).style.display='';
		E('sesdiv' + whichone + 'showhide').innerHTML='(Click here to hide)';
		cookie.set('basic_static_' + whichone + '_vis', 1);
	}
}

</script>
</head>
<body onload='init()'>
<form id='_fom' method='post' action='tomato.cgi'>
<table id='container' cellspacing=0>
<tr><td colspan=2 id='header'>
	<div class='title'>Tomato</div>
	<div class='version'>Version <% version(); %></div>
</td></tr>
<tr id='body'><td id='navi'><script type='text/javascript'>navi()</script></td>
<td id='content'>
<div id='ident'><% ident(); %></div>

<!-- / / / -->

<input type='hidden' name='_nextpage' value='basic-static.asp'>
<input type='hidden' name='_service' value='dhcpd-restart,cstats-restart'>

<input type='hidden' name='dhcpd_static'>
<input type='hidden' name='cstats_include'>

<div class='section-title'>Static DHCP</div>
<div class='section'>
	<table class='tomato-grid' id='bs-grid'></table>
</div>

<div class='section-title'>Notes <small><i><a href='javascript:toggleVisibility("notes");'><span id='sesdivnotesshowhide'>(Click here to show)</span></a></i></small></div>
<div class='section' id='sesdivnotes' style='display:none'>
<ul>
<li><b>MAC Address</b> - Unique identifier associated to a network interface on this particular device.</li>
<li><b>IP Address</b> - Network address assigned to this device on the local network.</li>
<li><b>IPTraffic</b> - Keep track of bandwidth usage for this IP address.</li>
<li><b>Hostname</b> - Human-readable nickname/label assigned to this device on the network.</li>
</ul>
<small>
<ul>
<li><b>Other relevant notes/hints:</b>
<ul>
<li>To specify multiple hostnames for a device, separate them with spaces.</li>
</ul>
</ul>
</small>
</div>


<!-- / / / -->

</td></tr>
<tr><td id='footer' colspan=2>
	<span id='footer-msg'></span>
	<input type='button' value='Save' id='save-button' onclick='save()'>
	<input type='button' value='Cancel' id='cancel-button' onclick='javascript:reloadPage();'>
</td></tr>
</table>
</form>
<script type='text/javascript'>sg.setup();</script>
</body>
</html>
