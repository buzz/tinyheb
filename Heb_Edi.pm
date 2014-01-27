# Package f�r elektronische Rechnungen

# $Id$
# Tag $Name$

# Copyright (C) 2005 - 2014 Thomas Baum <thomas.baum@arcor.de>
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

package Heb_Edi;

use strict;
use Date::Calc qw(Today_and_Now Today Decode_Month);
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

my %sondertarifkz = (); # Positionsnummern bei denen Sondertarif KZ mitgegeben werden muss

$sondertarifkz{$_}=1 for qw (9000 0900 9100 0910 9200 0920 9300 0930 9400 0940 9500 0950);

my $delim = "'\x0d\x0a"; # Trennzeichen
my $crlf = "\x0d\x0a";
my $openssl ='openssl';

my $TODAY_jmt = sprintf "%4.4u%2.2u%2.2u",Today();
#my $TODAY_jmt = '20120402';

$openssl = $h->win32_openssl() if ($^O =~ /MSWin32/);

our $path = $ENV{HOME}; # f�r tempor�re Dateien
if ($^O =~ /MSWin32/) {
  $path .='/tinyheb';
} else {
  $path .='/.tinyheb';
}
mkdir "$path" if(!(-d "$path"));
our $ERROR = '';

# suche nach Zertifikatspfad
my $cert_path='';
foreach my $file (@INC) {
  my $such_file = $file;
  $such_file = ($such_file eq '.') ? '' : $such_file;
#  print "suche nach $such_file \n";
  if (-r "$such_file"."certs/itsg1.pem") {
    $cert_path=$such_file;
    last;
  }
}

#print "CERT $cert_path\n";


sub new {
  my $class = shift;
  my $rechnr = shift;
  my $self = {@_};
  $self->{dbh} = $h->connect;

  # pr�fen auf openssl installation
  if(!($openssl)) {
    $ERROR="keine openssl Installation gefunden";
    return undef;
  }

  # Rahmendaten f�r Rechnung aus Datenbank holen
  $l->rechnung_such("RECH_DATUM,BETRAG,FK_STAMMDATEN,IK","RECHNUNGSNR=$rechnr");
  my ($rechdatum,$betrag,$frau_id,$ik)=$l->rechnung_such_next();
  if(!defined($rechdatum)) {
    $ERROR="Rechnung nicht vorhanden";
    return undef;
  }
#  $rechdatum =~ s/-//g;
  ($self->{rechdatum}=$rechdatum) =~ s/-//g;
  $betrag+=0.0;
  $self->{betrag}=$betrag;
  $self->{ik}=$ik;
  $self->{testind} = $k->krankenkasse_test_ind($ik);
  if (!defined($self->{testind})) {
    $ERROR="Keine Datennahmestelle vorhanden";
    return undef;
  }
  
  # pr�fen EMAIL der Hebamme vorhanden
  $self->{HEB_EMAIL}=$h->parm_unique('HEB_EMAIL');
  if (!defined($self->{HEB_EMAIL})) {
    $ERROR="E-Mail Adresse der Hebamme nicht bekannt,\nbitte in den Parametern nachpflegen\n";
    return undef;
  }

  $self->{HEB_IK}=$h->parm_unique('HEB_IK');
  if (!defined($self->{HEB_IK})) {
    $ERROR="IK-Nummer der Hebamme nicht bekannt,\nbitte in den Parametern nachpflegen\n";
    return undef;
  }

  # kostentr�ger ermitteln
  my ($ktr,$zik)=$k->krankenkasse_ktr_da($ik);
  $self->{kostentraeger}=$ktr;
  $self->{annahmestelle}=$zik;

  # pr�fen EMAIL der Annahmestelle vorhanden
  $self->{MAIL_ANNAHMESTELLE}=$h->parm_unique('MAIL'.$zik);
  if (!defined($self->{MAIL_ANNAHMESTELLE})) {
    $ERROR="E-Mail Adresse der Annahmestelle nicht bekannt,\nbitte in den Parametern Parameter MAIL$zik nachpflegen\n";
    return undef;
  }
  
  # physikalischen Empf�nger ermitteln
  my $empf_physisch=$k->krankenkasse_empf_phys($zik);
  if (!defined($empf_physisch)) {
    $ERROR="Physikalischer Empf�nger konnte f�r ZIK: $zik nicht ermittelt werden.\nBitte Hersteller benachrichtigen";
    return undef;
  }
  $self->{empf_physisch}=$empf_physisch;

  # Stammdaten Frau holen
  my ($vorname,$nachname,$geb_frau,$geb_kind,$plz,$ort,$tel,$strasse,
      $anz_kinder,$entfernung,$kv_nummer,$kv_gueltig,$versichertenstatus,
      $ik_krankenkasse,$naechste_hebamme,
      $begruendung_nicht_nae_heb,
      $kzetgt,
      $geb_zeit) = $s->stammdaten_frau_id($frau_id);
  
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

  $geb_zeit = '99:99' unless($geb_zeit);
  $geb_zeit =~ s/://g;
  $kzetgt=2 unless($kzetgt);
  $geb_zeit = '9999' if ($kzetgt==2);
  $self->{kzetgt}=$kzetgt;
  $self->{geb_zeit}=$geb_zeit;
  $self->{geb_kind}=$geb_kind;
  $self->{vorname}=$vorname;
  $self->{nachname}=$nachname;
  $self->{geb_frau}=$geb_frau;
  $self->{plz}=$plz;
  $self->{ort}=$ort;
  $self->{strasse}=$strasse;
  $self->{kv_nummer}=$kv_nummer;
  $self->{kv_gueltig}=$kv_gueltig;
  $self->{versichertenstatus}=$versichertenstatus;
  if (lc $versichertenstatus eq 'privat' ||
      lc $versichertenstatus eq 'soz') {
    $ERROR="F�r $versichertenstatus Versicherte kann keine elektronische Rechnung generiert werden\nBitte Stammdaten korrigieren\n";
    return undef;
  }
  $self->{anz_kinder}=$anz_kinder || 1;
  bless $self, ref $class || $class;

  my (undef,$betrag_slla)=$self->SLLA($rechnr,$zik,$ktr);
  if ($betrag_slla ne $self->{betrag}) {
    $ERROR="Betragsermittlung zu Papierrechnung unterschiedlich Edi Betrag:$betrag_slla, Papier: $betrag!!!\nBitte Hersteller benachrichtigen\n";
    return undef;
  }

  my $sig_flag = $h->parm_unique('SIG'.$zik);
  if (!defined($sig_flag)) {
    $ERROR= "Parameter f�r Signatur bei Datennahmestelle $zik fehlt.\nBitte Parameter SIG$zik pflegen\n";
    return undef;
  }
  $self->{sig_flag}=$sig_flag;
  if ($sig_flag > 0 && !defined($self->{sig_pass})) {
    $ERROR ="Rechnung soll signiert werden, aber kein Passwort angegeben.\n";
    return undef;
  } 

  my $schl_flag = $h->parm_unique('SCHL'.$zik);
  if (!defined($schl_flag)) {
    $ERROR= "Parameter f�r Verschl�sselung bei Datennahmestelle $zik fehlt.\nBitte Parameter SCHL$zik pflegen\n";
    return undef;
  }
  $self->{schl_flag}=$schl_flag;

  # pr�fen, ob Datei verschl�sselt werden kann
  # w/ race conditions muss lock gesetzt werden
  $h->get_lock("EDI");
  my ($hilf_nutz,$hilf_erstell)=$self->gen_nutz($rechnr,$zik,$ktr,1);
  unlink("$path/tmp/test_enc");
  unlink("$path/tmp/test_enc.enc");
  unlink("$path/tmp/test_enc.sig");
  my $dateiname = 'test_enc';
  # Nutzdatendatei schreiben
  my $descriptor = open NUTZ, ">$path/tmp/$dateiname";
  if (!defined($descriptor)) {
    $ERROR= "Konnte Nutzdatei nicht zum Schreiben �ffnen $!\n";
    $h->release_lock("EDI"); # lock wieder freigeben
    return undef;
  }
  print NUTZ $hilf_nutz; # Nutzdaten in Hilfsdatei schreiben
  close NUTZ;
  my $laenge_nutz=length($hilf_nutz);

  # hier muss noch verschl�sselt und signiert werden
  # Public key der Krankenkasse schreiben
  my ($pubkey) = $k->krankenkasse_sel("PUBKEY",$zik);
  $descriptor = open KWRITE,">$path/tmp/zik.pem";
  if (!defined($descriptor)) {
    $ERROR= "Konnte �ffentlichen Schl�ssel zu Datenannahmestelle $zik nicht schreiben, bitte pr�fen ob Schl�ssel vorhanden ist.\n$!\n";
    $h->release_lock("EDI"); # lock wieder freigeben
    return undef;
  }
  print KWRITE "-----BEGIN CERTIFICATE-----\n";
  print KWRITE $pubkey;
  print KWRITE "-----END CERTIFICATE-----\n";
  close(KWRITE);


  # signieren
  ($dateiname,$laenge_nutz)=$self->sig($dateiname,$sig_flag);
  if ($laenge_nutz == 0) {
    if ($sig_flag == 0) {
      $ERROR= "Nutzdaten konnten nicht signiert werden.\n$dateiname\nBitte OpenSSL Installation pr�fen\n $!";
    } else {
      $ERROR= "Nutzdaten konnten nicht signiert werden.\nBitte Passwort pr�fen $!";
      $ERROR= "Nutzdaten konnten nicht signiert werden.\n$dateiname" if($dateiname ne 'test_enc.sig');
    }
    $h->release_lock("EDI"); # lock wieder freigeben
    return undef;
  }
  # verschl�sseln
  ($dateiname,$laenge_nutz)=$self->enc($dateiname,$schl_flag);
  if ($laenge_nutz == 0) {
    $ERROR= "Nutzdaten konnten nicht verschl�sselt werden.\n$dateiname\nBitte OpenSSL Installation pr�fen \n$!\n";
    $h->release_lock("EDI"); # lock wieder freigeben
    return undef;
  }

  $h->release_lock("EDI"); # lock wieder freigeben
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

  substr($st,78,15) = sprintf "%-15u", $self->{empf_physisch}; # Empf�nger, der die Daten physikalisch empfangen soll

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
  $erg .= 'F'; # Leistungsbereich nur bei Version 6
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
  $erg .= '+'; # Freifeld/ KZ Sammelabrechnung
  $erg .= $h->parm_unique('HEB_IK').'+'; # IK des Leistungserbringers
  $erg .= $ik_kostentraeger.'+'; # IK des Kostentr�gers
  $erg .= $ik_krankenkasse.'+'; # IK der Krankenkasse
  $erg .= $h->parm_unique('HEB_IK');
  $erg .= $delim; # Zeilentrennung anf�gen.

  return $erg;
}


sub SLGA_REC {
  # generiert SLGA REC Segment 

  my $self=shift; # package Namen vom stack nehmen

  my ($rechnr,$rechdatum) = @_;

  my $erg = 'REC+';
  $erg .= $rechnr.':0+'; # Rechnungsnummer, hier Einzel-Rechnungsnummer
  $erg .= $rechdatum.'+'; # Rechnungsdatum
  $erg .= '1'; # Rechnungsart 1 = Abrechnung von LE und Zahlung an LE
  $erg .= $delim; # Zeilentrennung anf�gen

  return $erg;
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
  $gesamtsumme = sprintf "%.2f",$gesamtsumme;
  $gesamtsumme =~ s/\./,/g;

  my $erg = 'GES+';
  $erg .= $status.'+'; # Status 00 = Gesamtsumme aller Stati
  $erg .= $gesamtsumme; # Gesamtrechnungsbetrag
  $erg .= '+'.$gesamtsumme; # Gesamtbruttobetrag
  # Gesamtbetrag Zuzahlungen nicht �bermitteln
  # weil K Feld und identisch zu Gesamtrechnungsbetrag
  $erg .= $delim; # Zeilentrennung anf�gen

  return $erg;
}



sub SLGA_NAM {
  # generiert SLGA_NAM Segment
  # ist f�r Version 6.0 identisch

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
  # Version6 fast identisch , siehe W�hrungskennzeichen

  my $self=shift; # package Namen vom stack nehmen

  my ($rechnr,$rechdatum) = @_;

  my $erg = 'REC+';
  $erg .= $rechnr.':0+'; # Rechnungsnummer
  $erg .= $rechdatum.'+'; # Rechnungsdatum
  $erg .= '1'; # Rechnungsart 1 = Abrechnung von LE und Zahlung an LE
  $erg .= $delim; # Zeilentrennung anf�gen

  return $erg;
}



sub SLLA_INV {
  # generiert SLLA INV Segment
  # zu Version 6 fast identisch, siehe Feld besondere Versorgungsform
  
  my $self=shift; # package Namen vom stack nehmen

  my ($kvnr,$kvstatus,$rechnr) = @_;

  my ($kvs_1,$kvs_2)= split ' ',$kvstatus;

  my $erg = 'INV+';
  $erg .= $kvnr.'+'; # Krankenversicherungsnummer
  $erg .= $kvs_1.'000'.$kvs_2.'+'; # Versichertenstatus
  $erg .= '+'; # Freifeld
  $erg .= $rechnr; # Belegnummer
  # ab Version 6 gibt es Feld besondere Versorgungsform, wird weggelassen,
  # da optional
  $erg .= $delim; # Zeilentrennung anf�gen

  return $erg;
}



sub SLLA_NAD {
  # generiert SLLA NAD Segment
  # Version 6 fast identisch, siehe Feld L�nderkennzeichen

  my $self=shift; # package Namen vom Stack nehmen

  my ($nachname,$vorname,$geb_frau,$strasse,$plz,$ort,$land) = @_;
  # Steuerzeichen aufbereiten
  $nachname =~ s/'/\?'/g;$nachname =~ s/\+/\?\+/g;
  $nachname = substr($nachname,0,47);
  $vorname =~ s/'/\?'/g;$vorname =~ s/\+/\?\+/g;
  $vorname = substr($vorname,0,30);
  $strasse =~ s/'/\?'/g;$strasse =~ s/\+/\?\+/g;
  $strasse = substr($strasse,0,30);
  $ort =~ s/'/\?'/g;$ort =~ s/\+/\?\+/g;
  $ort = substr($ort,0,25);
  unless($plz) {
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
  $erg .= "+$land" if ($land); # L�nderkennzeichen
  $erg .= $delim; # Zeilentrennung
  
  return $erg;
}



sub SLLA_HEB {
  # generiert SLLA HEB Segement, gibt es erst ab Version 7
  my $self=shift;
  my ($ik_hebamme) = @_;

  my $erg='HEB+';
  $erg .= $ik_hebamme.'+';
  $erg .= $h->parm_unique('HEB_IK_BELEG_KKH'); # IK Belegkrankenhaus
  $erg .= $delim;
  
  return $erg;
}


sub SLLA_HEL {
  # generiert SLLA HEL Segment, gibt erst ab Version 6
  my $self=shift;
  my ($datum)=@_;

  my $erg='HEL+';
  $erg .= $datum; # Tag der Leistungserbringung
  $erg .= $delim; # Zeilentrennung
  
  return $erg;
}


sub SLLA_EHB {
  # generiert SLLA EHB Segment
  # Einzelfallnachweis Hebammen

  my $self=shift; # package Namen vom Stack nehmen

  my($posnr,$preis,$menge,$zeit_von,$zeit_bis,$dauer,$pzn) = @_;

  $zeit_von =~ s/://g if ($zeit_von);
  $zeit_bis =~ s/://g if ($zeit_bis);
  
  $menge = sprintf "%.2f",$menge;
  $menge =~ s/\./,/g;

  my $erg = 'EHB+';
  if ($sondertarifkz{$posnr}) {
    $erg .= '50:'.$h->parm_unique('HEB_TARIFKZ').'001+'; # Abrechnungscode 50 Hebamme Sondertarik 001 = mit Sondertarif w/ Betriebskostenpauschale
  } else {
    $erg .= '50:'.$h->parm_unique('HEB_TARIFKZ').'000+'; # Abrechnungscode 50 Hebamme Sondertarik 000 = ohne Sondertarif
  }
  $erg .= $posnr.'+'; # Art der Leistung gem 8.2.6 PosNr
  $erg .= "$menge+"; # Anzahl der Abrechnungspositionen
  $preis = sprintf "%.2f",$preis;
  $preis =~ s/\./,/g;
  $erg .= $preis.'+'; # Einzelpreis der Abrechnungsposition
#  $erg .= $pzn ? sprintf "%7.7u+",$pzn : '+'; # Pharmazentralnummer nur angeben, wenn vorhanden
  # ab Version 8 ist die PZN 8-stellig alpha, Datenhaushalt muss ge�ndert werden
  $erg .= $pzn ? sprintf "%u+",$pzn : '+'; # Pharmazentralnummer nur angeben, wenn vorhanden
  $erg .= $zeit_von ? "$zeit_von+" : "+"; # Uhrzeit von
  $erg .= $zeit_bis ? "$zeit_bis+" : "+"; # Uhrzeit bis
  $erg .= $dauer ? "$dauer+" : "+"; # Dauer
  # erg .= '+'; # gefahrene Kilometer entf�llt
  # Angaben bzgl. Abfahrtsort und Zielort entfallen, da kann Felder
  # erst wenn diese angegeben werden m�ssen wird eingebaut
  $erg .= $delim;

  return $erg;
}




sub SLLA_TXT {
  # generiert SLLA TXT Segment

  my $self=shift;
  
  my ($text)=@_;
  $text =~ s/'/\?'/g;$text =~ s/\+/\?\+/g; # Steuerzeichen aufbereiten
  $text =~ s/,/\?\,/g;
  $text = substr($text,0,70);

  my $erg = 'TXT+';
  $erg.= $text;
  $erg .= $delim;

  return $erg;
}


sub SLLA_ZHB {
  # generiert SLLA ZHB Segment Zusatzinfo Fall Hebammen
  # ab Version 6 vorhanden

  my $self=shift;
  my ($dia_datum)=@_;

  my $erg = 'ZHB+';
  # IK Nummer Hebamme wird in Version 7 nicht mehr ben�tigt
  #$erg .= $self->{HEB_IK}.'+'; # IK der behandelnden Hebamme
  # IK Belegkrankenhaus wird in Version 7 nicht mehr ben�tigt
  #$erg .= $h->parm_unique('HEB_IK_BELEG_KKH').'+'; # IK Belegkrankenhaus
  # $erg .= '999999999+'; # Betriebsst�ttennummer default angeben, bis Beschw.
  $erg .= '+'; # Betriebsst�ttennummer kann Feld
  $erg .= '+'; # Vertragsarztnummer kann Feld
  $erg .= $self->{kzetgt}.':'.$self->{geb_kind}.'+'; # Geburtsdatum kind
  $erg .= $self->{geb_zeit}.'+'; # Geburtszeit
  $erg .= $dia_datum ? $dia_datum.'+' : '+'; # Anordnungsdatum falls vorhanden
  $erg .= $self->{anz_kinder};
  $erg .= $delim;
  
  return $erg;
}



sub SLLA_DIA {
  # generiert SLLA DIA Segment Diagnose Fall Hebammen
  # ab Version 6 vorhanden

  my $self=shift;
  my ($dia_schl,$dia_text)=@_;

  return if(!$dia_schl && !$dia_text); # nix erzeugen, wenn keine Diagnose

  my $erg = 'DIA+';
  $erg .= $dia_schl ? $dia_schl.'+' : '+'; # Diagnose Schl�ssel
  $erg .= $dia_text ? $dia_text : ''; # Diagnose Text
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


sub UNH {
  # generiert UNH Segment

  my $self=shift;

  my ($lfdnr,$typ)=@_;
  $lfdnr = sprintf "%5.5u",$lfdnr;

  my $erg = 'UNH+';
  $erg .= $lfdnr.'+'; # laufender Nummer der UNH Segmente
  $erg .= $typ;
  # Nachrichtenkennung ab 01.04.2012 Version 07
  # ab 01.01.2013 Version 08, �bergangsregelung bis 31.03.2013
  # ab 01.10.2013 Version 09

  $erg .= ':09:0:0';
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
  # Version 6 identisch 
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
    die "Betragsermittlung zu Papierrechnung unterschiedlich Edi:$betrag_slla, Papier: $betrag!!!\n";
  }
  
  $erg .= $self->SLGA_GES($betrag_slla,'00');$lfdnr++;

  # 5. Schl�ssel Summenstatus ermitteln und GES Segment erzeugen
  my $summenstatus = '';
  my ($kvs_1,$kvs_2) = split ' ',$self->{versichertenstatus};
  # 1. Spalte
  $summenstatus = '99'; # Default
  $summenstatus = '11' if ($self->{versichertenstatus} eq '1 1'); # Mit. West
  $summenstatus = '19' if ($self->{versichertenstatus} eq '1 9'); # Mit. Ost
  $summenstatus = '31' if ($self->{versichertenstatus} eq '3 1'); # Ange West
  $summenstatus = '39' if ($self->{versichertenstatus} eq '3 9'); # Ange Ost
  $summenstatus = '51' if ($self->{versichertenstatus} eq '5 1'); # Rent West
  $summenstatus = '59' if ($self->{versichertenstatus} eq '5 9'); # Rent West
  $summenstatus = '07' if ($kvs_2 eq '7'); # Ausl�nder

#  print "summenstatus: $summenstatus\n";
  $erg .= $self->SLGA_GES($betrag_slla,$summenstatus);$lfdnr++;
  
  # 6. NAM Segment erzeugen
  $erg .= $self->SLGA_NAM();$lfdnr++;

  # 7. UNT Segment erzeugen
  $erg .= $self->UNT($lfdnr+1,$ref);
  
  $self->{SLGA}=$erg;
  return $erg;
}




sub SLLA {
  # generiert kompletten Nachrichtentyp SLLA nach Version 6
  # inkl. Kopf und Endesegment

  my $self=shift;

  my ($rechnr,$zik,$ktr) = @_;
  my $lfdnr = 1; # muss mit 1 beginnen sonst keine korrekte Z�hlung
  my $gesamtsumme = 0.00; # summe aller Rechnungsbetr�ge
  my $ref=2; # Nachrichtenreferenznummer, fortlaufende Nummer der UNH
  ;;;;;;;;;;;# Segemente zw. UNB und UNZ, d.h.hier immer 2 weil nach SLGA
  my $erg=''; # komplettes Ergebniss
  my $summe_km=0; # summe des Kilometergeldes

  # angaben zur Diagnose merken, falls vorhanden
  my $dia_schl = '';
  my $dia_text = '';
  my $dia_datum = '';

  # Kopfsegment UNH produzieren
  $erg .= $self->UNH($ref,'SLLA');$lfdnr++;
  
  my $rechdatum = $self->{rechdatum};
  my $betrag = $self->{betrag};
  my $test_ind = $self->{testind};
  my $ik = $self->{ik}; # IK Nummer der Krankenkasse

  
  # 1. FKT Segment erzeugen
  $erg .= $self->SLLA_FKT($self->{kostentraeger},$ik);$lfdnr++;
  # 2. REC Segment erzeugen
  $erg .= $self->SLLA_REC($rechnr,$self->{rechdatum});$lfdnr++;
  # 3. INV Segment erzeugen
  $erg .= $self->SLLA_INV($self->{kv_nummer},
			  $self->{versichertenstatus},
			  $rechnr);$lfdnr++;
  # 4. NAD Segment erzeugen
  $erg .= $self->SLLA_NAD($self->{nachname},
			  $self->{vorname},
			  $self->{geb_frau},
			  $self->{strasse},
			  $self->{plz},
			  $self->{ort},
			  $self->{land});
  $lfdnr++;

  # 5. HEB Segment generieren, erst nachdem 01.04.2012
  if ($TODAY_jmt > 20120331) {
    $erg .= $self->SLLA_HEB($h->parm_unique('HEB_IK'));
    $lfdnr++;
  }

  # 6. HEL Segmente generieren
  # Schleife �ber Tage an denen Leistungen erbracht wurden
  my %ges_sum;$ges_sum{A}=0;$ges_sum{C}=0;$ges_sum{M}=0;$ges_sum{B}=0;
  my $lleist=new Heb_leistung;
  $lleist->leistungsdaten_such_rechnr("distinct DATUM",$rechnr.' order by DATUM');

  while (my ($leisttag)=$lleist->leistungsdaten_such_rechnr_next()) {
    $leisttag =~ s/-//g;
    # HEL Segment
    $erg .= $self->SLLA_HEL($leisttag);$lfdnr++;

    # EHB Segmente generieren
    $l->leistungsdaten_such_rechnr("*",$rechnr." and DATUM=$leisttag order by ID");
    
    while (my @leistdat=$l->leistungsdaten_such_rechnr_next()) {
      my $txt_kz=0; # Kennzeichen, ob schon txt Segment generiert wurde
      $leistdat[5]=substr($leistdat[5],0,5); # nur HH:MM aus Ergebniss
      $leistdat[6]=substr($leistdat[6],0,5); # nur HH:MM aus Ergebniss

      warn "Bearbeite Position: ",(join ":",@leistdat) if ($debug > 100);

      # a. zuerst normale posnr f�llen
      my ($bez,$fuerzeit,$epreis,$ltyp,$zus1,$pzn)=$l->leistungsart_such_posnr("KBEZ,FUERZEIT,EINZELPREIS,LEISTUNGSTYP,ZUSATZGEBUEHREN1,PZN ",$leistdat[1],$leistdat[4]);
      my $fuerzeit_flag='';
      my $dauer=0;
      my $anzahl=1; # Default, wenn keine Zeitangabe notwendig
      ($fuerzeit_flag,$fuerzeit)=$d->fuerzeit_check($fuerzeit);

      # pr�fen ob Zeitangabe notwendig 
      my $datum_jmt = $leistdat[4];
      my ($zeit_von,$zeit_bis) = $l->timetoblank($leistdat[1],    # posnr
						 $fuerzeit,       # fuerzeit
						 $datum_jmt,   # datum
						 $leistdat[5],   # zeit von
						 $leistdat[6]);  # zeit bis
      if ($fuerzeit) {
	$dauer = $d->dauer_m($leistdat[6],$leistdat[5]);
	$anzahl = sprintf "%3.2f",$h->runden($dauer / $fuerzeit);
	# pr�fen, ob Minuten genau abgerechnet werden muss
	if ($fuerzeit_flag ne 'E') { # nein
	  $anzahl = sprintf "%2.2u",$anzahl;
	  $anzahl++ if ($anzahl*$fuerzeit < $dauer);
	}
      } 
      else {
	# Zeiten ggf. �bertragen
	($leistdat[5],$leistdat[6])=($zeit_von,$zeit_bis);
      }
      $leistdat[4] =~ s/-//g; # Datum in korrektes Format bringen
      
      # EHB Segment ausgeben
      if($ltyp ne 'M') { 
	# keine Materialpauschale
	if($epreis > 0) { # hier wird nicht prozentual gerechnet
	  $erg .= $self->SLLA_EHB($leistdat[1], # POSNR
				  $epreis,
				  $anzahl,
				  $leistdat[5], # Zeit von
				  $leistdat[6], # Zeit bis
				  $dauer);
	  $gesamtsumme += sprintf "%.2f",$h->runden($epreis*$anzahl);
	  my $wert= sprintf "%.2f",$h->runden($epreis*$anzahl);
	  $ges_sum{$ltyp} += $wert;
	} else {
	  $erg .= $self->SLLA_EHB($leistdat[1],  # POSNR
				  $leistdat[10], # Preis
				  $anzahl,
				  $leistdat[5], # Zeit von
				  $leistdat[6], # Zeit bis
				  $dauer);
	  $gesamtsumme += sprintf "%.2f",$h->runden($leistdat[10]*$anzahl);
	  $ges_sum{$ltyp} += (sprintf "%.2f",$h->runden($leistdat[10]*$anzahl));
	}
	$lfdnr++;


      } else {
	# Materialpauschale 
	# Pr�fen, welche Positionsnumer genutzt werden muss
	if ($leistdat[1] =~ /^[A-Z]\d{1,4}$/) {
	  # es muss zugeordnete Positionsnummer geben, diese steht in $zus1
	  # f�r diesen Fall muss Pharmazentralnummer �bermittelt werden
	  $zus1 = 70 if (!$zus1 &&
			 $leistdat[4] < 20070801);
	  $zus1 = 800 if (!$zus1 &&
			  $leistdat[4] >= 20070801 && $leistdat[4] < 20100101);
	  $zus1 = 8000 if (!$zus1 and 
			  $leistdat[4] >= 20100101);

	  
	  $erg .= $self->SLLA_EHB($zus1,
				  $leistdat[10],
				  1,
				  undef,
				  undef,
				  undef,
				  $pzn);
	  $lfdnr++;
	  # Text mit ausgeben
	  $erg .= $self->SLLA_TXT($bez);$lfdnr++;
	  $txt_kz++;
	} elsif ($leistdat[1] =~ /^\d{1,4}$/) {
	  $erg .= $self->SLLA_EHB($leistdat[1],
				  $leistdat[10],
				  1);
	  $lfdnr++;
	} else {
	  $ERROR="Materialpauschale konnte nicht ermittelt werden\n";
	  return undef;
	}
      
	$gesamtsumme += sprintf "%.2f",$h->runden($leistdat[10]);
	$ges_sum{$ltyp} += sprintf "%.2f",$h->runden($leistdat[10]);
      }
      
      # gesamtsumme muss gerundet werden, weil es sonst bei der Addition zu
      # Rundungsfehlern kommen kann
      $gesamtsumme = $h->runden($gesamtsumme);
      print "Zwischensumme ohne Wegegeld: $gesamtsumme\n" if ($debug>100);
      print "Typ A:",$ges_sum{A},"\tTyp B:",$ges_sum{B},"\tTyp C:",$ges_sum{C},"\tTyp M:",$ges_sum{M},"\n" if ($debug > 50);
      
      
      # b. Begr�ndungstexte ausgeben
      if ($leistdat[3] && !$txt_kz) { # Begr�ndung ausgeben
	$erg .= $self->SLLA_TXT($leistdat[3]);$lfdnr++;
	# pr�fen ob sp�ter DIA Segment ausgegeben werden muss
	if ($leistdat[3] =~ /Attest/ && 
	    !$dia_schl && !$dia_text && !$dia_datum &&
	    ($leistdat[13] || $leistdat[14])) {
	  ($dia_datum,$dia_schl,$dia_text) = 
	    ($leistdat[4],$leistdat[13],$leistdat[14]);
	}
      }

      # d. Kilometergeld ausgeben
      my $posnr_wegegeld='';
      $leistdat[7] = sprintf "%.2f",$leistdat[7]; # w/ Rundungsfehlern
      $leistdat[8] = sprintf "%.2f",$leistdat[8]; # w/ Rundungsfehlern
      
      # Unterscheidung alte/neue Positionsnummern
      if ($leistdat[4] < 20070801) {
	$posnr_wegegeld='91' if ($leistdat[7] > 0 && $leistdat[7] <= 2);# Tag <= 2
	$posnr_wegegeld='93' if ($leistdat[7] > 0 && $leistdat[7] > 2 ); # Tag > 2
      } 
      if ($leistdat[4] < 20100101 && $leistdat[4] >= 20070801) {
	$posnr_wegegeld='300' if ($leistdat[7] > 0 && $leistdat[7] <= 2);# Tag <= 2
	$posnr_wegegeld='320' if ($leistdat[7] > 0 && $leistdat[7] > 2 ); # Tag > 2
      }
      if ($leistdat[4] >= 20100101) { # PosNr ab 01.01.2010
	$posnr_wegegeld='3000' if ($leistdat[7] > 0 && $leistdat[7] <= 2);# Tag <= 2
	$posnr_wegegeld='3200' if ($leistdat[7] > 0 && $leistdat[7] > 2 ); # Tag > 2
      }
      



      if ($posnr_wegegeld) { # es muss wegegeld gerechnet werden
	($epreis)=$l->leistungsart_such_posnr("EINZELPREIS",$posnr_wegegeld,$leistdat[4]);
	my $anteilig='';
	if ($leistdat[9] > 1) {
	  $anteilig='a' if ($leistdat[4] < 20070801);# ant. Wegegeld alt
	  $posnr_wegegeld += 1 if ($leistdat[4] >= 20070801 && 
				   $leistdat[4] < 20100101);# ant. Wegegeld neu
	} elsif ($leistdat[4] >= 20100101) {
	  # besondere Regel ab 2010 letzte Ziffer muss wie letzte Ziffer 
	  # bei Abrechnungsposnr sein, falls nicht anteilig
	  my $letzte_ziffer = $leistdat[1];
	  $letzte_ziffer =~ /(\d{4})/;
	  $letzte_ziffer=substr($letzte_ziffer,-1,1);
	  $posnr_wegegeld+=$letzte_ziffer;
	}

	if ($posnr_wegegeld eq '91' || 
	    $posnr_wegegeld eq '300' ||
	    $posnr_wegegeld eq '301' ||
	    $posnr_wegegeld eq '3000' ||
	    $posnr_wegegeld eq '3001' ||
	    $posnr_wegegeld eq '3002' ||
	    $posnr_wegegeld eq '3010' ||
	    $posnr_wegegeld eq '3011' ||
	    $posnr_wegegeld eq '3012') {
	  $erg .= $self->SLLA_EHB($posnr_wegegeld.$anteilig,
				  $epreis,
				  1);
	  $lfdnr++;
	  $summe_km+=$epreis;
	  print "Wegegeld summe: $summe_km, $epreis\n" if ($debug > 1000);
	} elsif ($posnr_wegegeld eq '93' || 
		 $posnr_wegegeld eq '320' ||
		 $posnr_wegegeld eq '321' ||
		 $posnr_wegegeld eq '3200' ||
		 $posnr_wegegeld eq '3201' ||
		 $posnr_wegegeld eq '3202' ||
		 $posnr_wegegeld eq '3210' ||
		 $posnr_wegegeld eq '3211' ||
		 $posnr_wegegeld eq '3212'
		) {
	  $erg .= $self->SLLA_EHB($posnr_wegegeld.$anteilig,
				  $epreis,
				  $leistdat[7]);
	  $lfdnr++;
	  my $km_preis = sprintf "%.2f",$h->runden($leistdat[7]*$epreis);
	  $summe_km+=$km_preis;
	  print "Wegegeld summe: $summe_km, $km_preis,km: $leistdat[7]\n" if ($debug > 1000);
	} 
      }

      $posnr_wegegeld='';
      # Unterscheidung alte/neue Positionsnummern
      if ($leistdat[4] < 20070801) {
	$posnr_wegegeld='92' if ($leistdat[8] > 0 && $leistdat[8] <= 2);# Nacht <= 2
	$posnr_wegegeld='94' if ($leistdat[8] > 0 && $leistdat[8] > 2); # Nacht > 2
      }
      if ($leistdat[4] < 20100101 && $leistdat[4] >= 20070801) {
	$posnr_wegegeld='310' if ($leistdat[8] > 0 && $leistdat[8] <= 2);# Nacht <= 2
	$posnr_wegegeld='330' if ($leistdat[8] > 0 && $leistdat[8] > 2); # Nacht > 2
      }
      if ($leistdat[4] >= 20100101) { # PosNr ab 01.01.2010
	$posnr_wegegeld='3100' if ($leistdat[8] > 0 && $leistdat[8] <= 2);# Nacht <= 2
	$posnr_wegegeld='3300' if ($leistdat[8] > 0 && $leistdat[8] > 2); # Nacht > 2
      }


      
      if ($posnr_wegegeld) { # es muss wegegeld gerechnet werden
	($epreis)=$l->leistungsart_such_posnr("EINZELPREIS",$posnr_wegegeld,$leistdat[4]);
	my $anteilig='';
	if ($leistdat[9] > 1) {
	  $anteilig='a' if ($leistdat[4] < 20070801);# ant. Wegegeld alt
	  $posnr_wegegeld += 1 if ($leistdat[4] >= 20070801 &&
				   $leistdat[4] < 20100101);# ant. Wegegeld neu
	} elsif ($leistdat[4] >= 20100101) {
          # besondere Regel ab 2010 letzte Ziffer muss wie letzte Ziffer 
          # bei Abrechnungsposnr sein, falls nicht anteilig
          my $letzte_ziffer = $leistdat[1];
          $letzte_ziffer =~ /(\d{4})/;
          $letzte_ziffer=substr($letzte_ziffer,-1,1);
          $posnr_wegegeld+=$letzte_ziffer;
        }

	
	if ($posnr_wegegeld eq '92' || 
	    $posnr_wegegeld eq '310' ||
	    $posnr_wegegeld eq '311' ||
	    $posnr_wegegeld eq '3100' ||
	    $posnr_wegegeld eq '3101' ||
	    $posnr_wegegeld eq '3102' ||
	    $posnr_wegegeld eq '3110' ||
	    $posnr_wegegeld eq '3111' ||
	    $posnr_wegegeld eq '3112'
	   ) {
	  $erg .= $self->SLLA_EHB($posnr_wegegeld.$anteilig,$epreis,1);
	  $lfdnr++;
	  $summe_km+=$epreis;
	  print "Wegegeld summe: $summe_km, $epreis\n" if ($debug > 1000);
	} elsif ($posnr_wegegeld eq '94' || 
		 $posnr_wegegeld eq '330' ||
		 $posnr_wegegeld eq '331' ||
		 $posnr_wegegeld eq '3300' ||
		 $posnr_wegegeld eq '3301' ||
		 $posnr_wegegeld eq '3302' ||
		 $posnr_wegegeld eq '3310' ||
		 $posnr_wegegeld eq '3311' ||
		 $posnr_wegegeld eq '3312'
		) {
	  $erg .= $self->SLLA_EHB($posnr_wegegeld.$anteilig,$epreis,$leistdat[8]);
	  $lfdnr++;
	  my $km_preis = sprintf "%.2f",$h->runden($leistdat[8]*$epreis);
	  $summe_km+=$km_preis;
	  print "Wegegeld summe: $summe_km, $km_preis\n" if ($debug > 1000);
	}
      }
      print "\n" if ($debug > 100);

    }
  }

  # 7 ZHB Segment erzeugen
  $erg .= $self->SLLA_ZHB($dia_datum);$lfdnr++;
  
  # 8 DIA Segment erzeugen
  if ($dia_schl || $dia_text) {
    $erg .= $self->SLLA_DIA($dia_schl,$dia_text);
    $lfdnr++;
  }

  # 9. BES Segment ausgeben
  $gesamtsumme += $summe_km;
  $gesamtsumme = $h->runden($gesamtsumme);
  $erg .= $self->SLLA_BES($gesamtsumme);

  # 10. UNT Endesegment ausgeben
  $erg .= $self->UNT($lfdnr+1,$ref);
  print "$gesamtsumme, $summe_km\n" if ($debug > 10);
  $self->{SLLA}=$erg;
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
      return ("konnte Datei nicht NICHT signieren\n",0);
  }
  if ($sig_flag == 2) {
    # PEM signieren
    return("PEM Signierung  ist nicht implementiert, bitte nutzen sie pkcs7\n",0);
  }
  if ($sig_flag == 3) {
    # DER signieren um sp�ter base64 encoden zu k�nnen
    return ("Kein eigenes Zertifikat unter $path/privkey/".$self->{HEB_IK}.".pem  vorhanden, die Rechnung kann nicht signiert werden",0) if (!(-e "$path/privkey/".$self->{HEB_IK}.".pem"));

    my ($cert_info_text,$cert_info)=$self->get_cert_info("$path/privkey/".$self->{HEB_IK}.".pem");
    return ($cert_info_text,0) unless ($cert_info);

    return ("Kein eigener privater Schl�ssel vorhanden, die Rechnung kann nicht signiert werden",0) if (!(-e "$path/privkey/privkey.pem"));

    # 
    my $cert_opts='';
    $cert_opts=qq!-certfile "$cert_path!.qq!certs/itsg8.pem"! if ($cert_info == 5);
    $cert_opts=qq!-certfile "$cert_path!.qq!certs/itsg7.pem"! if ($cert_info == 4);
    $cert_opts=qq!-certfile "$cert_path!.qq!certs/itsg6.pem"! if ($cert_info == 3);
    $cert_opts=qq!-certfile "$cert_path!.qq!certs/itsg4.pem"! if ($cert_info == 2);
    $cert_opts=qq!-certfile "$cert_path!.qq!certs/itsg2.pem"! if ($cert_info == 1);

    # pr�fen, ob Zertifikate der Zertifizierungskette geladen werden k�nnen
    if ($cert_info == 1 && !(-r "$cert_path".'certs/itsg2.pem')) {
      return ("Ein Zertifikat der Zertifizierungskette (itsg2.pem) konnte nicht gefunden werden",0);
    }
    if ($cert_info == 2 && !(-r "$cert_path".'certs/itsg4.pem')) {
      return ("Ein Zertifikat der Zertifizierungskette (itsg4.pem) konnte nicht gefunden werden",0);
    }
    if ($cert_info == 3 && !(-r "$cert_path".'certs/itsg6.pem')) {
      return ("Ein Zertifikat der Zertifizierungskette (itsg6.pem) konnte nicht gefunden werden",0);
    }  
    if ($cert_info == 4 && !(-r "$cert_path".'certs/itsg7.pem')) {
      return ("Ein Zertifikat der Zertifizierungskette (itsg7.pem) konnte nicht gefunden werden",0);
    }
    if ($cert_info == 5 && !(-r "$cert_path".'certs/itsg8.pem')) {
      return ("Ein Zertifikat der Zertifizierungskette (itsg8.pem) konnte nicht gefunden werden",0);
    }

#    print "OpenSSL Befehl: $openssl smime -sign -binary -in $path/tmp/$dateiname -nodetach -outform DER -signer $path/privkey/".$self->{HEB_IK}.".pem $cert_opts -passin pass:\" test \" -inkey $path/privkey/privkey.pem";

    open NUTZ, "$openssl smime -sign -binary -in $path/tmp/$dateiname -nodetach -outform DER -signer $path/privkey/".$self->{HEB_IK}.".pem $cert_opts -passin pass:\"$self->{sig_pass}\" -inkey $path/privkey/privkey.pem |" or
      return ("konnte Datei nicht DER signieren",0);
  }

  open AUS, ">$path/tmp/$dateiname.sig" or return ("Konnte Signierte Datei nicht schreiben",0);
    
 
  binmode NUTZ;
  binmode AUS;
 LINE: while (my $zeile=<NUTZ>) {
    print AUS $zeile;
  }
  my $cl=close NUTZ;
  print "CL wert sig: $cl,$?\n" if($debug > 1000);
  if (!$cl && $? != 0) {
    return("bitte Passwort pr�fen",0); # openssl hat Fehler gemeldet
  }
  close AUS;
 
  # L�nge der Datei ermitteln
  my $st=stat($path."/tmp/$dateiname.sig") or return ("konnte L�nge der signierten Nutzdaten nicht ermitteln",0);
  return ("$dateiname.sig",$st->size);
}


sub enc {
  # verschl�sselt Nutzdatendatei

  my $self=shift;

  my ($dateiname,$schl_flag)=@_;

  if ($schl_flag == 0) {
    # PEM verschl�sseln
    open NUTZ, "$path/tmp/$dateiname" or
      return ("konnte Datei nicht NICHT verschl�sseln",0);
  }
  if ($schl_flag == 2) {
    # PEM verschl�sseln
    return ("PEM Verschl�sselung ist nicht implementiert, bitte nutzen sie pkcs7\n",0);
    open NUTZ, "$openssl smime -encrypt -in $path/tmp/$dateiname -des3 -outform DER $path/tmp/zik.pem |" or
      die "konnte Datei nicht PEM verschl�sseln\n";
  }
  if ($schl_flag == 3) {
    # pr�fen, ob Schl�ssel noch g�ltig sind
    my ($cert_info_text,$cert_info)=$self->get_cert_info("$path/tmp/zik.pem"); 
    return ("�ffentlicher Schl�ssel der Datenannahmestelle abgelaufen oder $cert_info_text",0) unless ($cert_info);

    # DER verschl�sseln um sp�ter base64 encoden zu k�nnen
    open NUTZ, "$openssl smime -encrypt -binary -in $path/tmp/$dateiname -des3 -outform DER $path/tmp/zik.pem |" or return ("Konnte Datei nicht DER verschl�sseln",0);
  }

  $dateiname =~ s/\.sig//g;
  open AUS,">$path/tmp/$dateiname.enc" or return ("konnte verschl�sselte Nutzdaten nicht schreiben",0);
    
  binmode NUTZ;
  binmode AUS;
 LINE: while (my $zeile=<NUTZ>) {
    print AUS $zeile;
  }

  my $cl=close NUTZ;
  print "CL wert enc: $cl,$?\n" if($debug > 1000);
  if (!$cl && $? != 0) {
    return("konnte Nutzdaten nicht verschl�sseln, unbekanntes Problem aufgetreten",0); # openssl hat Fehler gemeldet
  }

  close AUS;
  
  # L�nge der Datei ermitteln
  my $st=stat($path."/tmp/$dateiname.enc") or return ("konnte L�nge der verschl�sselten Nutzdaten nicht ermitteln",0);
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

  $h->get_lock("EDI"); # lock damit DTAUS Nummer nicht mehrfach vergeben wird

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
  binmode NUTZ;
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
  $h->release_lock("EDI");
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



sub get_cert_info {
  # holt Informationen aus einem gegenen Zertifikat 
  # R�ckgabe Wert 1 Fehlerwert
  # R�ckgabe Wert 2 Ergebnis:
  #  1 == Zertifikat g�ltig Zertifizierungskette 1
  #  2 == Zertifikat g�ltig Zertifizierungskette 2
  #  3 == Zertifikat g�ltig Zertifizierungskette 3
  #  4 == Zertifikat g�ltig Zertifizierungskette 4
  #  0 == Zertifikat nicht g�ltig oder sonstiges Problem

  my $self=shift;
  my ($certfile) = @_;

  open LESNAME,"$openssl x509 -in $certfile -dates -serial -noout |" or return ("konnte keine Informationen zum Zertifikat $certfile lesen",0);

  my $guelt_von=undef;
  my $guelt_bis=undef;
  my $serial=undef;

  while (my $name=<LESNAME>) {
    if ($name =~ /^notBefore=(.*?)$/) {
      $guelt_von=$1;
    }
    if ($name =~ /^notAfter=(.*?)$/) {
      $guelt_bis=$1;
    }
    if ($name =~ /^serial=(.*?)$/) {
      $serial=hex($1);
    }
  }

  my $ret=close(LESNAME);
  return ("unbekanntes Problem in get_cert_info $?,$!,$ret",0) if ($? != 0);

  $guelt_bis=$d->extract_date($guelt_bis);
  $guelt_von=$d->extract_date($guelt_von);
  
#  warn "G�lt von,bis: $guelt_von bis $guelt_bis\n";
  return ("Zertifikat abgelaufen",0) if ($guelt_bis < $TODAY_jmt);
#  return ("Zertifikat noch nicht g�ltig",0) if ($guelt_von > $TODAY_jmt);
  
  return ("Zertifikat mit Zertifizierungscert 01",1) if ($guelt_von < 20071213);
  return ("Zertifikat mit Zertifizierungscert 14",2) if ($guelt_von < 20091210);
  return ("Zertifikat mit Zertifizierungscert 56",3) if ($guelt_von < 20111208);
  return ("Zertifikat mit Zertifizierungscert 67",4) if ($guelt_von < 20131204);
  return ("Zertifikat mit Zertifizierungscert x23 und x1e",5);

}

1;
