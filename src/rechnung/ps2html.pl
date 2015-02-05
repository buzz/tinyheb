#!/usr/bin/perl -w
# -d:ptkdb
# -wT

# Erzeugen einer Rechnung und Druckoutput (Postscript)

# $Id: ps2html.pl,v 1.62 2012-12-30 12:24:06 thomas_baum Exp $
# Tag $Name: not supported by cvs2svn $

# Copyright (C) 2005 - 2013 Thomas Baum <thomas.baum@arcor.de>
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

use lib "../";
#use Devel::Cover -silent => 'On';

#no warnings qw(redefine);

use PostScript::Simple;
use Date::Calc qw(Today);
use strict;
use CGI;
use CGI::Carp qw(fatalsToBrowser);

use Heb;
use Heb_stammdaten;
use Heb_krankenkassen;
use Heb_leistung;
use Heb_datum;
use tiny_string_helpers;

our $s = new Heb_stammdaten;
our $k = new Heb_krankenkassen;
our $l = new Heb_leistung;
our $d = new Heb_datum;
our $h = new Heb;

my $q = new CGI;

our @kinder = ('Einlinge','Zwillinge','Drillinge','Vierlinge');
our $frau_id = $q->param('frau_id') || -1;
#my $frau_id = $ARGV[0] || 6;
our $seite=1;
our $speichern = $q->param("speichern") || '';
$h->get_lock("RECHNR") if ($speichern eq 'save'); # rechnr sperren
our $rechnungsnr = 1+($h->parm_unique('RECHNR'));
our $datum = $ARGV[2] || $d->convert_tmj(sprintf "%4.4u-%2.2u-%2.2u",Today());

our $posnr=-1;
our $heb_bundesland = $h->parm_unique('HEB_BUNDESLAND') || 'NRW';


# zun�chst daten der Frau holen
our ($vorname,$nachname,$geb_frau,$geb_kind,$plz,$ort,$tel,$strasse,
    $anz_kinder,$entfernung_frau,$kv_nummer,$kv_gueltig,$versichertenstatus,
    $ik_krankenkasse,$naechste_hebamme,
    $begruendung_nicht_nae_heb,
    $kzetgt,$uhr_kind,$privat_faktor) = $s->stammdaten_frau_id($frau_id);

$entfernung_frau =~ s/\./,/g;
$plz = sprintf "%5.5u",$plz;


our ($name_krankenkasse,
     $kname_krankenkasse,
     $plz_krankenkasse,
     $plz_post_krankenkasse,
     $ort_krankenkasse,
     $strasse_krankenkasse,
     $postfach_krankenkasse) = $k->krankenkasse_sel('NAME,KNAME,PLZ_HAUS,PLZ_POST,ORT,STRASSE,POSTFACH',$ik_krankenkasse);

$name_krankenkasse = '' unless ($name_krankenkasse);
$kname_krankenkasse = '' unless ($kname_krankenkasse);
$plz_krankenkasse = 0 unless ($plz_krankenkasse);
$plz_post_krankenkasse = 0 unless ($plz_post_krankenkasse);
$strasse_krankenkasse = '' unless ($strasse_krankenkasse);
$postfach_krankenkasse = '' unless ($postfach_krankenkasse);
$ort_krankenkasse = '' unless ($ort_krankenkasse);
$plz_krankenkasse = sprintf "%5.5u",$plz_krankenkasse;
$plz_post_krankenkasse = sprintf "%5.5u",$plz_post_krankenkasse;


our $font ="Helvetica-iso";
our $font_b = "Helvetica-Bold-iso";
our $y_font = 0.410;

our $p = new PostScript::Simple(papersize => "A4",
#			       color => 1,
			       eps => 0,
			       units => "cm",
			       reencode => "ISOLatin1Encoding");

our $x1=2;
our $y1=0;

$p->newpage;
wasserzeichen();
anschrift();

# Betreff Zeile
$p->setfont($font_b,10);
my $betreff='Geb�hrenabrechnung nach';
if ($versichertenstatus ne 'privat') {
  $betreff.=" Hebammen-Verg�tungsvereinbarung";
} else {
  # Abfragen, welche privat Geb�hrenordnung wird genutzt
  $betreff.=" Hebammen-Verg�tungsvereinbarung ";
  if (uc $heb_bundesland eq 'NRW') {
    $betreff.="NRW";
  } elsif (uc $heb_bundesland eq 'BAYERN') {
    $betreff.="Bayern";
  } elsif (uc $heb_bundesland eq 'BERLIN') {
    $betreff.="Berlin";
  } elsif (uc $heb_bundesland eq 'BRANDENBURG') {
    $betreff.="Brandenburg";
  } elsif (uc $heb_bundesland eq 'NIEDERSACHSEN') {
    $betreff.="Niedersachsen";
  } elsif (uc $heb_bundesland eq 'HESSEN') {
    $betreff.="Hessen";
  } elsif (uc $heb_bundesland eq 'HAMBURG') {
    $betreff.= "Hamburg";
  } elsif (uc $heb_bundesland eq 'RHEINLAND-PFALZ') {
    $betreff.="Rheinland-Pfalz";
  } elsif (uc $heb_bundesland eq 'TH�RINGEN' || $heb_bundesland eq 'Th�ringen') {
    $betreff.="Th�ringen";
  } elsif (uc $heb_bundesland eq 'SACHSEN-ANHALT') {
    $betreff.="Sachsen-Anhalt";
  } elsif (uc $heb_bundesland eq 'SACHSEN') {
    $betreff.="Sachsen";
  } elsif (uc $heb_bundesland eq 'BADEN-W�RTTEMBERG' || $heb_bundesland eq 'Baden-W�rttemberg') {
    $betreff.="Baden-W�rttemberg";
    my $priv=0;
    $priv=$privat_faktor ? $privat_faktor : $h->parm_unique('PRIVAT_FAKTOR');
    $priv= sprintf "%.2f",$priv;
    $priv=~ s/\./,/g;
    $betreff.= " Faktor $priv";
      
  }  else {
    $betreff.="PRIVAT GEB�HRENORDNUNG UNBEKANNT, BITTE PARAMETER HEB_BUNDESLAND pflegen".uc $heb_bundesland;
  }
}




$p->text(2,19.7,$betreff);


fussnote(); # auf der ersten Seite explizit angeben

# Falz  ausgeben
$p->setlinewidth(0.02);
$p->line(0,19.2,0.5,19.2);
$p->line(20.4,19.2,21,19.2);
$p->setlinewidth(0.04);

# Rechnung ausgeben f�r Rechnungsteile A,B,C
$y1=18.5;
my $gsumme=0;
$gsumme +=print_teil('A') if ($l->leistungsdaten_offen($frau_id,'Leistungstyp="A"')>0);
$gsumme +=print_teil('B') if ($l->leistungsdaten_offen($frau_id,'Leistungstyp="B"')>0);
$gsumme +=print_teil('C') if ($l->leistungsdaten_offen($frau_id,'Leistungstyp="C"')>0);
$gsumme +=print_teil('D') if ($l->leistungsdaten_offen($frau_id,'Leistungstyp="D"')>0);

# Auslagen
$gsumme += print_material('M') if ($l->leistungsdaten_offen($frau_id,'Leistungstyp="M"','sort,ZUSATZGEBUEHREN1,DATUM'));


# Pr�fen auf Wegegeld
if ($l->leistungsdaten_offen($frau_id,'(ENTFERNUNG_T > 0 or ENTFERNUNG_N > 0)')>0) {
  neue_seite(7,'');
  $p->setfont($font_b,10);
  $p->text($x1,$y1,"Wegegeld");$y1-=$y_font;
  $p->setfont($font,10);
  $gsumme += print_wegegeld('N') if ($l->leistungsdaten_offen($frau_id,'ENTFERNUNG_N >0,ENTFERNUNG_N > 2','DATUM')>0);
  $gsumme += print_wegegeld('T') if ($l->leistungsdaten_offen($frau_id,'ENTFERNUNG_T >0, ENTFERNUNG_T > 2','DATUM')>0);
$gsumme += print_wegegeld('NK') if ($l->leistungsdaten_offen($frau_id,'ENTFERNUNG_N >0, ENTFERNUNG_N <= 2','DATUM')>0);
$gsumme += print_wegegeld('TK') if ($l->leistungsdaten_offen($frau_id,'ENTFERNUNG_T >0, ENTFERNUNG_T <= 2','DATUM')>0);
}


# Gesamtsumme ausgeben
$y1+=$y_font;$y1+=$y_font;
$y1-=0.05;
$p->setlinewidth(0.05);
$p->line(19.5,$y1,17.5,$y1);$y1-=$y_font-0.1;
$p->setfont($font_b,10);
$p->text(12.7,$y1,"Gesamtbetrag");
$p->setfont($font,10);
$gsumme = sprintf "%.2f",$gsumme;
$gsumme =~ s/\./,/g;
$p->text({align => 'right'},19.5,$y1,$gsumme." EUR"); # Gesamt Summe andrucken

$y1-=$y_font;$y1-=$y_font;
neue_seite(6);

# Begr�ndungen ausgeben
print_begruendung() if ($l->leistungsdaten_offen($frau_id,'BEGRUENDUNG <> ""')>0);
$y1-=$y_font;
neue_seite(7);



# Pr�fen ob auch elektronisch versand wird
if ($name_krankenkasse && $versichertenstatus ne 'privat' 
   && $versichertenstatus ne 'SOZ') {
  # pr�fen ob zu ik Zentral IK vorhanden ist
  my $text='';
  my ($ktr,$zik)=$k->krankenkasse_ktr_da($ik_krankenkasse);
  my $test_ind = $k->krankenkasse_test_ind($ik_krankenkasse);
  my ($kname_zik)=$k->krankenkasse_sel("KNAME",$zik);
  if ($zik  && $test_ind && $test_ind==1) {
    $p->text($x1,$y1,"Diese Rechnung wurde im Rahmen der Erprobungsphase des Datenaustausches im Abrechnungsverfahren");$y1-=$y_font;
    $p->text($x1,$y1,"nach �302 SGB V per E-Mail an die zust�ndige Datenannahmestelle ");$y1-=$y_font;
    $p->text($x1,$y1,"$zik ($kname_zik) geschickt.");$y1-=$y_font;$y1-=$y_font;
  } elsif (defined($zik) && $zik > 0 && defined($test_ind) && $test_ind==2) {
    $p->text($x1,$y1,"Diese Rechnung dient nur Ihren pers�nlichen Unterlagen, die Rechnung muss ausschlie�lich per");$y1-=$y_font;
    $p->text($x1,$y1,"E-Mail an die zust�ndige Datenannahmestelle geschickt werden.");$y1-=$y_font;
  }
}


# Abschlusstext ausgeben
neue_seite(7);
$p->text($x1,$y1, "Die abgerechneten Leistungen sind nach � 4 Nr. 14 UStG von der Umsatzsteuer befreit.");$y1-=$y_font;$y1-=$y_font;

if ($versichertenstatus ne 'privat' && $versichertenstatus ne 'SOZ') {
  $p->text($x1,$y1,"Bitte �berweisen Sie den Gesamtbetrag innerhalb der gesetzlichen Frist von drei Wochen nach");$y1-=$y_font;
  $p->text($x1,$y1,"Rechnungseingang unter Angabe der Rechnungsnummer.");
} else {
  $p->text($x1,$y1,"Bitte �berweisen Sie den Gesamtbetrag innerhalb der gesetzlichen Frist von 30 Tagen nach");$y1-=$y_font;
  $p->text($x1,$y1,"Rechnungseinang unter Angabe der Rechnungsnummer.");
}
$y1-=$y_font;$y1-=$y_font;$y1-=$y_font;
$p->text($x1,$y1,"Mit freundlichen Gr��en");

# Pr�fen ob es sich um elektronische Rechnung handelt und Begleitzettel f�r Urbelege
# ertellt werden muss
my $test_ind = $k->krankenkasse_test_ind($ik_krankenkasse);
if ($test_ind && $test_ind==2) {
  # Begleitzettel f�r Urbeleg erstellen
  urbeleg();
}


# in Browser schreiben, falls Windows wird PDF erzeugt, sonst Postscript
my $all_rech=$p->get();

#warn "User_agent: ",$q->user_agent;
#warn "OS :",$^O;

if ($q->user_agent !~ /Windows/ && $q->user_agent !~ /Macintosh/) {
  my $filename = string2filename("Rechnung_${nachname}_${rechnungsnr}.ps");
  print $q->header ( -type => "application/postscript", -expires => "-1d", -content_disposition => "inline; filename=$filename");
  $all_rech =~ s/PostScript::Simple generated page/${nachname}_${vorname}/g;
  print $all_rech;
}

if ($q->user_agent =~ /Windows/ || $q->user_agent =~ /Macintosh/) {
  my $filename = string2filename("Rechnung_${nachname}_${rechnungsnr}.pdf");
  print $q->header ( -type => "application/pdf", -expires => "-1d", -content_disposition => "inline; filename=$filename");
  if (!(-d "/tmp/wwwrun")) {
    mkdir "/tmp" if (!(-d "/tmp"));
    mkdir "/tmp/wwwrun";
  }
  unlink('/tmp/wwwrun/file.ps');
  $p->output('/tmp/wwwrun/file.ps');

  if ($^O =~ /linux/ || $^O =~ /darwin/) {
#    warn "Linux oder darwin";
    system('ps2pdf /tmp/wwwrun/file.ps /tmp/wwwrun/file.pdf');
  } elsif ($^O =~ /MSWin32/) {
    unlink('/tmp/wwwrun/file.pdf');
    my $gswin=$h->suche_gswin32();
    $gswin='"'.$gswin.'"';
    system("$gswin -q -dCompatibilityLevel=1.2 -dSAFER -dNOPAUSE -dBATCH -sDEVICE=pdfwrite -sOutputFile=/tmp/wwwrun/file.pdf -c .setpdfwrite -f /tmp/wwwrun/file.ps");
  } else {
    die "kein Konvertierungsprogramm ps2pdf gefunden\n";
  }

  open AUSGABE,"/tmp/wwwrun/file.pdf" or
    die "konnte Datei nicht konvertieren in pdf\n";
  binmode AUSGABE;
  binmode STDOUT;
  while (my $zeile=<AUSGABE>) {
    print $zeile;
  }
  close AUSGABE;
}

if ($speichern eq 'save') {
  # setzt alle Daten in der Datenbank auf Rechnung und speichert die Rechnung
  $datum = $d->convert($datum);
  $gsumme =~ s/,/\./g;
  $l->rechnung_ins($rechnungsnr,$datum,$gsumme,$frau_id,$ik_krankenkasse,$all_rech);
  rech_up('A');
  rech_up('B');
  rech_up('C');
  rech_up('D');
  rech_up('M');
  $h->release_lock("RECHNR");
}

#-----------------------------------------------------------------

sub rech_up {
  my ($typ)=@_;
    $l->leistungsdaten_offen($frau_id,"Leistungstyp='$typ'");
    while (my @erg=$l->leistungsdaten_offen_next()) {
      $l->leistungsdaten_up_werte($erg[0],"STATUS=20,RECHNUNGSNR='$rechnungsnr'");
    }
}


sub fussnote {
  $p->setfont($font, 10);
  $p->text(2,1.6, "Bankverbindung: Kto-Nr. ".$h->parm_unique('HEB_Konto').' '.$h->parm_unique('HEB_NAMEBANK').' BLZ '.$h->parm_unique('HEB_BLZ'));
  # Steuernummer ausgeben, wenn vorhanden
  if($h->parm_unique('HEB_STNR')) {
    $p->text(2,1.6-$y_font,'Steuernummer: '.$h->parm_unique('HEB_STNR'));
  }
}


sub kopfzeile {
  $seite++;
  $y1=27.8;
  $p->newpage;
  $p->setfont($font_b,10);
  $p->text(2,$y1,$h->parm_unique('HEB_VORNAME').' '.$h->parm_unique('HEB_NACHNAME'));
  $p->text(12.7,$y1,"Rechnung");
  $p->setfont($font,10);
  $p->text(15,$y1,"/Seite $seite");
  $y1-=$y_font;
  $p->text(2,$y1,"Hebamme");
  $p->text(12.7,$y1,"Nr.:");
  $p->text(15,$y1,$rechnungsnr);
  $p->text(17.3,$y1,$nachname);
  $y1-=0.1;
  $p->line(1.95,$y1,19.5,$y1);
  $y1-=$y_font,$y1-=$y_font;
}

sub wasserzeichen {
  if ($speichern ne 'save') {
    $p->setfont($font_b,60);
    $p->setcolour('grey70');
    $p->text( {rotate => 50,
	       align => 'center'},
	      21/2,28.6/2,"Rechnungsvorschau");
    $p->setcolour('black');
    $p->setfont($font,10);
  }
}


sub neue_seite {
  my ($abstand,$teil) = @_;
  $teil = '' if (!defined($teil));
  return if ($y1 > $abstand);
  kopfzeile();
  fussnote();
  wasserzeichen();
  $posnr=-1;
  my $text='';
  $text = 'A. Mutterschaftsvorsorge' if ($teil eq 'A');
  $text = 'B. Geburt' if ($teil eq 'B');
  $text = 'C. Wochenbett' if ($teil eq 'C');
  $text = 'D. sonstige Leistungen' if ($teil eq 'D');
  $text = 'Wegegeld bei Nacht' if ($teil eq 'N');
  $text = 'Wegegeld bei Tag' if ($teil eq 'T');
  $text = 'Wegegeld bei Tag Entfernung nicht mehr als 2 KM' if ($teil eq 'TK');
  $text = 'Wegegeld bei Nacht Entfernung nicht mehr als 2 KM' if ($teil eq 'NK');
  $text = 'Auslagen' if ($teil eq 'M');
  if ($teil eq 'A' or $teil eq 'B' or $teil eq 'C' or $teil eq 'D' or $teil eq 'M') {
    $p->setfont($font_b,10);
    $p->text($x1,$y1,$text);$y1-=$y_font;$y1-=$y_font;
    $p->setfont($font,10);
  }
  if ($teil eq 'N' || $teil eq 'T' || $teil eq 'TK' || $teil eq 'NK') {
    $p->setfont($font,10);
    $p->text($x1,$y1,$text);$y1-=$y_font;
  }
}    


sub print_begruendung {
    while (my @erg=$l->leistungsdaten_offen_next()) {
      my ($bez,$fuerzeit,$epreis)=$l->leistungsart_such_posnr("KBEZ",$erg[1],$erg[4]);
      my $datum = $d->convert_tmj($erg[4]);
      $p->text($x1,$y1,"Begr�ndung f�r $bez am $datum: $erg[3]");$y1-=$y_font;
      if ($erg[3] =~ /Attest/) {
	if ($erg[13]) {
	  $p->text($x1,$y1,"Diagnose Schl�ssel: $erg[13]");$y1-=$y_font;
	}
	if ($erg[14]) {
	  $p->text($x1,$y1,"Diagnose Text: $erg[14]");$y1-=$y_font;
	}	
      }
      neue_seite(4);
    }
    $y1-=$y_font;
  }


sub print_material {
  my ($typ) = @_;
  my $summe=0;
  my $posnr=-1;
  my $zus_posnr=-1;
  neue_seite(6);
  $p->setfont($font_b,10);
  $p->text($x1,$y1,'Auslagen');$y1-=$y_font;$y1-=$y_font;
  $p->setfont($font,10);
  NEXT: while (my @erg=$l->leistungsdaten_offen_next()) {
    my ($bez,$epreis,$zus1)=$l->leistungsart_such_posnr("KBEZ,EINZELPREIS,ZUSATZGEBUEHREN1 ",$erg[1],$erg[4]);

    if($erg[1] =~ /^\d{1,4}$/) { # 
      $bez = substr($bez,0,50);
      my $laenge_bez = length($bez)*0.2/2;
      if ($posnr ne $erg[1]) {
	# bei posnr wechsel posnr schreiben
	$p->text({align => 'center'},$x1+1,$y1,$erg[1]);
	$posnr=$erg[1];
	$p->text($x1+2,$y1,$bez);
      } else {
	# Hochkomma ausgeben, wenn keine Zeitangabe notwendig
	$p->text({align => 'center'},$x1+2+$laenge_bez,$y1,"\"");
      }
    } elsif($erg[1] =~ /^[A-Z]\d{1,4}$/) {
      # zugeordnete Posnr holen
      my $go_datum = $erg[4];
      $go_datum =~ s/-//g;
      $zus1=70 if ((!$zus1) &&
		   $go_datum < 20070801);
      $zus1=800 if ((!$zus1) &&
		    $go_datum >= 20070801 && $go_datum < 20100101);
      $zus1=8000 if ((!$zus1) && $go_datum >= 20100101);

      my($bez_zus)=$l->leistungsart_such_posnr("KBEZ","$zus1",$erg[4]);
      $bez_zus = substr($bez_zus,0,50);
      my $laenge_bez_zus = length($bez_zus)*0.2/2;
      if ($zus_posnr ne $zus1) {
	# bei �bergeordneter posnr wechsel posnr schreiben
	$p->text({align => 'center'},$x1+1,$y1,$zus1);
	$zus_posnr=$zus1;
	$posnr=$erg[1];
	$p->text($x1+2,$y1,$bez_zus);$y1-=$y_font;
	$p->text($x1+2,$y1,$bez);
      } elsif ($posnr ne $erg[1]) {
	$posnr=$erg[1];
	# bei wechsel posnr schreiben
	$p->text($x1+2,$y1,$bez);
      } else {
	# Hochkomma ausgeben, wenn kein Wechsel vorhanden
	$p->text({align => 'center'},$x1+2+$laenge_bez_zus,$y1,'"');	
      }
    }
    my $datum = $d->convert_tmj($erg[4]);
    $p->text({align => 'right'},15,$y1,$datum); # Datum andrucken
    my $gpreis = sprintf "%.2f",$erg[10];
    $summe+=$gpreis;$gpreis =~ s/\./,/g;
    $p->text({align => 'right'},17.3,$y1,$gpreis." EUR"); # Preis andrucken
    $y1-=$y_font;
    neue_seite(4,'M');
  }
  $y1+=$y_font-0.05;
  $p->line(17.4,$y1,15.1,$y1);$y1-=$y_font-0.1;
  my $psumme = sprintf "%.2f",$summe;$psumme =~ s/\./,/g;
  $p->text({align => 'right'},17.3,$y1,$psumme." EUR"); # Gesamt Summe andrucken
  $p->text({align => 'right'},19.5,$y1,$psumme." EUR"); # Gesamt erneut Summe andrucken
  $y1-=$y_font;$y1-=$y_font;
  return $summe;
}


sub print_wegegeld {
  my ($tn) = @_;
  my $text='';
  my $preis=0;
  my $summe=0;
  neue_seite(5);
  $text ='Wegegeld bei Nacht' if ($tn eq 'N');
  $text ='Wegegeld bei Tag' if ($tn eq 'T');
  $text ='Wegegeld bei Tag Entfernung nicht mehr als 2 KM' if ($tn eq 'TK');
  $text ='Wegegeld bei Nacht Entfernung nicht mehr als 2 KM' if ($tn eq 'NK');
  $p->text($x1,$y1,$text);$y1-=$y_font;
  while (my @erg=$l->leistungsdaten_offen_next()) {
    neue_seite(5,$tn);
    # richtige Positionsnummer Suchen
    my $go_datum = $erg[4];
    $go_datum =~ s/-//g;
    my $posnr=0;
    if ($go_datum < 20070801) {
      # Geb�hrenordnung mit alten Posnr
      $posnr = 94 if ($tn eq 'N');
      $posnr = 93 if ($tn eq 'T');
      $posnr = 91 if ($tn eq 'TK');
      $posnr = 92 if ($tn eq 'NK');
    }
    if ($go_datum < 20100101 && $go_datum >= 20070801) {
      # Geb�hrenordnung ab 01.08.2007
      $posnr = 330 if ($tn eq 'N');
      $posnr = 320 if ($tn eq 'T');
      $posnr = 300 if ($tn eq 'TK');
      $posnr = 310 if ($tn eq 'NK');
    }
    if ($go_datum >= 20100101) {
      # Geb�hrenordnung ab 01.01.2010 mit neuen PosNr
      $posnr = 3300 if ($tn eq 'N');
      $posnr = 3200 if ($tn eq 'T');
      $posnr = 3000 if ($tn eq 'TK');
      $posnr = 3100 if ($tn eq 'NK');
    }

    # Falls Privatrechnung und Baden-W�rttemberg andere Posnr benutzen
    if (uc $heb_bundesland eq 'BADEN-W�RTTEMBERG' &&
	$versichertenstatus eq 'privat') {
      $posnr = 'BW330' if ($tn eq 'N');
      $posnr = 'BW320' if ($tn eq 'T');
      $posnr = 'BW300' if ($tn eq 'TK');
      $posnr = 'BW310' if ($tn eq 'NK');
    }
    ($preis)=$l->leistungsart_such_posnr("EINZELPREIS","$posnr",$erg[4]);


    if ($versichertenstatus eq 'privat') {
      if (uc $heb_bundesland eq 'NIEDERSACHSEN' ||
	  uc $heb_bundesland eq 'HESSEN' ||
	  uc $heb_bundesland eq 'BAYERN' ||
	  uc $heb_bundesland eq 'HAMBURG') {
	if ($privat_faktor) {
	  $preis *= $privat_faktor;
	} else {
	  $preis *= $h->parm_unique('PRIVAT_FAKTOR');
	}
	$preis = sprintf "%.2f",$preis;
      }
    }
    $preis =~ s/\./,/g;

    my $datum = $d->convert_tmj($erg[4]);
    $p->text({align => 'right'},4,$y1,$datum); # Datum andrucken
    my $entf=0;
    $entf = sprintf "%.2f",$erg[7] if ($tn eq 'T');
    $entf = sprintf "%.2f",$erg[8] if ($tn eq 'N');
    my $entfp = $entf;
    $entfp =~ s/\./,/g;
    $preis =~s/\./,/g;
    $p->text({align => 'right'},7,$y1,"$entfp km") if ($entf>=2);
    $p->text(8,$y1,"(Anteil $erg[9] Besuche)") if ($erg[9]>1); # Anzahl Frauen
    $p->text({align => 'right'},13.0,$y1,"� $preis EUR");
    $preis =~ s/,/\./g;
    my $teilsumme = 0;
    $teilsumme = ($preis * $entf) if ($entf>=2);
    $teilsumme = $preis if($entf<2);
    $teilsumme = sprintf "%.2f",$h->runden($teilsumme);
    $summe += $teilsumme;
    my $gpreis = sprintf "%.2f",$h->runden($preis * $entf);
    $gpreis = $preis if($entf<2);
    $gpreis =~s/\./,/g;
    $p->text({align => 'right'},17.3,$y1,$gpreis." EUR"); # Preis andrucken
    $y1-=$y_font;
  }
  $y1+=$y_font-0.05;
  $p->line(17.4,$y1,15.1,$y1);$y1-=$y_font-0.1;

  $summe = $h->runden($summe); # w/ Rundungsfehler-
  my $psumme = sprintf "%.2f",$summe;$psumme =~ s/\./,/g;
  $p->text({align => 'right'},17.3,$y1,$psumme." EUR"); # Gesamt Summe andrucken
  $p->text({align => 'right'},19.5,$y1,$psumme." EUR"); # Gesamt erneut Summe andrucken
  $y1-=$y_font;$y1-=$y_font;
  return $summe;
}

sub print_teil {
  my ($teil) = @_;

  my $text='';
  my $summe=0;
  neue_seite(6);
  $text = 'A. Mutterschaftsvorsorge' if ($teil eq 'A');
  $text = 'B. Geburt' if ($teil eq 'B');
  $text = 'C. Wochenbett' if ($teil eq 'C');
  $text = 'D. sonstige Leistungen' if ($teil eq 'D');
  $p->setfont($font_b,10);
  $p->text($x1,$y1,$text);$y1-=$y_font;$y1-=$y_font;
  $p->setfont($font,10);
    my $hks=1; # Steuerung, ob Hochkomma w/ Wiederholung ausgegeben wird
  while (my @erg=$l->leistungsdaten_offen_next()) {
    my @erg2=$l->leistungsdaten_such_id($erg[0]);
    my ($bez,$fuerzeit,$epreis)=$l->leistungsart_such_posnr("KBEZ,FUERZEIT,EINZELPREIS ",$erg[1],$erg[4]);

    if ($epreis == 0) { # prozentuale Berechnung
      $epreis=$erg[10];
      $epreis = sprintf "%.2f",$epreis;
    }

    if ($versichertenstatus eq 'privat') {
      if($privat_faktor) {
	$epreis *= $privat_faktor;
      } else {
	$epreis *= $h->parm_unique('PRIVAT_FAKTOR');
      }
      $epreis = sprintf "%.2f",$epreis;
    }
    
    my $fuerzeit_flag='';
    ($fuerzeit_flag,$fuerzeit)=$d->fuerzeit_check($fuerzeit);
    $bez = substr($bez,0,60);
    my $laenge_bez = length($bez)*0.2/2;

    # Zeitangaben ggf. auf Blank setzen
    my ($zeit_von,$zeit_bis) = $l->timetoblank($erg[1],     # posnr
					       $fuerzeit,   # fuerzeit
					       $erg[4],     # datum
					       $erg2[5],    # zeit von
					       $erg2[6]);   # zeit bis

    if ($posnr ne $erg[1]) {
      # bei posnr wechsel posnr schreiben
      $p->text({align => 'center'},$x1+1,$y1,$erg[1]);
      $posnr=$erg[1];
      $p->text($x1+2,$y1,$bez);
      $hks=1; # es darf Hochkomma gesetzt werden

      if ($zeit_von || $zeit_bis) {
	$y1 -= $y_font;
	$hks=0; # nach Zeitangabe kein Hochkomma
      }
    } else {
      # Hochkomma ausgeben, wenn keine Zeitangabe notwendig
      unless ($zeit_von || $zeit_bis) {
	if ($hks) {
	  $p->text({align => 'center'},$x1+2+$laenge_bez,$y1,"\"");
	} else {
	  $p->text($x1+2,$y1,$bez);
	  $hks=1; # nach Bezeichnung darf Hochkoma kommen
	}
      }
    }
    
    # pr�fen ob Zeitangabe notwendig 
    my $vk = 1;
    if ($fuerzeit) {
      # fuerzeit ausgeben
      $p->text($x1+2,$y1,$erg2[5].'-'.$erg2[6]); # Zeit von bis
      # pr�fen, ob Minuten genau abgerechnet werden muss
      if ($fuerzeit_flag ne 'E') { # nein

	my $dauer = $d->dauer_m($erg2[6],$erg2[5]);
	$vk = sprintf "%3.1u",$h->runden($dauer / $fuerzeit);
	$vk++ if ($vk*$fuerzeit < $dauer);
	$vk = sprintf "%1.1u",$vk;
	$epreis =~ s/\./,/g;
	$p->text($x1+5.5,$y1,$vk." x ".$fuerzeit." min � ".$epreis." EUR");
      }
      if ($fuerzeit_flag eq 'E') { # ja
	my $dauer = $d->dauer_m($erg2[6],$erg2[5]);
	$vk = sprintf "%3.2f",$h->runden($dauer / $fuerzeit);
	$epreis =~ s/\./,/g;
	$vk =~ s/\./,/g;
	$p->text($x1+5.5,$y1,$dauer." min = ".$vk." h � ".$epreis." EUR");
      }
    } else {
      if ($zeit_von || $zeit_bis) {
	$p->text($x1+2,$y1,$d->wotag($erg[4]));
	$p->text($x1+5,$y1,$zeit_von.'-'.$zeit_bis);
	$hks=0;
      }
    }
    # datum 4
    my $datum = $d->convert_tmj($erg[4]);
    my $gpreis = 0;
    $vk =~ s/,/\./g;	$epreis =~ s/,/\./g;
    $gpreis = sprintf "%.2f",$h->runden($vk * $epreis);


    $summe+=$gpreis;$gpreis =~ s/\./,/g;
    $p->text({align => 'right'},15,$y1,$datum); # Datum andrucken
    $p->text({align => 'right'},17.3,$y1,$gpreis." EUR"); # Preis andrucken
    $y1-=$y_font;
    neue_seite(4,$teil);
  }
  $y1+=$y_font-0.05;
  $p->line(17.4,$y1,15.1,$y1);$y1-=$y_font-0.1;
  my $psumme = sprintf "%.2f",$summe;$psumme =~ s/\./,/g;
  $p->text({align => 'right'},17.3,$y1,$psumme." EUR"); # Gesamt Summe andrucken
  $p->text({align => 'right'},19.5,$y1,$psumme." EUR"); # Gesamt erneut Summe andrucken
  $y1-=$y_font;$y1-=$y_font;
  neue_seite(6);
  return $summe;
}


sub anschrift {
  # gibt Anschrift, Rechnungsnummer, etc. aus
  my $x1=12.6; # x werte f�r kisten
  my $x2=19.4;

  $p->setfont($font, 10);
  $p->box($x1,27.2,$x2,28.2);# Kiste f�r Rechnung y1=28.2 y2=27.2
  $p->setfont($font_b, 12);
  $p->text(12.7,27.8,"Rechnung");
  $p->setfont($font,10);
  $p->text(15.1,27.8,"Nr.");
  $p->text(15.1+2.4,27.8,$rechnungsnr);
  $p->text(15.1,27.8-$y_font,"Datum");
  $p->text(15.1+2.4,27.8-$y_font,$datum);
  
  my $y1=27.7;
  # Kiste f�r Krankenkassen nur ausgeben, wenn keine privat Rechnung
  if ($versichertenstatus ne 'privat') {
    $p->box($x1,25.1,$x2,26.4); # Kiste f�r Krankenkasse y=25.1 y2=26.4
    $p->setfont($font,8);
    if ($versichertenstatus ne 'SOZ') {
      $p->text(12.7,$y1-3*$y_font,"Zahlungspflichtige Kasse (Rechnungsempf�nger):");
    } else {
      $p->text(12.7,$y1-3*$y_font,"Rechnungsempf�nger:");
    }
    $p->setfont($font,10);
    $p->text(12.7,$y1-4*$y_font,"IK:");
    $p->setfont($font_b,10);
    $p->text(15.1,$y1-4*$y_font,$ik_krankenkasse);
    $p->text(12.7,$y1-5*$y_font,$kname_krankenkasse);
    $p->setfont($font,10);
    $p->text(12.7,$y1-6*$y_font,$plz_krankenkasse." ".$ort_krankenkasse) if ($plz_krankenkasse ne '' && $plz_krankenkasse > 0);
    $p->text(12.7,$y1-6*$y_font,$plz_post_krankenkasse." ".$ort_krankenkasse) if ($plz_krankenkasse ne '' && $plz_krankenkasse == 0);
    
    $y1=24.6;
    $p->box($x1,23.8,$x2,$y1);# Kiste f�r Mitglied y1=23.8 y2=24.6
    $p->setfont($font,8);
    $y1+=0.1;
    $p->text(12.7,$y1,"Mitglied");
    $p->setfont($font_b,10);
    $p->text(12.7,$y1-$y_font,$nachname.", ".$vorname);
    $p->setfont($font,10);
    $p->text(12.7,$y1-2*$y_font,"geboren am");
    $p->text(15.1,$y1-2*$y_font,$geb_frau);
    
    $y1=23.8;
    my $groesse_kiste = 2.1;
    $groesse_kiste-=(2.9*$y_font) if($versichertenstatus eq 'SOZ');
    $p->box($x1,$y1-$groesse_kiste,$x2,$y1);# Anschrift und Versichertenstatus y1=21.7 y2=23.8
    $y1=23.4;
    $p->text(12.7,$y1,$plz." ".$ort);
    $p->text(12.7,$y1-$y_font,$strasse);
    if($versichertenstatus ne 'SOZ') {
      $p->text(12.7,$y1-2*$y_font,"Mitgl-Nr.");
      $p->setfont($font_b,10);
      $p->text(15.1,$y1-2*$y_font,$kv_nummer);
      $p->setfont($font,10);
      $p->text(12.7,$y1-3*$y_font,"V-Status:");
      $p->setfont($font_b,10);
      $p->text(15.1,$y1-3*$y_font,$versichertenstatus);
      $p->setfont($font,10);
      $p->text(12.7,$y1-4*$y_font,"g�lt.bis:");
      $p->setfont($font_b,10);
      my ($m,$j) = unpack("A2A2",$kv_gueltig);
      $p->text(15.1,$y1-4*$y_font,"$m/$j");
    }
    
    $y1=21.3;
    $y1+=(3*$y_font) if($versichertenstatus eq 'SOZ');
    $p->box($x1,$y1-0.5,$x2,$y1);# Kiste f�r Kind y1=20.8 y2=21.3
    $p->setfont($font,8);
#    $y1=21.35;
    $y1+=0.05;
    if ($anz_kinder < 2) {
      $p->text(12.7,$y1,"Kind:");
    } else {
      my $text = "Kinder (".$kinder[$anz_kinder-1]."):";
      $p->text(12.7,$y1,$text);
    }

    $p->setfont($font,10);
    # pr�fen ob ET oder Geburtsdatum
    my $geb_kind_et=$d->convert($geb_kind);$geb_kind_et =~ s/-//g;
    my $datum_jmt=$d->convert($datum);$datum_jmt =~ s/-//g;
    # zeilen nur ausgeben, wenn geb Kind g�ltig ist
    if ($geb_kind_et ne 'error') {
      if ($datum_jmt >= $geb_kind_et && !$kzetgt ||
	  $kzetgt == 1) {
	$p->text(12.7,$y1-$y_font,"geboren am");
      } else {
	$p->text(12.7,$y1-$y_font,"ET");
      }
      if ($uhr_kind && $kzetgt && $kzetgt == 1) {
	$p->text(15.1,$y1-$y_font,"$geb_kind $uhr_kind");
      } else {
	$p->text(15.1,$y1-$y_font,"$geb_kind");
      }
    } else {
      $p->text(12.7,$y1-$y_font,"unbekannt");
    }
  }
  
  # Anschrift der Hebamme
  $p->setfont($font,10);
  $x1=2; $y1=27.8;
  $p->text($x1,$y1,$h->parm_unique('HEB_VORNAME').' '.$h->parm_unique('HEB_NACHNAME'));
  $y1 -= $y_font;
  $p->text($x1,$y1,$h->parm_unique('HEB_STRASSE'));
  $y1 -= $y_font;
  $p->text($x1,$y1,$h->parm_unique('HEB_PLZ').' '.$h->parm_unique('HEB_ORT'));
  $y1 -= $y_font;
  $p->text($x1,$y1,$h->parm_unique('HEB_TEL'));
  $y1 -= $y_font;
  $p->text($x1,$y1,'IK: '.$h->parm_unique('HEB_IK'));
  
  # Absender 
  $p->line($x1,24.6,$x1+9,24.6);
  $p->setfont($font,8);
  my $absender=$h->parm_unique('HEB_VORNAME').' '.$h->parm_unique('HEB_NACHNAME').', '.$h->parm_unique('HEB_STRASSE').', '.$h->parm_unique('HEB_PLZ').' '.$h->parm_unique('HEB_ORT');
  $p->text($x1,24.7,$absender);

  # Logo einbauen
  if (-e "logo.eps") {
    $p->importepsfile("logo.eps",$x1+7.3,26.2,$x1+9.3,28.2);
  }
  
  # Empf�nger
  # zun�chst richtige Annahmestelle f�r Belege holen
  # und zu dieser Anschrift holen,
  
  my ($beleg_ik,$beleg_typ)=$k->krankenkasse_beleg_ik($ik_krankenkasse);
  my $beleg_parm = $h->parm_unique('BELEGE');
  $beleg_ik=$ik_krankenkasse if(!(defined($beleg_parm)) || $beleg_parm != 1);
  my  ($name_krankenkasse_beleg,
       $kname_krankenkasse_beleg,
       $plz_krankenkasse_beleg,
       $plz_post_krankenkasse_beleg,
       $ort_krankenkasse_beleg,
       $strasse_krankenkasse_beleg,
       $postfach_krankenkasse_beleg) = $k->krankenkasse_sel('NAME,KNAME,PLZ_HAUS,PLZ_POST,ORT,STRASSE,POSTFACH',$beleg_ik);
  
  $name_krankenkasse_beleg = '' unless ($name_krankenkasse_beleg);
  $kname_krankenkasse_beleg = '' unless ($kname_krankenkasse_beleg);
  $plz_krankenkasse_beleg = 0 unless ($plz_krankenkasse_beleg);
  $plz_post_krankenkasse_beleg = 0 unless ($plz_post_krankenkasse_beleg);
  $strasse_krankenkasse_beleg = '' unless ($strasse_krankenkasse_beleg);
  $postfach_krankenkasse_beleg = '' unless ($postfach_krankenkasse_beleg);
  $ort_krankenkasse_beleg = '' unless ($ort_krankenkasse_beleg);
  
  $plz_krankenkasse_beleg = sprintf "%5.5u",$plz_krankenkasse_beleg;
  $plz_post_krankenkasse_beleg = sprintf "%5.5u",$plz_post_krankenkasse_beleg;
  
  
  # nur dann, wenn keine privat Rechnung
  if ($versichertenstatus ne 'privat') {
    $p->setfont($font,10);
    $y1=23.8;
    $p->text($x1,$y1,$kname_krankenkasse_beleg);
    $p->text($x1,$y1-$y_font,$strasse_krankenkasse_beleg) if ($plz_post_krankenkasse_beleg ne '' && $plz_post_krankenkasse_beleg == 0);
    $p->text($x1,$y1-$y_font,"Postfach $postfach_krankenkasse_beleg") if ($plz_post_krankenkasse_beleg ne '' && $plz_post_krankenkasse_beleg > 0);
    $p->text($x1,$y1-3*$y_font,$plz_krankenkasse_beleg." ".$ort_krankenkasse_beleg) if ($plz_post_krankenkasse_beleg ne '' && $plz_post_krankenkasse_beleg == 0);
    $p->text($x1,$y1-3*$y_font,$plz_post_krankenkasse_beleg." ".$ort_krankenkasse_beleg) if ($plz_post_krankenkasse_beleg ne '' && $plz_post_krankenkasse_beleg > 0);
  }
  
  if ($versichertenstatus eq 'privat') {
    $p->setfont($font,10);
    $y1=23.8;
    $p->text($x1,$y1,$vorname.' '.$nachname);
    $p->text($x1,$y1-$y_font,$strasse);
    $p->text($x1,$y1-3*$y_font,$plz.' '.$ort);
  }
}


sub urbeleg {
  $p->newpage;
  wasserzeichen();
  anschrift();

  # Falz  ausgeben
  $p->setlinewidth(0.02);
  $p->line(0,19.2,0.5,19.2);
  $p->line(20.4,19.2,21,19.2);
  $p->setlinewidth(0.04);

  # Betreff Zeile
  $p->setfont($font_b,10);
  if ($versichertenstatus ne 'privat') {
    $p->text(2,19.7,"Begleitzettel f�r Urbelege, Rechnung $rechnungsnr");
  }
  $y1=18.5;

  $p->setfont($font,10);  
  $p->text($x1,$y1,"Anzahl der �bermittelten Belege: ");
  $y1-=$y_font;$y1-=$y_font;$y1-=$y_font;
  $p->text($x1,$y1,"Mit freundlichen Gr��en");
  fussnote(); # auf der ersten Seite explizit angeben
}
