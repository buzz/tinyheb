#!/usr/bin/perl -w

# legt neue Tabelle Stammdaten an
# alle Stammdaten der Frau

# T. Baum
# 16.12.03

use strict;
use DBI;
use lib "../";


use Heb;

my $h = new Heb;
my $dbh = Heb->connect;

# fehler beim verbinden abfangen
die $DBI::errstr unless $dbh;

# neue Tabelle anlegen
$dbh->do("CREATE TABLE Parms (" .
	 "ID SMALLINT UNSIGNED NOT NULL,".
	 "NAME CHAR(20),".
	 "VALUE CHAR(100)," .
	 "BESCHREIBUNG CHAR(100) );") or die $dbh->errstr();

$dbh->disconnect();
