#!/usr/bin/perl -w

# legt neue Tabelle Leistungsart an

use lib "../";
use strict;
use DBI;

use Heb;

my $dbh = Heb->connect;

# fehler beim verbinden abfangen
die $DBI::errstr unless $dbh;

# neue Tabelle anlegen
$dbh->do("CREATE TABLE Leistungsart (" .  
	 "ID SMALLINT UNSIGNED NOT NULL," .
	 "POSNR CHAR(5) NOT NULL," .
	 "BEZEICHNUNG TEXT NOT NULL," .
	 "LEISTUNGSTYP ENUM ('A','B','C','D','M','W') NOT NULL," .
	 "EINZELPREIS DECIMAL(6,2),".
	 "PROZENT DECIMAL (5,2)," .
	 "SONNTAG CHAR(5) DEFAULT NULL,".
	 "NACHT CHAR(5) DEFAULT NULL,".
	 "SAMSTAG CHAR(5) DEFAULT NULL,".
	 "FUERZEIT CHAR(5) DEFAULT 0,".
	 "DAUER TINYINT UNSIGNED NOT NULL DEFAULT 0,".
	 "ZWILLINGE CHAR(5) DEFAULT NULL,".
	 "ZWEITESMAL CHAR(5) DEFAULT NULL,".
	 "EINMALIG CHAR(5) DEFAULT NULL,".
	 "BEGRUENDUNGSPFLICHT ENUM ('j','n'),".
	 "ZUSATZGEBUEHREN1 CHAR(5) DEFAULT NULL,".
	 "ZUSATZGEBUEHREN2 CHAR(5) DEFAULT NULL,".
	 "ZUSATZGEBUEHREN3 CHAR(5) DEFAULT NULL,".
	 "ZUSATZGEBUEHREN4 CHAR(5) DEFAULT NULL,".
	 "GUELT_VON DATE NOT NULL DEFAULT '1990-01-01'," .
	 "GUELT_BIS DATE NOT NULL DEFAULT '9999-01-01'," .
	 "KBEZ CHAR(50), ".
	 "PRIMARY KEY (ID) );") or die $dbh->errstr();

$dbh->disconnect();
