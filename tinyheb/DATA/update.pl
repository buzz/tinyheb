#!/usr/bin/perl -w

# Verarbeiten der Datenbank�nderungen bei einem Programmupdate

# $Id: update.pl,v 1.3 2007-10-28 16:00:55 thomas_baum Exp $
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
use DBI;
use Getopt::Long;

my $dbh; # Verbindung zur Datenbank
my $user='root';
my $pass='';
my $root_pass='';
my $debug=0;

my $rpm=undef;

my $parms=GetOptions('rpm' => \$rpm);

write_LOG("Starte update ----------------------------");

# root passwort f�r db holen, wenn n�tig
$dbh = connect_db('root',$root_pass);
if (!defined($dbh) and ($DBI::err == 1044 || $DBI::err == 1045)) {
  write_LOG("Hole DB Passwort");
  print "Bitte Passwort fuer Datenbankadmin root angeben:";
  $root_pass=<STDIN>;
  chomp $root_pass;
  $dbh = connect_db('root',$root_pass);
  error("unbekanntes Problem aufgetreten $DBI::errstr\n") unless (defined($dbh));
  print "Fehler Text:",$DBI::errstr,"\n" if($DBI::errstr);
  print "Fehler Nummmer:",$DBI::err,"\n" if($DBI::err);
  print "State Nummmer:",$DBI::state,"\n" if($DBI::state);
  write_LOG("Habe mich mit root angemeldet $dbh");
}

write_LOG("oeffne update.sql");
open SQL, "update.sql" or error("konnte update Datei nicht �ffnen $!\n");

# alle Zeile der Update Datei Verarbeiten
LINE:while (my $line=<SQL>) {
  chomp $line;
  next LINE if ($line eq '' or $line =~ /^#/);
  my ($muser,$tag,$tabelle,$dep,$sql) = split '\t',$line;
  write_LOG("update.sql gelesen",$muser,$tag,$tabelle,$dep,$sql);
  if ($debug) {
    print "muser\t$muser\n";
    print "tag\t$tag\n";
    print "tabelle\t$tabelle\n";
    print "dep\t$dep\n";
    print "sql\t$sql\n";
  }
  do_update($sql) if (uc $tag eq 'UPDATE');
  do_insert($sql,$tabelle,$dep) if (uc $tag eq 'INSERT');
  do_create($sql,$tabelle) if (uc $tag eq 'CREATE');
  do_alter($sql,$tabelle,$dep) if (uc $tag eq 'ALTER');

}    


write_LOG("Beende update ----------------------------");

unless($rpm) {
  print "Update erfolgreich durchgef�hrt,\nBitte die ENTER Taste zum Beenden des Update druecken\n";
  my $eingabe=<STDIN>;
}

sub do_update {
  my ($sql)=@_;

  my $dbh=connect_db('wwwrun','');
  write_LOG("update",$dbh);
  error("unbekanntes Problem aufgetreten $DBI::errstr\n") unless (defined($dbh));

  $dbh->do($sql);
  error("unbekanntes Problem aufgetreten $DBI::errstr\n") if ($DBI::errstr);
  $dbh->disconnect();
}


sub do_insert {
  my ($sql,$tabelle,$dep)=@_;

  my $dbh=connect_db('wwwrun','');
  write_LOG("insert",$dbh,$sql,$tabelle,$dep);
  error("unbekanntes Problem aufgetreten $DBI::errstr\n") unless (defined($dbh));

  my $sdep = $dbh->prepare("select * from $tabelle where $dep;");
  error("unbekanntes Problem aufgetreten $DBI::errstr\n") unless (defined($sdep));

  
  my $erg=$sdep->execute() or error($dbh->errstr());
  write_LOG("insert dep $erg $sdep");
  if (!defined($erg) or $erg == 0) {
    my ($name,$id)=get_parm($tabelle,$dbh);
    $dbh->do($sql);
    error("unbekanntes Problem aufgetreten $DBI::errstr\n") if ($DBI::errstr);
    # Hier muss noch update auf den Z�hler in Parms gemacht werden
    $id++;
    write_LOG("Parm update $id $name");
    parm_up($name,$id,$dbh);
    my $id_up=$dbh->do("update $tabelle set id=$id where id=9999;");
    error("unbekanntes Problem aufgetreten $DBI::errstr\n") unless (defined($id_up));
  }
  $sdep->finish;
  $dbh->disconnect();
}

sub do_create {
  my ($sql,$tabelle)=@_;

  my $dbh=connect_db('root',$root_pass);
  write_LOG("create",$dbh,$sql,$tabelle);
  error("unbekanntes Problem aufgetreten $DBI::errstr\n") unless (defined($dbh));

#  $dbh->do($sql) or die $dbh->errstr();
  $dbh->disconnect();
}


sub do_alter {
  my ($sql,$tabelle,$dep)=@_;

  my $dbh=connect_db('root',$root_pass);
  write_LOG("alter",$dbh,$sql,$tabelle,$dep);
  error("unbekanntes Problem aufgetreten $DBI::errstr\n") unless (defined($dbh));

  # alter durchf�hren
  my $erg=$dbh->do($sql);
  if (!defined($erg)) {
      write_LOG("alter fehler",$DBI::err,$DBI::errstr);
    if ($DBI::err == 1061 || $DBI::err == 1060) {
    # ok, mache nix, INDEX oder Spalte war schon da
    } else {
      error("unbekanntes Problem aufgetreten $DBI::errstr\n");
    }
  }

  $dbh->disconnect();
}


sub get_parm {
  my ($tabelle,$dbh)=@_;
  my $name='';
  $name = 'LEISTUNGSART_ID' if (uc $tabelle eq 'LEISTUNGSART');


  my $parm_such=$dbh->prepare("select VALUE from Parms ".
		"where NAME=?;")
    or error($dbh->errstr());

  $parm_such->execute($name) or error($dbh->errstr());

  my ($erg) = $parm_such->fetchrow_array();
  $parm_such->finish;
  return ($name,$erg);
}

sub parm_up {
  # update auf bestimmten Parameter
  
  my ($name,$value,$dbh) = @_;
  $dbh->prepare("update Parms set ".
		"VALUE=? where ".
		"NAME = ?;")->execute($value,$name)
    or error($dbh->errstr());
}



sub connect_db {
  my ($user,$pass) = @_;
  # verbindung zur Datenbank aufbauen
  $dbh = DBI->connect("DBI:mysql:database=Hebamme;host=localhost",$user,$pass,
                      {RaiseError => 1,
		       HandleError => \&fehler,
                       AutoCommit => 1 });
  return $dbh;
}

sub fehler {
  my @erg=@_;
  print "Fehlernummer ",$erg[1]->err,"\n" if $debug;
  print "STR ",$erg[1]->errstr,"\n" if $debug;

  write_LOG("DB Fehler",$erg[1]->err,$erg[1]->errstr);
  #  Keine Zugriffsberechtigung
  return 1 if ($erg[1]->err == 1044);

  #  Keine Zugriffsberechtigung mit Passwort
  return 1 if ($erg[1]->err == 1045);

  #  print "Datenbank ist nicht gestartet\n";
  # return 1 if ($erg[1]->err == 2002);

  # Doppelter Index
  return 1 if ($erg[1]->err == 1061);

  # Doppelter Spaltenname
  return 1 if ($erg[1]->err == 1060);

  return 1;
}


sub write_LOG {
  if(!open (LOG,">>update.log")) {
    print "FEHLER log Datei kann nicht geschrieben werden: $!\n";
    unless($rpm) {
      print "Bitte die ENTER Taste zum Beenden des Update druecken\n";
      my $eingabe=<STDIN>;
    }
    exit(1);
  }

  my @log = @_;
  my $print_log = join(':',@log);
  my $time = join(':',localtime);
  print LOG "LOG:$time\t$print_log\n";
  close (LOG);
};

sub error {
  my ($error)=@_;
  write_LOG($error);
  print "FEHLER $error\n";
  unless($rpm) {
    print "Bitte die ENTER Taste zum Beenden des Update druecken\n";
    my $eingabe=<STDIN>;
  }
  exit(1);
}