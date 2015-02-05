# Package um Stammdaten zu verarbeiten

# $Id: Heb_stammdaten.pm,v 1.18 2010-03-13 17:40:09 thomas_baum Exp $
# Tag $Name: not supported by cvs2svn $

# Copyright (C) 2004 - 2010 Thomas Baum <thomas.baum@arcor.de>
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
# author: Thomas Baum

package Heb_stammdaten;

=head1 NAME

Heb_stammdaten - Package f�r tinyHeb um Stammdaten zu verarbeiten

my $d = new Heb_stammdaten;

=head1 DESCRIPTION

=cut

use strict;
use DBI;

use Heb;
my $h = new Heb;
my $debug = 0;
my $dbh=$h->connect; # Verbindung zur Datenbank
my $frau_such; # suchen von Frauen
my $stammdaten_werte; # suchen nach bestimmten Werten bei Frauen
$frau_such = $dbh->prepare("select ID,VORNAME,NACHNAME,".
			   "DATE_FORMAT(GEBURTSDATUM_FRAU,'%d.%m.%Y'),".
			   "DATE_FORMAT(GEBURTSDATUM_KIND,'%d.%m.%Y'),".
			   "PLZ,ORT,TEL,STRASSE,ANZ_KINDER,ENTFERNUNG, ".
			   "KRANKENVERSICHERUNGSNUMMER,".
			   "KRANKENVERSICHERUNGSNUMMER_GUELTIG,".
			   "VERSICHERTENSTATUS,".
			   "IK,".
			   "NAECHSTE_HEBAMME,".
			   "BEGRUENDUNG_NICHT_NAECHSTE_HEBAMME, ".
			   "KZETGT, ".
			   "TIME_FORMAT(GEBURTSZEIT_KIND,'%H:%i') ".
			   "PRIVAT_FAKTOR ".
			   "from Stammdaten where ".
			   "VORNAME like ? and ".
			   "NACHNAME like ? and ".
			   "GEBURTSDATUM_FRAU like ? and ".
			   "GEBURTSDATUM_KIND like ? and ".
			   "PLZ like ? and ".
			   "ORT like ? and ".
			   "STRASSE like ?;");

sub new {
  my($class) = @_;
  my $self = {};
  bless $self, ref $class || $class;
  return $self;
}

sub stammdaten_suchfrau {
  # Sucht nach Frauen in der Datenbank

  my $self=shift; # package Namen vom stack nehmen

  $frau_such->execute(@_) or die $dbh->errstr();

}


sub stammdaten_suchfrau_next {
  my @erg = $frau_such->fetchrow_array();
  for (my $i=0;$i < $#erg;$i++) {
    if (!defined($erg[$i])) {
      $erg[$i]='';
    }
  }
  return @erg;
}


sub stammdaten_ins {
  # f�gt neue Person in Datenbank ein

=head2 $s->stammdaten_ins(@stammdaten,$id_alt)
    
f�gt eine neue Frau in die Tabelle stammdaten ein. 

=over

=item Ist $id_alt nicht definiert oder 0, wird eine neue ID vergeben und der 
Datensatz eingef�gt.

=item Ist $id_alt definiert, wird der Datensatz unter dieser ID in die Datenbank
geschrieben.

=back

Die Felder m�ssen in folgender Reihenfolge �bergeben werden:

=over

=item Vorname, Nachname, Geburtsdatum der Frau, Strasse, PLZ,
Ort, Tel, Entfernung, Krankenversicherungsnummer,
Krankenversicherungsnummer G�ltigkeit, Versichertenstatus,
IK-Nummer Krankenkasse, Anzahl geborene Kinder, Geburtsdatum des Kindes,
naechste hebamme, Begr�ndungstext falls nicht n�chste Hebamme,
aktuelles Datum, Kennzeichen errechneter Termin/ Geburtstermin,
Geburtszeit des Kindes, privat Faktor.

=back

=cut

  my $self=shift; # package Namen vom stack nehmen

  my($vorname,
     $nachname,
     $geburtsdatum_frau,
     $strasse,
     $plz,
     $ort,
     $tel,
     $entfernung,
     $krankenversicherungsnummer,
     $krankenversicherungsnummer_gueltig,
     $versichertenstatus,
     $ik,
     $anz_kinder,
     $geburtsdatum_kind,
     $naechste_hebamme,
     $begruendung_nicht_naechste_hebamme,
     $datum,
     $kzetgt,
     $geburtszeit_kind,
     $privat_faktor,
     $id_alt) = @_;

  # zun�chst neue ID f�r Frau holen
  $h->get_lock("STAMMDATEN_ID"); # Stammdaten_ID sperren
  my $id = 1+$h->parm_unique('STAMMDATEN_ID');
  $id = $id_alt if ($id_alt);
  $h->parm_up('STAMMDATEN_ID',$id) if(!$id_alt);
  print "ergebnis ins_id $id<br>\n" if $debug;
  $h->release_lock("STAMMDATEN_ID"); # Stammdaten_ID freigeben

  # insert an Datenbank vorbereiten
  my $stammdaten_ins = $dbh->prepare("insert into Stammdaten ".
				     "(ID,VORNAME,NACHNAME,GEBURTSDATUM_FRAU,".
				     "STRASSE,PLZ,ORT,TEL,ENTFERNUNG,".
				     "KRANKENVERSICHERUNGSNUMMER,".
				     "KRANKENVERSICHERUNGSNUMMER_GUELTIG,".
				     "VERSICHERTENSTATUS,IK,".
				     "ANZ_KINDER,GEBURTSDATUM_KIND,".
				     "NAECHSTE_HEBAMME,".
				     "BEGRUENDUNG_NICHT_NAECHSTE_HEBAMME,".
				     "DATUM,".
				     "KZETGT,".
				     "GEBURTSZEIT_KIND,".
				     "PRIVAT_FAKTOR".
				     ")".
				     "values (?,?,?,?,".
				     "?,?,?,?,?,".
				     "?,".
				     "?,".
				     "?,?,".
				     "?,?,".
				     "?,".
				     "?,".
				     "?,".
				     "?,".
				     "?,".
				     "?);")
    or die $dbh->errstr();
  my $erg = $stammdaten_ins->execute($id,$vorname,$nachname,$geburtsdatum_frau,
				     $strasse,$plz,$ort,$tel,$entfernung,
				     $krankenversicherungsnummer,
				     $krankenversicherungsnummer_gueltig,
				     $versichertenstatus,$ik,
				     $anz_kinder,$geburtsdatum_kind,
				     $naechste_hebamme,
				     $begruendung_nicht_naechste_hebamme,
				     $datum,$kzetgt,$geburtszeit_kind,
				     $privat_faktor)
#				     $datum,$kzetgt,undef)
    or die $dbh->errstr();

  return $id;
}

sub stammdaten_update {
  # speichert ge�nderte Daten ab
  my $self=shift;
  # update an Datenbank vorbereiten
  my $stammdaten_up = $dbh->prepare("update Stammdaten set ".
				    "VORNAME=?,NACHNAME=?,GEBURTSDATUM_FRAU=?,".
				    "STRASSE=?,PLZ=?,ORT=?,TEL=?,ENTFERNUNG=?,".
				    "KRANKENVERSICHERUNGSNUMMER=?,".
				    "KRANKENVERSICHERUNGSNUMMER_GUELTIG=?,".
				    "VERSICHERTENSTATUS=?,IK=?,".
				    "ANZ_KINDER=?,GEBURTSDATUM_KIND=?,".
				    "NAECHSTE_HEBAMME=?,".
				    "BEGRUENDUNG_NICHT_NAECHSTE_HEBAMME=?,".
				    "DATUM=?, ".
				    "KZETGT=?, ".
				    "GEBURTSZEIT_KIND=?, ".
				    "PRIVAT_FAKTOR=? ".
				    "where ID=?;")
    or die $dbh->errstr();
  my $erg = $stammdaten_up->execute(@_)
    or die $dbh->errstr();

  print "ergebnis $erg<br>\n" if $debug;
  return $erg;
}


sub stammdaten_delete {
  # l�scht Datensatz aus der Datenbank
  my $self=shift;
  # delete an Datenbank vorbereiten
  my $stammdaten_del = $dbh->prepare("delete from Stammdaten ".
				     "where ID=?;")
    or die $dbh->errstr();
  my $erg = $stammdaten_del->execute(@_)
    or die $dbh->errstr();
   
  print "ergebnis $erg<br>\n" if $debug;
  return $erg;
}  


sub stammdaten_frau_id {
  # holt alle Daten zu einer Frau
  my $self=shift;

  my ($id) = @_;

  my $frau_id = $dbh->prepare("select VORNAME,NACHNAME,".
			      "DATE_FORMAT(GEBURTSDATUM_FRAU,'%d.%m.%Y'),".
			      "DATE_FORMAT(GEBURTSDATUM_KIND,'%d.%m.%Y'),".
			      "PLZ,ORT,TEL,STRASSE,ANZ_KINDER,ENTFERNUNG, ".
			      "KRANKENVERSICHERUNGSNUMMER,".
			      "KRANKENVERSICHERUNGSNUMMER_GUELTIG,".
			      "VERSICHERTENSTATUS,".
			      "IK,".
			      "NAECHSTE_HEBAMME,".
			      "BEGRUENDUNG_NICHT_NAECHSTE_HEBAMME, ".
			      "KZETGT, ".
			      "TIME_FORMAT(GEBURTSZEIT_KIND,'%H:%i'), ".
			      "PRIVAT_FAKTOR ".
			      "from Stammdaten where ".
			      "ID = $id;")
    or die $dbh->errstr();
  $frau_id->execute() or die $dbh->errstr();
  my @erg = $frau_id->fetchrow_array();
  for (my $i=0;$i < 16;$i++) {
    if (!defined($erg[$i])) {
      $erg[$i]='';
    }
  }
  return @erg;
}

sub stammdaten_next_id {

=head2 $s->stammdaten_next_id($id)

liefert die ID der n�chsten Frau in der Datenbank bei angebener ID.

Existiert keine n�chste Frau, wird die �bergebende ID als Ergebnis
zur�ckgeliefert.

=cut

  my $self=shift;
  my ($id) = @_;
  my $stammdaten_next_id =
    $dbh->prepare("select ID from Stammdaten where ".
		  "ID > ? limit 1;")
      or die $dbh->errstr();
  $stammdaten_next_id->execute($id) or die $dbh->errstr();
  my ($erg)=$stammdaten_next_id->fetchrow_array();
  return ($erg) if ($erg);
  return $id;
}

sub stammdaten_prev_id {

=head2 $s->stammdaten_prev_id($id)

liefert die ID der vorhergehenden Frau in der Datenbank bei angebener ID.

Existiert keine vorhergehende Frau, wird die �bergebende ID als Ergebnis
zur�ckgeliefert.

=cut


  # holt zur gegebenen Frau die vorhergehende Frau
  my $self=shift;
  my ($id) = @_;
  my $stammdaten_prev_id =
    $dbh->prepare("select ID from Stammdaten where ".
		  "ID < ? order by ID desc limit 1;")
      or die $dbh->errstr();
  $stammdaten_prev_id->execute($id) or die $dbh->errstr();
  my ($erg)= $stammdaten_prev_id->fetchrow_array();
  return $erg if ($erg);
  return $id;
}


sub stammdaten_werte {

=head2 $s->stammdaten_werte($werte,$where,$order)

Sucht nach Frauen die der $where Bedinung entsprechen
wenn where blank �bergeben wird, werden alle Frauen ausgegeben
      
Als Ergebnis werden die in $werte angegebenen Felder �bermittelt

Bei Bedarf kann $order angeben werden, dann wird das Ergebnis in der
in $order angegebenen Suchreihenfolge geliefert

=cut

  my $self=shift;
  my ($werte,$where,$order) = @_;
  $werte ='*' unless ($werte);
  if ($where) {
    $where = ' where '.$where;
  } else {
    $where = '';
  }
  if ($order) {
    $order = ' order by '.$order;
  } else {
    $order = '';
  }
  $stammdaten_werte = $dbh->prepare("select $werte from Stammdaten ".
				    "$where $order;")
      or die $dbh->errstr();
  my $erg=$stammdaten_werte->execute() or die $dbh->errstr();
  return $erg if($erg > 0);
  return 0;
}



sub stammdaten_werte_next {

=head2 $s->stammdaten_werte_next

Liefert das n�chste Suchergebnis zur Funktion stammdaten_werte

=cut

  my @erg=$stammdaten_werte->fetchrow_array();
  return @erg;
}


1;
