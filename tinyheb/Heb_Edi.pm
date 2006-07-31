#!/usr/bin/perl -wT

# Package f�r elektronische Rechnungen

# Copyright (C) 2005,2006 Thomas Baum <thomas.baum@arcor.de>
# Thomas Baum, Rubensstr. 3, 42719 Solingen, Germany

# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.

package Heb_Edi;

use strict;
use Date::Calc qw(Today_and_Now);
use File::stat;
use MIME::QuotedPrint qw(encode_qp);

use Heb;
use Heb_leistung;
use Heb_krankenkassen;
use Heb_stammdaten;
use Heb_datum;

my $debug=0;
my $h = new Heb;
my $l = new Heb_leistung;
my $k = new Heb_krankenkassen;
my $s = new Heb_stammdaten;
my $d = new Heb_datum;

my $delim = "'\x0d\x0a"; # Trennzeichen
my $crlf = "\x0d\x0a";
my $openssl ='openssl';

$openssl = '/OpenSSL/bin/'.$openssl if ($^O =~ /MSWin32/);

our $path = $ENV{HOME}; # f�r tempor�re Dateien
if ($^O =~ /MSWin32/) {
  $path .='/tinyheb';
} else {
  $path .='/.tinyheb';
}
mkdir "$path" if(!(-d "$path"));

our $dbh;
our $ERROR = '';

sub new {
  my $class = shift;
  my $rechnr = shift;
  my $self = {};
  $dbh = Heb->connect;
  # Rahmendaten f�r Rechnung aus Datenbank holen
  $l->rechnung_such("RECH_DATUM,BETRAG,FK_STAMMDATEN,IK","RECHNUNGSNR=$rechnr");
  my ($rechdatum,$betrag,$frau_id,$ik)=$l->rechnung_such_next();
  if(!defined($rechdatum)) {
    $ERROR="Rechnung nicht vorhanden";
    return undef;
  }
  $rechdatum =~ s/-//g;
  $self->{rechdatum}=$rechdatum;
  $betrag+=0.0;
  $self->{betrag}=$betrag;
  $self->{testind} = $k->krankenkasse_test_ind($ik);
  if (!defined($self->{testind})) {
    $ERROR="Keine Datennahmestelle vorhanden";
    return undef;
  }
  
  # kostentr�ger ermitteln
  my ($ktr,$zik)=$k->krankenkasse_ktr_da($ik);
  $self->{kostentraeger}=$ktr;
  $self->{annahmestelle}=$zik;
  
  # physikalischen Empf�nger ermitteln
  my $empf_physisch=$k->krankenkasse_empf_phys($zik);
  if (!defined($empf_physisch)) {
    $ERROR="Physikalischer Empf�nger konnte f�r ZIK: $zik nicht ermittelt werden";
    return undef;
  }
  $self->{empf_physisch}=$empf_physisch;

  # Stammdaten Frau holen
  my ($vorname,$nachname,$geb_frau,$geb_kind,$plz,$ort,$tel,$strasse,
      $anz_kinder,$entfernung,$kv_nummer,$kv_gueltig,$versichertenstatus,
      $ik_krankenkasse,$naechste_hebamme,
      $begruendung_nicht_nae_heb) = $s->stammdaten_frau_id($frau_id);
  $geb_frau=$d->convert($geb_frau);$geb_frau =~ s/-//g;
  if($geb_frau eq 'error') {
    $ERROR="Geburtsdatum der Frau ist kein g�ltiges Datum, es kann keine elektronische Rechnung erstellt werden, bitte in den Stammdaten korrigieren";
    return undef;
  }
  $geb_kind=$d->convert($geb_kind);$geb_kind =~ s/-//g;
  if($geb_kind eq 'error') {
    $ERROR="Geburtsdatum des Kindes ist kein g�ltiges Datum, es kann keine elektronische Rechnung erstellt werden, bitte in den Stammdaten korrigieren";
    return undef;
  }
  $self->{geb_kind}=$geb_kind;
  $self->{vorname}=$vorname;
  $self->{nachname}=$nachname;
  $self->{geb_frau}=$geb_frau;
  $self->{plz}=$plz;
  bless $self, ref $class || $class;

  my ($hilf,$betrag_slla)=$self->SLLA($rechnr,$zik,$ktr);
  if ($betrag_slla ne $self->{betrag}) {
    $ERROR="Betragsermittlung zu Papierrechnung unterschiedlich Edi Betrag:$betrag_slla, Papier: $betrag!!!";
    return undef;
  }
  
  return $self;
}



sub gen_auf {
  # generiert Auftragsdatei wie den Richtlinien f�r den Datenaustausch mit 
  # den geetzlichen Krankenkassen beschrieben.

  my $self=shift; # package Namen vom Stack nehmen

  my ($test_ind,$transfer_nr,$ik_empfaenger,
      $dateigroesse_nutz,$dateigroesse_ueb,
      $schl_ind,$sig_ind) = @_;

  my $default_n = '0';
  my $default_an = ' ';

  my $satzlaenge=348;
  my $i=0;
  my $st='!' x $satzlaenge;

  # 1. Teil Allgemeine Beschreibung der Krankenkassen-Kommunikation
  substr($st,1,6)='500000'; # Krankenkasse-Kommunikation Konstante 500000
  substr($st,7,2)='01'; # Version der Auftragsstruktur '01' erste Version
  substr($st,9,8)= sprintf "%8.8u",348; # L�nge Auftragsdatei Konstant 348
  substr($st,17,3)= '000'; # Laufende Nummer bei Teillieferung 000 komplett
  if ($test_ind > 1) { # pr�fen ob Test oder Produktion
    substr($st,20,5) = 'ESOL0'; # Produktion (siehe 3.2.3)
  } else {
    substr($st,20,5) = 'TSOL0'; # Test (siehe 3.2.3)
  }
  substr($st,25,3) = sprintf "%3.3u",substr((sprintf "%5.5u",$transfer_nr),2,3); # Transfernummer
  substr($st,28,5) = '     '; # Verfahrenkennung Spezifikation (optional)
#  substr($st,28,5) = '12345'; # Verfahrenkennung Spezifikation (optional)
  substr($st,33,15) = sprintf "%-15u", $h->parm_unique('HEB_IK'); #Absender Eigner der Daten
  substr($st,48,15) = sprintf "%-15u", $h->parm_unique('HEB_IK'); #Absender physikalisch
  substr($st,63,15) = sprintf "%-15u", $ik_empfaenger; # Empf�nger, der die Daten nutzen soll und im Besitz des Schl�ssels ist, um verschl�sselte Infos zu entschl�sseln

  # Anhand der IK Empf�nger Nummer pr�fen, ob der Schl�sselnutzer
  # unterschiedliches RZ nutzt, dann ist anderer physikalischer Empf�nger
  # anzugeben
#  my $ik_empfaenger_physisch=$k->krankenkasse_empf_phys($ik_empfaenger);
  my $ik_empfaenger_physisch=$self->{empf_physisch};
  if (!defined($ik_empfaenger_physisch)) {
    die "Zu Datenannahmestelle $ik_empfaenger mit Entschl�sselungsbefugnis konnte keine physikalische Annahmestelle gefunden werden\n"
  } else {
    substr($st,78,15) = sprintf "%-15u", $ik_empfaenger_physisch; # Empf�nger, der die Daten physikalisch empfangen soll
  }

  substr($st,93,6) = '000000'; # Fehlernr bei R�cksendung von Dateien
  substr($st,99,6) = '000000'; # Ma�nahme laut Fehlerkatalog

  substr($st,105,11) = "SL".substr($h->parm_unique('HEB_IK'),2,6).'S'.$d->monat(); # Dateiname
  
  my $erstelldatum = sprintf "%4.4u%2.2u%2.2u%2.2u%2.2u%2.2u",Today_and_Now(); # Datum Erstellung der Datei
  substr($st,116,14) = $erstelldatum;
  substr($st,130,14) = sprintf "%4.4u%2.2u%2.2u%2.2u%2.2u%2.2u",Today_and_Now(); # Datum Start der �bertragung
  substr($st,144,14) = sprintf "%14.14u",$default_n; # Datum Empfangen Start
  substr($st,158,14) = sprintf "%14.14u",$default_n; # Datum Empfangen Ende
  substr($st,172,6) = '000000'; # Versionsnummer Datei muss auf 000000 stehen
  substr($st,178,1) = '0'; # wird nichts genutzt muss auf 0 stehen
  substr($st,179,12) = sprintf "%12.12u", $dateigroesse_nutz; # Dateigr��e Nutzdaten (unverschl�sselt)
  substr($st,191,12) = sprintf "%12.12u", $dateigroesse_ueb; # Dateigr��e Nutzdaten (nach Verschl�sselung Signierung und Komprimierung)
  substr($st,203,2) = 'I1'; # Daten sind ISO 8859-1 codiert
  substr($st,205,2) = '00'; # keine Komprimierung
  # Verschl�sselungsart und Signatur
  substr($st,207,2) = sprintf "%2.2u",$schl_ind; # Verschl�sselung
  substr($st,209,2) = sprintf "%2.2u",$sig_ind; #  Signatur
  
  # 2. Teil Spezifische Information zur Bandverarbeitung
  substr($st,211,3)='   '; # Satzformat, bei DF� blank
  substr($st,214,5)='00000'; # Satzl�nge, bei DF� 00000
  substr($st,219,8)='00000000'; # Bl�ckl�nge, bei DF� 00000000

  # 3. Teil Spezifische Informationen f�r das KSS-Verfahren
  # alle Felder auf default setzen
  substr($st,227,1)=' '; # Status bei Anlieferung durch Abrechnungssystem blank
  substr($st,228,2)='00'; # maximale Anzahl wiederholungen bei fehler
  substr($st,230,1)='0'; # �bertragungsweg
  substr($st,231,10)= $default_n x 10; # Verz�gerter Versand
  substr($st,241,6)= $default_n x 6; # Info Fehlerfelder
  substr($st,247,28)= $default_an x 28; # Klartextfehlermeldung
  
  # 4. Teil Spezifische Information zur Verarbeitung innerhalb eines RZ
  substr($st,275,44)=$default_an x 44; # E-Mail Absender
  substr($st,319,30)=$default_an x 30; # Variabler Bereich f�r Zusatz Info
  

  $st=substr($st,1,$satzlaenge);
  $erstelldatum=substr($erstelldatum,0,8).':'.substr($erstelldatum,8,4);
  return ($st,$erstelldatum);
}


sub UNB {
  # generiert UNB Segment, Kopfsegment der Nutzendatei
  
  my $self=shift; # package Namen vom stack nehmen

  my ($ik_empfaenger,$datenaustauschref,$test_ind) = @_;

  my $erg = 'UNB+';
  $erg .= 'UNOC:3+'; # Syntax
  $erg .= $h->parm_unique('HEB_IK').'+'; # IK des Absenders
  $erg .= $ik_empfaenger.'+'; # IK des Empf�ngers
  my $erstelldatum=sprintf "%4.4u%2.2u%2.2u:%2.2u%2.2u",Today_and_Now(); # Erstellungsdatum und Uhrzeit der Datei
  $erg .= $erstelldatum.'+';
  $erg .= sprintf "%5.5u+",$datenaustauschref; # Datenaustauschreferenz, vortlaufende Nummer zwischen Absender und Empf�nger
  $erg .= '+'; # Freifeld
  $erg .= "SL".substr($h->parm_unique('HEB_IK'),2,6).'S'.$d->monat().'+'; # Anwendungsreferenz, entspricht dem logischen Dateinamen
  $erg .=  sprintf "%1.1u",$test_ind; # Indikator, ob Test, Erprobungs- oder Echtdatei
  $erg .= $delim;

  return ($erg,$erstelldatum);
}


sub UNZ {
  # generiert UNZ Segment, Endesegment der Nutzendatei

  my $self=shift;

  my ($datenaustauschref) = @_;

  my $erg = 'UNZ+';
  $erg .= sprintf "%6.6u+",2; # Anzahl der UNH in Nutzdatendatei
  $erg .= sprintf "%5.5u",$datenaustauschref;
  $erg .= $delim;

  return $erg;
}


sub SLGA_FKT {
  # generiert SLGA_FKT Segment
  # ist analog SLLA_FKT Segment, weil keine Sammelabrechnung erstellt wird
  # muss aber noch Absender zus�tzlich enthalten

  my $self=shift; # package Namen vom stack nehmen

  my ($ik_kostentraeger,$ik_krankenkasse) = @_;
  my $erg = 'FKT+';
  $erg .= '01+'; # Abrechnung ohne Besonderheiten
  $erg .= '+'; # Freifeld
  $erg .= $h->parm_unique('HEB_IK').'+'; # IK des Leistungserbringers
  $erg .= $ik_kostentraeger.'+'; # IK des Kostentr�gers
  $erg .= $ik_krankenkasse.'+'; # IK der Krankenkasse
  $erg .= $h->parm_unique('HEB_IK');
  $erg .= $delim; # Zeilentrennung anf�gen.

  return $erg;
  
}

sub SLGA_REC {
  # generiert SLGA REC Segment
  # analog SLLA REC Segment
  my $self=shift; # package Namen vom stack nehmen

  my ($rechnr,$rechdatum) = @_;
  return $self->SLLA_REC($rechnr,$rechdatum);
}


sub SLGA_UST {
  # generiert SLGA UST Segment
  my $self = shift;
  my $ustid = shift;
  $ustid =~ s/\// /g;
  
  my $erg = 'UST+';
  $erg .= $ustid.'+';
  $erg .= 'J'; # Hebammen sind Umsatzsteuerbefreit
  $erg .= $delim; # Zeilentrennung anf�gen

  return $erg;
}


sub SLGA_GES {
  # generiert SLGA_GES Segment

  my $self=shift;

  my ($gesamtsumme,$status) = @_;
  $gesamtsumme =~ s/\./,/g;

  my $erg = 'GES+';
  $erg .= $status.'+'; # Status 00 = Gesamtsumme aller Stati
  $erg .= $gesamtsumme; # Gesamtrechnungsbetrag
  # Gesamtbruttobetrag und Gesamtbetrag Zuzahlungen nicht �bermitteln
  # weil K Felder und identisch zu Gesamtrechnungsbetrag
  $erg .= $delim; # Zeilentrennung anf�gen

  return $erg;
}

sub SLGA_NAM {
  # generiert SLGA_NAM Segment

  my $self=shift;

  my $erg = 'NAM+';
  $erg .= substr($h->parm_unique('HEB_VORNAME').' '.$h->parm_unique('HEB_NACHNAME'),0,30).'+'; # Name der Hebamme
  $erg .= substr($h->parm_unique('HEB_TEL'),0,30); # Telefonnummer der Hebamme
  $erg .= $delim; # Zeilenende anf�gen

  return $erg;

}


sub SLLA_FKT {
  # generiert SLLA_FKT Segment

  my $self=shift; # package Namen vom stack nehmen

  my ($ik_kostentraeger,$ik_krankenkasse) = @_;
  
  my $erg = 'FKT+';
  $erg .= '01+'; # Abrechnung ohne Besonderheiten
  $erg .= '+'; # Freifeld
  $erg .= $h->parm_unique('HEB_IK').'+'; # IK des Leistungserbringers
  $erg .= $ik_kostentraeger.'+'; # IK des Kostentr�gers
  $erg .= $ik_krankenkasse; # IK der Krankenkasse
  $erg .= $delim; # Zeilentrennung anf�gen.

  return $erg;
}

sub SLLA_REC {
  # generiert SLLA REC Segment

  my $self=shift; # package Namen vom stack nehmen

  my ($rechnr,$rechdatum) = @_;

  my $erg = 'REC+';
  $erg .= $rechnr.':0+'; # Rechnungsnummer
  $erg .= $rechdatum.'+'; # Rechnungsdatum
  $erg .= '1+'; # Rechnungsart 1 = Abrechnung von LE und Zahlung an LE
  $erg .= 'EUR'; # W�hrungskennzeichen
  $erg .= $delim; # Zeilentrennung anf�gen

  return $erg;
}

sub SLLA_INV {
  # generiert SLLA INV Segment
  
  my $self=shift; # package Namen vom stack nehmen

  my ($kvnr,$kvstatus,$rechnr) = @_;

  my ($kvs_1,$kvs_2)= split ' ',$kvstatus;

  my $erg = 'INV+';
  $erg .= $kvnr.'+'; # Krankenversicherungsnummer
  $erg .= $kvs_1.'000'.$kvs_2.'+'; # Versichertenstatus
  $erg .= '+'; # Freifeld
  $erg .= $rechnr; # Belegnummer
  $erg .= $delim; # Zeilentrennung anf�gen

  return $erg;
}


sub SLLA_NAD {
  # generiert SLLA NAD Segment

  my $self=shift; # package Namen vom Stack nehmen

  my ($nachname,$vorname,$geb_frau,$strasse,$plz,$ort) = @_;
  # Steuerzeichen aufbereiten
  $nachname =~ s/'/\?'/g;$nachname =~ s/\+/\?\+/g;
  $nachname = substr($nachname,0,47);
  $vorname =~ s/'/\?'/g;$vorname =~ s/\+/\?\+/g;
  $vorname = substr($vorname,0,30);
  $strasse =~ s/'/\?'/g;$strasse =~ s/\+/\?\+/g;
  $strasse = substr($strasse,0,30);
  $ort =~ s/'/\?'/g;$ort =~ s/\+/\?\+/g;
  $ort = substr($ort,0,25);
  if (!defined($plz) || $plz == 0) {
    $plz='';
  } else {
    $plz = sprintf "%5.5u",$plz;
  }

  my $erg = 'NAD+';
  $erg .= $nachname.'+'; # nachname
  $erg .= $vorname.'+'; # vorname
  $erg .= $geb_frau.'+'; # geburtsdatum frau
  $erg .= $strasse.'+'; # strasse
  $erg .= $plz.'+'; # plz
  $erg .= $ort; # ort
  $erg .= $delim; # Zeilentrennung
  
  return $erg;
}


sub SLLA_ENF {
  # generiert SLLA ENF Segement

  my $self=shift; # package Namen vom Stack nehmen

  my($posnr,$datum,$preis,$menge) = @_;
  $menge = sprintf "%.2f",$menge;
  print "Posnr: $posnr,\t Datum: $datum, Preis: $preis,\t Menge: $menge\tPreis*Menge:",$preis*$menge,"\t" if ($debug >100);
  $menge =~ s/\./,/g;

  my $erg = 'ENF+';
  $erg .= '+'; # Feld Identifikationsnummer �berspringen, wird nicht genutzt
  $erg .= '50:'.$h->parm_unique('HEB_TARIFKZ').'000+'; # Abrechnungscode 50 Hebamme Sondertarik 000 = ohne Sondertarif
  $erg .= $posnr.'+'; # Art der Leistung gem 8.2.6 PosNr
  $erg .= '+'; # Positionsnummer Produktbesonderheiten 
  $erg .= "$menge+"; # Anzahl der Abrechnungspositionen
  $preis = sprintf "%.2f",$preis;
  $preis =~ s/\./,/g;
  $erg .= $preis.'+'; # Einzelpreis der Abrechnungsposition
  $erg .= $datum.'+';
  $erg .= '+'; # Schl�ssel-KZ bei Hilfsmittel muss eigentlich angegeben werden
  $erg .= '+'; # Inventarnummer f�r Hilfsmittel noch nicht belegt
  # Betrag Zuzahlung entf�llt
  $erg .= $delim;


  return $erg;
}

sub SLLA_SUT {
  # generiert SLLA SUT Segment
  my $self=shift; 

  my ($zeit_von,$zeit_bis,$dauer) = @_;
  $zeit_von =~ s/://g;
  $zeit_bis =~ s/://g;
  
  my $erg = 'SUT+';
  $erg .= '+'; # gefahrene Kilometer m�ssen �ber ENF gerechnet werden
  $erg .= $zeit_von.'+'; # Uhrzeit
  $erg .= $zeit_bis.'+'; # Uhrzeit bis
  $erg .= $dauer; # Dauer in Minuten
  $erg .= $delim;
  
  return $erg;
}

sub SLLA_TXT {
  # generiert SLLA TXT Segment
  my $self=shift;
  
  my ($text)=@_;
  $text =~ s/'/\?'/g;$text =~ s/\+/\?\+/g; # Steuerzeichen aufbereiten
  $text = substr($text,0,70);

  my $erg = 'TXT+';
  $erg.= $text;
  $erg .= $delim;

  return $erg;
}


sub SLLA_BES {
  # generiert SLLA BES Segment
  my $self=shift;

  my ($betrag) = @_;
  $betrag = sprintf "%.2f",$betrag;
  $betrag =~ s/\./,/g;

  my $erg = 'BES+';
  $erg .= $betrag;
  $erg .= $delim;

  return $erg;
}


sub SLLA_ZUV {
  # generiert SLLA ZUV Segement
  my $self=shift;
  
  my $erg = 'ZUV+';
  $erg .= '+'; # Vertragsarztnummer muss nicht geliefer werden
  $erg .= $self->{geb_kind}; # Geburtsdatum Kind
  $erg .= '+';
  $erg .= '0'; # Zuzahlungskennzeichen ist immer Null
  $erg .= $delim;

  return $erg;
}


sub UNH {
  # generiert UNH Segment
  my $self=shift;

  my ($lfdnr,$typ)=@_;
  $lfdnr = sprintf "%5.5u",$lfdnr;

  my $erg = 'UNH+';
  $erg .= $lfdnr.'+'; # laufender Nummer der UNH Segmente
  $erg .= $typ.':05:0:0'; # Nachrichtenkennung
  $erg .= $delim;

  return $erg;
}

sub UNT {
  # generiert UNT Segment
  my $self=shift;

  my ($anzahl,$refnr) = @_;
  $anzahl = sprintf "%6.6u",$anzahl;
  $refnr = sprintf "%5.5u",$refnr;

  my $erg = 'UNT+';
  $erg .= $anzahl.'+'; # Anzahl der Segemente in Nachricht inkl. UNH und UNT
  $erg .= $refnr; # Nachrichtenreferenz wie in UNH Segment
  $erg .= $delim;

  return $erg;
}


sub SLGA {
  # generiert kompletten Nachrichtentyp SLGA
  # inkl. Kopf und Endesegment
  
  my $self = shift;

  my ($rechnr,$zik,$ktr) = @_;
  my $lfdnr = 0;
  my $ref=1; # Nachrichtenreferenznummer
  my $erg = '';

  # Kopfsegment UNH produzieren
  $erg .= $self->UNH($ref,'SLGA');$lfdnr++;

  # Rahmendaten f�r Rechnung aus Datenbank holen
  $l->rechnung_such("RECH_DATUM,BETRAG,FK_STAMMDATEN,IK","RECHNUNGSNR=$rechnr");
  my ($rechdatum,$betrag,$frau_id,$ik)=$l->rechnung_such_next();
  $betrag+=0.0; # entfernen der f�hrenden Nullen
  $rechdatum =~ s/-//g;

  # 1. FKT Segment erzeugen
  $erg .= $self->SLGA_FKT($ktr,$ik);$lfdnr++;
  # 2. REC Segment erzeugen
  $erg .= $self->SLGA_REC($rechnr,$rechdatum);$lfdnr++;
  # 3. UST Segement erzeugen, wenn Steuernummer vorhanden
  if ($h->parm_unique('HEB_STNR')) {
    $erg .= $self->SLGA_UST($h->parm_unique('HEB_STNR'));$lfdnr++;
  }
  # 4. GES Segment erzeugen
  # zun�chst Rechnungsbetrag ermitteln
  my ($hilf,$betrag_slla)=$self->SLLA($rechnr,$zik,$ktr);
  if ($betrag_slla ne $betrag) {
    if ($rechdatum > 20051006) {
      die "Betragsermittlung zu Papierrechnung unterschiedlich Edi:$betrag_slla, Papier: $betrag!!!\n";
    } else {
      print "ACHTUNG Papier zu Edi Rechnung unterschiedlich, da Rechnung vor dem 06.10.2005 erstellt wurde wird weiter gearbeitet,\nEdi:$betrag_slla, Papier: $betrag!!!\n";
    }
  }
  $erg .= $self->SLGA_GES($betrag_slla,'00');$lfdnr++;
  $erg .= $self->SLGA_GES($betrag_slla,'11');$lfdnr++;
  
  # 4. NAM Segment erzeugen
  $erg .= $self->SLGA_NAM();$lfdnr++;

  # 5. UNT Segment erzeugen
  $erg .= $self->UNT($lfdnr+1,$ref);
  
  return $erg;
}


sub SLLA {
  # generiert kompletten Nachrichtentyp SLLA 
  # inkl. Kopf und Endesegment

  my $self=shift;

  my ($rechnr,$zik,$ktr) = @_;
  my $lfdnr = 1; # muss mit 1 beginnen sonst keine korrekte Z�hlung
  #                laut Herr Birk AOK Rheinland
  my $gesamtsumme = 0.00; # summe aller Rechnungsbetr�ge
  my $ref=2; # Nachrichtenreferenznummer, fortlaufende Nummer der UNH
  ;;;;;;;;;;;# Segemente zw. UNB und UNZ, d.h.hier immer 2 weil nach SLGA
  my $erg=''; # komplettes Ergebniss
  my $summe_km=0; # summe des Kilometergeldes

  # Kopfsegment UNH produzieren
  $erg .= $self->UNH($ref,'SLLA');$lfdnr++;
  
  # Rahmendaten f�r Rechnung aus Datenbank holen
  $l->rechnung_such("RECH_DATUM,BETRAG,FK_STAMMDATEN,IK","RECHNUNGSNR=$rechnr");
  my ($rechdatum,$betrag,$frau_id,$ik)=$l->rechnung_such_next();
  $rechdatum =~ s/-//g;

  my $test_ind = $k->krankenkasse_test_ind($ik);

  # Stammdaten Frau holen
  my ($vorname,$nachname,$geb_frau,$geb_kind,$plz,$ort,$tel,$strasse,
      $anz_kinder,$entfernung,$kv_nummer,$kv_gueltig,$versichertenstatus,
      $ik_krankenkasse,$naechste_hebamme,
      $begruendung_nicht_nae_heb) = $s->stammdaten_frau_id($frau_id);

  $geb_frau=$d->convert($geb_frau);$geb_frau =~ s/-//g;
  die "Geburtsdatum der Frau ist kein g�ltiges Datum, es kann keine elektronische Rechnung erstellt werden, bitte in den Stammdaten korrigieren\n" if ($geb_frau eq 'error');
  
  # 1. FKT Segment erzeugen
  $erg .= $self->SLLA_FKT($ktr,$ik);$lfdnr++;
  # 2. REC Segment erzeugen
  $erg .= $self->SLLA_REC($rechnr,$rechdatum);$lfdnr++;
  # 3. INV Segment erzeugen
  $erg .= $self->SLLA_INV($kv_nummer,$versichertenstatus,$rechnr);$lfdnr++;
  # 4. NAD Segment erzeugen
  $erg .= $self->SLLA_NAD($nachname,$vorname,$geb_frau,$strasse,$plz,$ort);
  $lfdnr++;

  # 5. ENF Segmente generieren
  # dazu Schleife �ber alle Positionen, die die Rechnungsnummer enthalten
  my %ges_sum;$ges_sum{A}=0;$ges_sum{C}=0;$ges_sum{M}=0;$ges_sum{B}=0;
  $l->leistungsdaten_such_rechnr("*",$rechnr.' order by DATUM');
  while (my @leistdat=$l->leistungsdaten_such_rechnr_next()) {
    $leistdat[5]=substr($leistdat[5],0,5); # nur HH:MM aus Ergebniss
    $leistdat[6]=substr($leistdat[6],0,5); # nur HH:MM aus Ergebniss
    # a. zuerst normale posnr f�llen
    my ($bez,$fuerzeit,$epreis,$ltyp,$zus1)=$l->leistungsart_such_posnr("KBEZ,FUERZEIT,EINZELPREIS,LEISTUNGSTYP,ZUSATZGEBUEHREN1 ",$leistdat[1],$leistdat[4]);
    my $fuerzeit_flag='';
    my $dauer=0;
    my $anzahl=1; # Default, wenn keine Zeitangabe notwendig
    ($fuerzeit_flag,$fuerzeit)=$d->fuerzeit_check($fuerzeit);
    # pr�fen ob Zeitangabe notwendig 
    if (defined($fuerzeit) && $fuerzeit > 0) {
      $dauer = $d->dauer_m($leistdat[6],$leistdat[5]);
      $anzahl = sprintf "%3.2f",($dauer / $fuerzeit);
      # pr�fen, ob Minuten genau abgerechnet werden muss
      if ($fuerzeit_flag ne 'E') { # nein
	$anzahl = sprintf "%2.2u",$anzahl;
        $anzahl++ if ($anzahl*$fuerzeit < $dauer);
      }
    }
    $leistdat[4] =~ s/-//g; # Datum in korrektes Format bringen

    # ENF Segment ausgeben
    if($ltyp ne 'M') { 
      # keine Materialpauschale
      if($epreis > 0) { # hier wird nicht prozentual gerechnet
	$erg .= $self->SLLA_ENF($leistdat[1],$leistdat[4],$epreis,$anzahl);
	$gesamtsumme += sprintf "%.2f",($epreis*$anzahl);
	my $wert= sprintf "%.2f",($epreis*$anzahl);
	$ges_sum{$ltyp} += $wert;
      } else {
	$erg .= $self->SLLA_ENF($leistdat[1],$leistdat[4],$leistdat[10],$anzahl);
	$gesamtsumme += sprintf "%.2f",($leistdat[10]*$anzahl);
	$ges_sum{$ltyp} += (sprintf "%2.f",($leistdat[10]*$anzahl));
      }
      $lfdnr++;


    } else {
      # Materialpauschale 
      # Pr�fen, welche Positionsnumer genutzt werden muss
      if ($leistdat[1] =~ /^[A-Z]\d{1,3}$/) {
	# es muss zugeordnete Positionsnummer geben, diese steht in $zus1
	$zus1 = 70 if (!defined($zus1) or $zus1 eq '');
	$erg .= $self->SLLA_ENF($zus1,$leistdat[4],$leistdat[10],1);
	$lfdnr++;
	# Text mit ausgeben
	$erg .= $self->SLLA_TXT($bez);$lfdnr++;
      } elsif ($leistdat[1] =~ /^\d{1,3}$/) {
	$erg .= $self->SLLA_ENF($leistdat[1],$leistdat[4],$leistdat[10],1);
	$lfdnr++;
      } else {
	$ERROR="Materialpauschale konnte nicht ermittelt werden\n";
	return undef;
      }
      
      $gesamtsumme += $leistdat[10];
      $ges_sum{$ltyp} += $leistdat[10];
    }

    print "Zwischensumme ohne Wegegeld: $gesamtsumme\n" if ($debug>100);
    print "Typ A:",$ges_sum{A},"\tTyp B:",$ges_sum{B},"\tTyp C:",$ges_sum{C},"\tTyp M:",$ges_sum{M},"\n" if ($debug > 50);

    # b. pr�fen ob Zeitangaben ausgegeben werden m�ssen
    if (defined($fuerzeit) && $fuerzeit > 0) {
      $erg .= $self->SLLA_SUT($leistdat[5],$leistdat[6],$dauer);$lfdnr++;
    }

    # c. Begr�ndungstexte ausgeben
    if ($leistdat[3] ne '') { # Begr�ndung ausgeben
      $erg .= $self->SLLA_TXT($leistdat[3]);$lfdnr++;
    }

    # d. Kilometergeld ausgeben
    my $posnr_wegegeld='';
    $leistdat[7] = sprintf "%.2f",$leistdat[7]; # w/ Rundungsfehlern
    $leistdat[8] = sprintf "%.2f",$leistdat[8]; # w/ Rundungsfehlern
    $posnr_wegegeld='91' if ($leistdat[7] > 0 && $leistdat[7] <= 2);# Tag < 2
    $posnr_wegegeld='92' if ($leistdat[8] > 0 && $leistdat[8] <= 2);# Nacht < 2
    $posnr_wegegeld='93' if ($leistdat[7] > 0 && $leistdat[7] > 2); # Tag > 2
    $posnr_wegegeld='94' if ($leistdat[8] > 0 && $leistdat[8] > 2); # Nacht > 2
    if ($posnr_wegegeld ne '') { # es muss wegegeld gerechnet werden
      ($epreis)=$l->leistungsart_such_posnr("EINZELPREIS",$posnr_wegegeld,$leistdat[4]);
      my $anteilig='';
      $anteilig='a' if ($leistdat[9]>1);# anteiliges Wegegeld
      if ($posnr_wegegeld eq '91' || $posnr_wegegeld eq '92') {
	$erg .= $self->SLLA_ENF($posnr_wegegeld.$anteilig,$leistdat[4],$epreis,1);
	$lfdnr++;
	$summe_km+=$epreis;
	print "Wegegeld summe: $summe_km, $epreis\n" if ($debug > 1000);
      } elsif ($posnr_wegegeld eq '93') {
	$erg .= $self->SLLA_ENF($posnr_wegegeld.$anteilig,$leistdat[4],$epreis,$leistdat[7]);
	$lfdnr++;
	my $km_preis = sprintf "%.2f",$leistdat[7]*$epreis;
	$summe_km+=$km_preis;
	print "Wegegeld summe: $summe_km, $km_preis,km: $leistdat[7]\n" if ($debug > 1000);
      } elsif ($posnr_wegegeld eq '94') {
	$erg .= $self->SLLA_ENF($posnr_wegegeld.$anteilig,$leistdat[4],$epreis,$leistdat[8]);
	$lfdnr++;
	my $km_preis = sprintf "%.2f",$leistdat[8]*$epreis;
	$summe_km+=$km_preis;
	print "Wegegeld summe: $summe_km, $km_preis\n" if ($debug > 1000);
      }
      print "\n" if ($debug > 100);
    }
  }

  # 6 ZUV Segment erzeugen
  $erg .= $self->SLLA_ZUV;$lfdnr++;

  # 7. BES Segment ausgeben
  $gesamtsumme += $summe_km;
  $erg .= $self->SLLA_BES($gesamtsumme);

  # 8. UNT Endesegment ausgeben
  $erg .= $self->UNT($lfdnr+1,$ref);
  print "$gesamtsumme, $summe_km\n" if ($debug > 10);
  return ($erg,$gesamtsumme);
}



sub gen_nutz {
  # generiert Nutzdatendatei
  # mit allen notwendigen Segmenten

  my $self=shift;

  my ($rechnr,$zik,$ktr,$datenaustauschref) = @_;

  my $erg = '';

  my $test_ind = $k->krankenkasse_test_ind($ktr);
  my ($zw_erg,$erstelldatum)= $self->UNB($zik,$datenaustauschref,$test_ind);
  $erg .= $zw_erg;
  $erg .= $self->SLGA($rechnr,$zik,$ktr);
  my ($erg_slla,$summe) = $self->SLLA($rechnr,$zik,$ktr);
  $erg .= $erg_slla;
  $erg .= $self->UNZ($datenaustauschref);
  return ($erg,$erstelldatum);
}


sub sig {
  # signieren Nutzdatendatei

  my $self=shift;

  my ($dateiname,$sig_flag)=@_;

  if ($sig_flag == 0) {
    # PEM verschl�sseln
    open NUTZ, "$path/tmp/$dateiname" or
      die "konnte Datei nicht NICHT signieren\n";
  }
  if ($sig_flag == 2) {
    # PEM signieren
    die "PEM Signierung  ist nicht implementiert, bitte nutzen sie pkcs7\n";
    open NUTZ, "$openssl smime -sign -in $path/tmp/$dateiname -nodetach -outform PEM -signer $path/privkey/cert.pem -inkey $path/privkey/privkey.pem |" or
      die "konnte Datei nicht PEM signieren\n";
  }
  if ($sig_flag == 3) {
    # DER signieren um sp�ter base64 encoden zu k�nnen
    open NUTZ, "$openssl smime -sign -in $path/tmp/$dateiname -nodetach -outform DER -signer $path/privkey/cert.pem -inkey $path/privkey/privkey.pem |" or
      die "konnte Datei nicht DER verschl�sseln\n";
  }

  open AUS, ">$path/tmp/$dateiname.sig";
    
 
 LINE: while (my $zeile=<NUTZ>) {
    print AUS $zeile;
  }
  close NUTZ;
  close AUS;
 
  # L�nge der Datei ermitteln
  my $st=stat($path."/tmp/$dateiname.sig") or die "Datei $dateiname.sig nicht vorhanden:$!\n";
  return ("$dateiname.sig",$st->size);
}


sub enc {
  # verschl�sselt Nutzdatendatei

  my $self=shift;

  my ($dateiname,$schl_flag)=@_;

  if ($schl_flag == 0) {
    # PEM verschl�sseln
    open NUTZ, "$path/tmp/$dateiname" or
      die "konnte Datei nicht NICHT verschl�sseln\n";
  }
  if ($schl_flag == 2) {
    # PEM verschl�sseln
    die "PEM Verschl�sselung ist nicht implementiert, bitte nutzen sie pkcs7\n";
    open NUTZ, "$openssl smime -encrypt -in $path/tmp/$dateiname -des3 -outform DER $path/tmp/zik.pem |" or
      die "konnte Datei nicht PEM verschl�sseln\n";
  }
  if ($schl_flag == 3) {
    # DER verschl�sseln um sp�ter base64 encoden zu k�nnen
    open NUTZ, "openssl smime -encrypt -in $path/tmp/$dateiname -des3 -outform DER $path/tmp/zik.pem |" or
      die "konnte Datei nicht DER verschl�sseln\n";
  }

  $dateiname =~ s/\.sig//g;
  open AUS, ">$path/tmp/$dateiname.enc";
    
 LINE: while (my $zeile=<NUTZ>) {
    print AUS $zeile;
  }
  close NUTZ;
  close AUS;
  
  # L�nge der Datei ermitteln
  my $st=stat($path."/tmp/$dateiname.enc") or die "Datei $dateiname.enc nicht vorhanden:$!\n";
  return ("$dateiname.enc",$st->size);
}



sub edi_rechnung {
  # generiert komplette elektronische Rechnung 
  # Auftrags- und Nutzdatendatei
  
  my $self=shift;

  my ($rechnr) = @_;

  my $erg_nutz = ''; # Nutzdatendatei
  my $erg_auf  = ''; # Auftragsdatendatei
  my $erstell_nutz = ''; # Erstelldatum Nutzdatedatei
  my $erstell_auf = '';  # Erstelldatum Auftragsdatei


  # Rahmendaten f�r Rechnung aus Datenbank holen
  $l->rechnung_such("RECH_DATUM,BETRAG,FK_STAMMDATEN,IK","RECHNUNGSNR=$rechnr");
  my ($rechdatum,$betrag,$frau_id,$ik)=$l->rechnung_such_next();
  die "Rechnung nicht vorhanden Abbruch\n" if (!defined($rechdatum));

  # pr�fen ob zu ik Zentral IK vorhanden ist
  my ($ktr,$zik)=$k->krankenkasse_ktr_da($ik);
  my $test_ind = $k->krankenkasse_test_ind($ik);
  return undef if (!defined($test_ind)); # ZIK nicht als Annahmestelle vorhanden
  my $datenaustauschref = $h->parm_unique('DTAUS'.$zik);
  my $schl_flag = $h->parm_unique('SCHL'.$zik);
  my $sig_flag = $h->parm_unique('SIG'.$zik);

  ($erg_nutz,$erstell_nutz) = $self->gen_nutz($rechnr,$zik,$ktr,$datenaustauschref);

  # Dateinamen ermitteln
  my $dateiname='';
  if ($test_ind > 1) { # pr�fen ob Test oder Produktion
    $dateiname .= 'ESOL0'; # Produktion (siehe 3.2.3)
  } else {
    $dateiname .= 'TSOL0'; # Test (siehe 3.2.3)
  }
  my $empf_physisch=$k->krankenkasse_empf_phys($zik);
  die "Physikalischer Empf�nger konnte f�r ZIK: $zik nicht ermittelt werden\n" unless (defined($empf_physisch));
  my $transref=$h->parm_unique('DTAUS'.$empf_physisch);
  $dateiname .= sprintf "%3.3u",substr((sprintf "%5.5u",$transref),2,3); # Transfernummer
  my $dateiname_orig = $dateiname;

  # Nutzdatendatei schreiben
  open NUTZ, ">$path/tmp/$dateiname"
    or die "Konnte Nutzdatei nicht zum Schreiben �ffnen $!\n";
  print NUTZ $erg_nutz;
  close NUTZ;

  my $laenge_nutz=length($erg_nutz);

  # hier muss noch verschl�sselt und signiert werden
  # Public key der Krankenkasse schreiben
  my ($pubkey) = $k->krankenkasse_sel("PUBKEY",$zik);
  open KWRITE,">$path/tmp/zik.pem" or die "Kann key zu $zik nicht schreiben\n";
  print KWRITE "-----BEGIN CERTIFICATE-----\n";
  print KWRITE $pubkey;
  print KWRITE "-----END CERTIFICATE-----\n";
  close(KWRITE);

  # signieren
  ($dateiname,$laenge_nutz)=$self->sig($dateiname,$sig_flag);
  # verschl�sseln
  ($dateiname,$laenge_nutz)=$self->enc($dateiname,$schl_flag);


  ($erg_auf,$erstell_auf)  = 
    $self->gen_auf($test_ind,$transref,$zik,length($erg_nutz),
		   $laenge_nutz,
		   $h->parm_unique('SCHL'.$zik),
		   $h->parm_unique('SIG'.$zik));

  # jetzt Dateien schreiben mit physikalischen Namen

  # Auftragsdatei schreiben
  open AUF, ">$path/tmp/$dateiname_orig.AUF"
    or die "Konnte Auftragsdatei nicht zum Schreiben �ffnen $!\n";
  print AUF $erg_auf;
  close (AUF);

  # wenn alles gelaufen ist, Datenaustauschreferenz erh�hen
  $datenaustauschref++;
  $transref++;
  $transref=0 if($transref > 999);
  $datenaustauschref=0 if($datenaustauschref > 99999);
  $h->parm_up('DTAUS'.$zik,$datenaustauschref);
  $h->parm_up('DTAUS'.$empf_physisch,$transref) if($empf_physisch != $zik);
  return ($dateiname_orig,$erstell_auf,$erstell_nutz);
}


sub mail {
  # produziert Mail f�r eine Rechnung, die in Datei vorliegen muss
  # als Ergebniss wird ein String geliefert, der ggf. nach sendmail
  # gepiped werden kann.

  my $self=shift;

  my ($dateiname,$rechnr,$erstell_auf,$erstell_nutz) = @_;


  # Rahmendaten f�r Rechnung aus Datenbank holen
  $l->rechnung_such("RECH_DATUM,BETRAG,FK_STAMMDATEN,IK","RECHNUNGSNR=$rechnr");
  my ($rechdatum,$betrag,$frau_id,$ik)=$l->rechnung_such_next();
  # pr�fen ob zu ik Zentral IK vorhanden ist
  my ($ktr,$zik)=$k->krankenkasse_ktr_da($ik);
  my $test_ind = $k->krankenkasse_test_ind($ik);
  return undef if (!defined($test_ind)); # ZIK nicht als Annahmestelle vorhanden

  my $boundary='Boundary-00='.$rechnr;

  my $dateiname_ext=$dateiname; # Dateiendung der Nutzdatendatei
  $dateiname_ext = $dateiname.'.sig' if ($h->parm_unique('SIG'.$zik) > 0);
  $dateiname_ext = $dateiname.'.enc' if ($h->parm_unique('SCHL'.$zik) > 0);

  # Header
  my $erg .= 'From: '.$h->parm_unique('HEB_IK').' <'.$h->parm_unique('HEB_EMAIL').'>'.$crlf;
  $erg .= 'To: '.$h->parm_unique('MAIL'.$zik).$crlf;
  $erg .= 'Bcc: '.$h->parm_unique('HEB_IK').' <'.$h->parm_unique('HEB_EMAIL').'>'.$crlf;
  $erg .= 'Subject: '.$h->parm_unique('HEB_IK').$crlf;
  $erg .= 'MIME-Version: 1.0'.$crlf;
  $erg .= 'Content-Type: Multipart/Mixed;'.$crlf;
  $erg .= '  boundary="'.$boundary.'"'.$crlf;
  $erg .= $crlf;

  # Message Body
  $erg .= '--'.$boundary.$crlf;
  $erg .= 'Content-Type: text/plain;'.$crlf;
  $erg .= '  charset="iso-8859-1"'.$crlf;
  $erg .= 'Content-Transfer-Encoding: quoted-printable'.$crlf;
  $erg .= 'Content-Disposition: inline'.$crlf;
  $erg .= $crlf;
  
  $erg .= encode_qp($dateiname.'.AUF,348,'.$erstell_auf,$crlf).$crlf;
  # L�nge der Nutzdatendatei ermitteln
  my $st=stat("$path/tmp/$dateiname_ext") or die "Datei $dateiname_ext f�r Message Body nicht vorhanden:$!\n";
  my $laenge_nutz=$st->size;
  $erg .= encode_qp($dateiname.','.$laenge_nutz.','.$erstell_nutz,$crlf).$crlf;
  $erg .= encode_qp($h->parm_unique('HEB_VORNAME').' '.$h->parm_unique('HEB_NACHNAME'),$crlf).$crlf; # Absender Firmenname
  $erg .= encode_qp($h->parm_unique('HEB_VORNAME').' '.$h->parm_unique('HEB_NACHNAME'),$crlf).$crlf; # Absender Ansprechpartner
  $erg .= encode_qp($h->parm_unique('HEB_EMAIL'),$crlf).$crlf;
  $erg .= encode_qp($h->parm_unique('HEB_TEL'),$crlf).$crlf;
  $erg .= $crlf;

  # Attachment 1 Datei mit Auftragssatz
  $erg .= '--'.$boundary.$crlf;
  $erg .= 'Content-Type: text/plain;'.$crlf;
  $erg .= '  charset="iso-8859-1"'.$crlf;
  $erg .= 'Content-Transfer-Encoding: quoted-printable'.$crlf;
  $erg .= 'Content-Disposition: attachment; filename="'.$dateiname.'.auf"'.$crlf;
  $erg .= $crlf;
  # Auftragsdatei lesen
  open AUF, "$path/tmp/$dateiname.AUF"
    or die "Konnte Auftragsdatei nicht �ffnen\n";
  my $auf = <AUF>;
  $erg .= encode_qp($auf,$crlf).$crlf;
  close AUF;

  # Attachment 2 Datei mit Nutzdaten
  $erg .= '--'.$boundary.$crlf;
  if ($h->parm_unique('SCHL'.$zik) > 0 || $h->parm_unique('SIG'.$zik) > 0) {
    # Dateinamen extension muss jetzt erweitert werden
    $erg .= 'Content-Type: text/plain;'.$crlf;
    $erg .= '  charset="iso-8859-1"'.$crlf;
    $erg .= '  name="'.$dateiname.'"'.$crlf;
    $erg .= 'Content-Transfer-Encoding: base64'.$crlf;
    $erg .= 'Content-Disposition: attachment; filename="'.$dateiname.'"'.$crlf;
    $erg .= $crlf;
  }

  if ($h->parm_unique('SCHL'.$zik) == 0 && $h->parm_unique('SIG'.$zik) == 0) {
    $erg .= 'Content-Disposition: attachment; filename="'.$dateiname.'"'.$crlf;
    $erg .= 'Content-Type: text/plain;'.$crlf;
    $erg .= '  charset="iso-8859-1"'.$crlf;
    $erg .= '  name="'.$dateiname.'"'.$crlf;
    $erg .= 'Content-Transfer-Encoding: quoted-printable'.$crlf;
    $erg .= $crlf;
  }

  # pr�fen ob Nutzdatendatei noch base64 codiert werden muss
  if ($h->parm_unique('SCHL'.$zik) == 3) {
    open NUTZ, "mimencode $path/tmp/$dateiname_ext |" or die 
      "Konnte Nutzdatendatei nicht base64 codieren $!";
    open AUS, ">$path/tmp/$dateiname.base64" or die
      "konnte Nutzdatendatei nicht base64 schreiben $!";
    while (my $zeile=<NUTZ>) {
      print AUS $zeile;
    }
    close NUTZ; close AUS;
    $dateiname_ext=$dateiname.'.base64';
  }

  # Nutzdatendatei lesen
  open NUTZ, "$path/tmp/$dateiname_ext" or die "Konnte Nutzdatendatei nicht �ffnen $!";
 LINE: while (my $zeile=<NUTZ>) {
    if ($h->parm_unique('SCHL'.$zik) == 0 && $h->parm_unique('SIG'.$zik) == 0) {
      # Datei wird quoted printable ausgegeben
      $zeile =~ s/$crlf$//; # vorher crlf entfernen
      $zeile = encode_qp($zeile,$crlf).$crlf;
    } else {
    }
    $erg .= $zeile;
  }
  close NUTZ;

  $erg .= $crlf;
  
  return $erg;
    
}

sub edi_update {
  # macht update auf Tabelle 
  # Rechnung und Leistungsdaten und hinterlegt da den neuen
  # Rechnungsstatus
  my $self=shift;
  my ($rechnr,$ignore,$dateiname,$datum) = @_;

  $datum =~ s/://g;
  $datum .= '00';
  # Rahmendaten f�r Rechnung aus Datenbank holen
  $l->rechnung_such("ZAHL_DATUM,BETRAGGEZ,BETRAG,STATUS","RECHNUNGSNR=$rechnr");
  my ($zahl_datum,$betraggez,$betrag,$status)=$l->rechnung_such_next();
  if ($status > 20 && !($ignore) ) {
    die "Rechnung wurde schon elektronisch gestellt oder ist schon (Teil-)bezahlt Rechnungsstatus ist:$status\n";
  }
  $status=22;
  $l->rechnung_up($rechnr,$zahl_datum,$betraggez,$status);
  # update auf einzelne Leistungspositionen muss noch erfolgen
  $l->leistungsdaten_such_rechnr("ID",$rechnr);
  while (my ($id)=$l->leistungsdaten_such_rechnr_next()) {
    $l->leistungsdaten_up_werte($id,"STATUS=$status");
  }
  # jetzt noch Datum, Auftragsdatei und Nutzdatendatei in DB abspeichern.
  my $auf = '';
  my $nutz = '';
  # Auftragsdatei lesen
  open AUF, "$path/tmp/$dateiname.AUF" or die "Konnte Auftragsdatei nicht f�r speichern in DB �ffnen $!";
 LINE: while (my $zeile=<AUF>) {
    $auf .= $zeile;
  }
  close AUF;
  # Nutzdatendatei lesen
  open NUTZ, "$path/tmp/$dateiname" or die "Konnte Nutzdatendatei nicht f�r speichern in DB �ffnen $!";
 LINE: while (my $zeile=<NUTZ>) {
    $nutz .= $zeile;
  }
  close NUTZ;
  $l->rechnung_up_werte($rechnr,"EDI_DATUM='$datum',EDI_NUTZ=\"$nutz\",EDI_AUFTRAG=\"$auf\"");

  return 1;
}
1;
