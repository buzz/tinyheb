#!/usr/bin/perl -w
#-wT
#-d:ptkdb
#-d:DProf  

# Einspielen von  Schl�sseldateien in tinyHeb Datenbank

# $Id: key_ein.pl,v 1.3 2007-07-27 18:55:15 baum Exp $
# Tag $Name: not supported by cvs2svn $

# Copyright (C) 2007 Thomas Baum <thomas.baum@arcor.de>
# Thomas Baum, 42719 Solingen, Germany

# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.

use strict;
use CGI;
use CGI::Carp qw(fatalsToBrowser);
use Date::Calc qw(Today);

use lib "../";
use Heb;

my $q = new CGI;
my $h = new Heb;

my $TODAY = sprintf "%4.4u-%2.2u-%2.2u",Today();

my $datei = $q->param('datei') || '';
my $update = $q->param('update') || '';

my $abschicken = $q->param('abschicken');
my $hint='';


if (defined($abschicken)) {
  key_save();
}



print $q->header ( -type => "text/html", -expires => "-1d");

print '<head>';
print '<title>Schl�sseldatei einspielen</title>';
print '<script language="javascript" src="../Heb.js"></script>';
print '<link href="../Heb.css" rel="stylesheet" type="text/css">';
print '</head>';
print '<html>';
print '<body>';
# kommandozeilen programm key.pl aufrufen
if (!(-d "/tmp/wwwrun/keys")) {
  mkdir "/tmp/wwwrun" if (!(-d "/tmp"));
  mkdir "/tmp/wwwrun/keys";
}

if ($^O =~ /MSWin32/) {
  open KEY,"key.pl $update -t -p /tmp/wwwrun/ -o /tmp/wwwrun/keys/ -f key.dat |" or die "konnte Programm key.pl nicht starten\n";
} else {
  open KEY,"./key.pl $update -t -p /tmp/wwwrun/ -o /tmp/wwwrun/keys/ -f key.dat |" or die "konnte Programm key.pl nicht starten\n";
}

while (my $line=<KEY>) {
  print $line;
}
unlink ("/tmp/wwwrun/key.dat");
print "</body>";
print "</html>";


sub key_save {
  # speichert die Schl�sseldatei in tempor�rer Datei ab
  my $fh = $q->upload('datei');
  if ($datei eq '') {
    $hint='keine Datei angegeben, es wurden keine Schl�ssel eingespielt\n';
    return;
  }
  if (!(-d "/tmp/wwwrun")) {
    mkdir "/tmp" if (!(-d "/tmp"));
    mkdir "/tmp/wwwrun";
  }
  unlink('/tmp/wwwrun/key.dat');
  my $fd=open OUTPUT,">/tmp/wwwrun/key.dat";
  unless(defined($fd)) {
    $hint='konnte Schl�sseldatei nicht in Zwischendatei ablegen, nichts verarbeitet\n';
    return;
  }
  binmode $fh;
  binmode OUTPUT;
  while (my $line=<$fh>) {
    print OUTPUT $line;
  }
  close OUTPUT;
}
