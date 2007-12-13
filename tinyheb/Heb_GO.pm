# Package f�r die Hebammen Verarbeitung
# Plausipr�fungen der GO

# $Id: Heb_GO.pm,v 1.11 2007-12-13 11:17:37 thomas_baum Exp $
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

package Heb_GO;

use strict;
use Date::Calc qw(Today Day_of_Week Delta_Days Add_Delta_Days Day_of_Week Add_Delta_YM);

use lib "../";
use Heb_leistung;
use Heb_datum;
use Heb_stammdaten;

my $s = new Heb_stammdaten;
my $d = new Heb_datum;
my $l = new Heb_leistung;

our $HINT = '';

sub new {
  my $class = shift;
  my $self = {@_,};
  
  return undef unless(defined($self->{posnr}));
  return undef unless(defined($self->{frau_id}));
  return undef unless(defined($self->{datum_l}));
  my $dbh = Heb->connect;

  my @dat_frau = $s->stammdaten_frau_id($self->{frau_id});
  my $geb_kind=$d->convert($dat_frau[3]);
  $geb_kind = '' if ($geb_kind eq 'error');
  $geb_kind =~ s/-//g;
  $self->{geb_kind}=$geb_kind;
  $self->{dow}=Day_of_Week($d->jmt($self->{datum_l}));  # 1 == Montag 2 == Dienstag, ..., 7 == Sonntag
  $self->{datum_l} =~ s/-//g;

  ($self->{ltyp},$self->{begruendungspflicht},$self->{dauer},
   $self->{samstag},$self->{sonntag},$self->{nacht},$self->{zweitesmal},
   $self->{fuerzeit},$self->{nicht})
   =$l->leistungsart_such_posnr
     ('LEISTUNGSTYP,BEGRUENDUNGSPFLICHT,DAUER,SAMSTAG,SONNTAG,NACHT,ZWEITESMAL,FUERZEIT,NICHT',
      $self->{posnr},$self->{datum_l});
  $self->{zweitesmal}='' unless (defined($self->{zweitesmal}));
  $self->{samstag}='' unless(defined($self->{samstag}));
  $self->{sonntag}='' unless(defined($self->{sonntag}));
  $self->{nacht}='' unless(defined($self->{nacht}));
  $self->{dauer}=0 unless(defined($self->{dauer}));
  $self->{ltyp}='' unless(defined($self->{ltyp}));
  $self->{begruendungspflicht}='n' unless(defined($self->{begruendungspflicht}));

  bless $self,ref $class || $class;
  return $self;
}

sub ersetze_samstag {
  # Wenn Samstag angegeben ist, pr�fen ob posnr ersetzt werden muss
  my $self=shift;

  if ($self->{dow} == 6 && $self->{samstag} =~ /(\+{0,1})(\d{1,3})/ && $2 > 0 && $d->zeit_h($self->zeit) >= 12) { # 
    # Samstag nach 12 Uhr und ob es sich um andere Positionsnummer handelt
    return $2 if ($1 ne '+');
  }
  return undef;
}

sub zuschlag_samstag {
  # pr�ft ob Zuschlag f�r diese Positionsnummer an einem Samstag  existiert
  my $self=shift;

  if ($self->{dow} == 6 && $self->{samstag} =~ /(\+{0,1})(\d{1,3})/ && $2 > 0 && $d->zeit_h($self->zeit) >= 12) { # 
    # Samstag nach 12 Uhr und ob es sich um Zuschlags Positionsnummer handelt
    return $2 if ($1 eq '+');
  }
  return undef;
}


sub ersetze_sonntag {
  # Wenn Sonntag oder Feiertag angegeben ist, pr�fen ob posnr ersetzt werden
  # muss
  my $self=shift;
  if (($self->{dow} == 7 || ($d->feiertag_datum($self->{datum_l})>0)) && $self->{sonntag} =~ /(\+{0,1})(\d{1,3})/ && $2 > 0) {
    return $2 if ($1 ne '+');
  }
  return undef;
}

sub zuschlag_sonntag {
  # pr�ft ob Zuschlag f�r diese Posnr an einem Sonntag oder Feiertag existiert
  my $self=shift;

  if (($self->{dow} == 7 || ($d->feiertag_datum($self->{datum_l})>0)) && $self->{sonntag} =~ /(\+{0,1})(\d{1,3})/ && $2 > 0) {
    return $2 if ($1 eq '+');
  }
  return undef;
}


sub ersetze_nacht {
  # wenn Nacht angegeben ist, pr�fen ob posnr ersetzt werden muss
  my $self=shift;
  if ($self->{zeit_von} ne '' && ($d->zeit_h($self->zeit) < 8 || $d->zeit_h($self->zeit)>=20) && $self->{nacht} =~ /(\+{0,1})(\d{1,3})/ && $2 > 0) {
    return $2 if($1 ne '+');
  }
  return undef;
}

sub zuschlag_nacht {
  # pr�fen, ob Zuschlag f�r diese Posnr Nachts existiert
  my $self=shift;
  if ($self->{zeit_von} ne '' && ($d->zeit_h($self->zeit) < 8 || $d->zeit_h($self->zeit)>=20) && $self->{nacht} =~ /(\+{0,1})(\d{1,3})/ && $2 > 0) {
    return $2 if($1 eq '+');
  }
  return undef;
}


sub zweitesmal {
  # pr�fen ob andere Positionsnummer w/ Zweitesmal genutzt werden muss
  # wird genau dann gemacht, wenn die Positionsnummer am gleichen Tag
  # schon erfasst ist
  my $self=shift;

  if ($self->{zweitesmal} =~ /(\+{0,1})(\d{1,3})/ && $2 > 0) {
    return $2 if ($l->leistungsdaten_werte($self->{frau_id},"POSNR","POSNR=$self->{posnr} AND DATUM='$self->{datum_l}'")>0);
  }
  return undef;
}

sub zuschlag_plausi {
  # pr�ft ob eine Zuschlagspositionsnummer f�r einen Tag ausgew�hlt
  # wurde, an dem kein Zuschlag gew�hlt werden darf
  my $self=shift;
  if ($l->leistungsart_pruef_zus($self->{posnr},'SONNTAG') && ($self->{dow}==7 || ($d->feiertag_datum($self->{datum_l})))) {
    # alles ok
  } elsif ($l->leistungsart_pruef_zus($self->{posnr},'SAMSTAG') && $self->{dow}==6 && $d->zeit_h($self->{zeit_von}) >= 12) {
    # alles ok
  } elsif ($l->leistungsart_pruef_zus($self->{posnr},'NACHT') && ($d->zeit_h($self->zeit) < 8 && $self->zeit ne '' || $d->zeit_h($self->zeit) >= 20)) {
    # alles ok
  } elsif (($l->leistungsart_pruef_zus($self->{posnr},'SONNTAG') || 
	    $l->leistungsart_pruef_zus($self->{posnr},'SAMSTAG') || 
	    $l->leistungsart_pruef_zus($self->{posnr},'NACHT')) && 
	   ($self->{dow} < 6 || $self->{dow}==6 && $self->zeit ne '' && $d->zeit_h($self->zeit) < 12) || 
	   $d->zeit_h($self->zeit)<8 && $d->zeit_h($self->zeit) > 20) {
    return 1;
  }
  return undef;
}


sub pos1_plausi {
  # pr�ft ob Positionsnummer 1 erfasst wurde
  # liefert als Ergebnis '' wenn kein Fehler aufgetreten ist oder
  # Fehlermeldung wenn Fehler aufgetreten ist
  my $self = shift;
  my ($posnr,$frau_id,$datum_l) = 
    ($self->{posnr},$self->{frau_id},$self->{datum_l});

  return '' if $posnr ne '1';
  if ($l->leistungsdaten_werte($frau_id,"POSNR","POSNR=$posnr") >= 12) {
    return 'FEHLER: Position ist h�chstens zw�lfmal berechnungsf�hig\nes wurde nichts gespeichert';
  }
  return '';
}

sub pos010_plausi {
  # pr�ft ob Positionsnummer 010 erfasst wurde

  # liefert als Ergebnis '' wenn kein Fehler aufgetreten ist oder
  # Fehlermeldung wenn Fehler aufgetreten ist
  my $self = shift;
  my ($posnr,$frau_id,$datum_l) = 
    ($self->{posnr},$self->{frau_id},$self->{datum_l});

  return '' if $posnr ne '010';
  if ($l->leistungsdaten_werte($frau_id,"POSNR","POSNR=$posnr") >= 12) {
    return 'FEHLER: Position ist h�chstens zw�lfmal berechnungsf�hig\nes wurde nichts gespeichert';
  }

  return '';
}



sub pos6_plausi {
  # Positionsnummer 6 mehr als 2 mal am selben Tag nur auf
  # �rztliche Anordnung
  my $self=shift;
  
  return undef if ($self->{posnr} ne '6');
  
  if ($l->leistungsdaten_werte($self->{frau_id},"POSNR","POSNR=$self->{posnr} AND DATUM='$self->{datum_l}'")>=2 && $self->{begruendung} !~ /Anordnung/ ) {
    return '\nFEHLER: Position '.$self->{posnr}.' mehr als 2 mal am selben Tag nur auf �rztliche Anordnung\nEs wurde nichts gespeichert';
  }
  return undef;
}


sub pos060_plausi {
  # Positionsnummer 060 mehr als 2 mal am selben Tag nur auf
  # �rztliche Anordnung
  my $self=shift;
  
  return undef if ($self->{posnr} ne '060');
  
  if ($l->leistungsdaten_werte($self->{frau_id},"POSNR","POSNR=$self->{posnr} AND DATUM='$self->{datum_l}'")>=2 && $self->{begruendung} !~ /Anordnung/ ) {
    return '\nFEHLER: Position '.$self->{posnr}.' mehr als 2 mal am selben Tag nur auf �rztliche Anordnung\nEs wurde nichts gespeichert';
  }
  return undef;
}



sub pos7_plausi {
  # Positionsnummer 7 darf die maximale Dauer 14 Stunden nicht �berschreiten
  my $self=shift;
  my ($zeit_von,$zeit_bis) = ($self->{zeit_von},$self->{zeit_bis});
  my ($posnr,$frau_id)=($self->{posnr},$self->{frau_id});

  return '' if $posnr ne '7';
  # zun�chst die bisherige Dauer berechnen
  my $dauer=0;
  $l->leistungsdaten_werte($frau_id,"ZEIT_VON,ZEIT_BIS","POSNR=$posnr");
  while (my($alt_zeit_von,$alt_zeit_bis)=$l->leistungsdaten_werte_next()) {
    $dauer+=$d->dauer_m($alt_zeit_bis,$alt_zeit_von);
  }
  my $erfasst=sprintf "%3.2f",$dauer/60;
  $erfasst =~ s/\./,/g;
  $dauer += $d->dauer_m($zeit_bis,$zeit_von);
  if ($dauer > (14*60)) {
    return 'FEHLER: Geburtsvorbereitung in der Gruppe h�chsten 14 Stunden\nschon erfasst '.$erfasst.' Stunden\nes wurde nichts gespeichert\n';
  }
  return '';
}


sub pos070_plausi {
  # Positionsnummer 070 darf die maximale Dauer 14 Stunden nicht �berschreiten
  my $self=shift;
  my ($zeit_von,$zeit_bis) = ($self->{zeit_von},$self->{zeit_bis});
  my ($posnr,$frau_id)=($self->{posnr},$self->{frau_id});

  return '' if $posnr ne '070';
  # zun�chst die bisherige Dauer berechnen
  my $dauer=0;
  $l->leistungsdaten_werte($frau_id,"ZEIT_VON,ZEIT_BIS","POSNR=$posnr");
  while (my($alt_zeit_von,$alt_zeit_bis)=$l->leistungsdaten_werte_next()) {
    $dauer+=$d->dauer_m($alt_zeit_bis,$alt_zeit_von);
  }
  my $erfasst=sprintf "%3.2f",$dauer/60;
  $erfasst =~ s/\./,/g;
  $dauer += $d->dauer_m($zeit_bis,$zeit_von);
  if ($dauer > (14*60)) {
    return 'FEHLER: Geburtsvorbereitung in der Gruppe h�chsten 14 Stunden\nschon erfasst '.$erfasst.' Stunden\nes wurde nichts gespeichert\n';
  }
  return '';
}



sub pos8_plausi {
  # Positionsnummer 8 darf die maximale Dauer 14 Stunden nicht �berschreiten
  my $self=shift;
  my ($zeit_von,$zeit_bis) = ($self->{zeit_von},$self->{zeit_bis});
  my ($posnr,$frau_id)=($self->{posnr},$self->{frau_id});

  return '' if $posnr ne '8';
  # zun�chst die bisherige Dauer berechnen
  my $dauer=0;
  $l->leistungsdaten_werte($frau_id,"ZEIT_VON,ZEIT_BIS","POSNR=$posnr");
  while (my($alt_zeit_von,$alt_zeit_bis)=$l->leistungsdaten_werte_next()) {
    $dauer+=$d->dauer_m($alt_zeit_bis,$alt_zeit_von);
  }
  my $erfasst=sprintf "%3.2f",$dauer/60;
  $erfasst =~ s/\./,/g;
  $dauer += $d->dauer_m($zeit_bis,$zeit_von);
  if ($dauer > (14*60)) {
    return 'FEHLER: Geburtsvorbereitung bei Einzelunterweisung h�chsten 14 Stunden\nschon erfasst '.$erfasst.' Stunden\nes wurde nichts gespeichert\n';
  }
  return '';
}



sub pos080_plausi {
  # Positionsnummer 8 darf die maximale Dauer 
  # h�chstens 14 Unterichtseinheiten a 30 Minuten nicht �berschreiten
  my $self=shift;
  my ($zeit_von,$zeit_bis) = ($self->{zeit_von},$self->{zeit_bis});
  my ($posnr,$frau_id)=($self->{posnr},$self->{frau_id});

  return '' if $posnr ne '080';
  # zun�chst die bisherige Dauer berechnen
  my $vk=0;
  my $dauer_alt=0;
  $l->leistungsdaten_werte($frau_id,"ZEIT_VON,ZEIT_BIS","POSNR=$posnr");
  while (my($alt_zeit_von,$alt_zeit_bis)=$l->leistungsdaten_werte_next()) {
    my $dauer_akt=$d->dauer_m($alt_zeit_bis,$alt_zeit_von);
    $vk = sprintf "%3.1u",($dauer_akt / $self->{fuerzeit});
    $vk++ if ($vk*$self->{fuerzeit} < $dauer_akt);
    $vk = sprintf "%1.1u",$vk;
    $dauer_alt += $vk;
  }

  # aktuelle Zeit berechnen
  my $dauer_akt=$d->dauer_m($self->{zeit_bis},$self->{zeit_von});
  $vk = sprintf "%3.1u",($dauer_akt / $self->{fuerzeit});
  $vk++ if ($vk*$self->{fuerzeit} < $dauer_akt);
  $vk = sprintf "%1.1u",$vk;

  if ($dauer_alt+$vk > 14) {
    return 'FEHLER: Geburtsvorbereitung bei Einzelunterweisung h�chsten 14 Unterichtseinheiten a 30 Minuten bis jetzt wurden '.$dauer_alt.' Einheiten erfasst\nes wurde nichts gespeichert\n';
  }
  return '';
}


sub pos40_plausi {
  # Positionsnummer 40 darf die maximale Dauer von 10 Stunden nicht �berschreiten
  my $self=shift;
  my ($zeit_von,$zeit_bis) = ($self->{zeit_von},$self->{zeit_bis});
  my ($posnr,$frau_id)=($self->{posnr},$self->{frau_id});

  return '' if $posnr ne '40';
  # zun�chst die bisherige Dauer berechnen
  my $dauer=0;
  $l->leistungsdaten_werte($frau_id,"ZEIT_VON,ZEIT_BIS","POSNR=$posnr");
  while (my($alt_zeit_von,$alt_zeit_bis)=$l->leistungsdaten_werte_next()) {
    $dauer+=$d->dauer_m($alt_zeit_bis,$alt_zeit_von);
  }
  my $erfasst=sprintf "%3.2f",$dauer/60;
  $erfasst =~ s/\./,/g;
  $dauer += $d->dauer_m($zeit_bis,$zeit_von);
  if ($dauer > (10*60)) {
    return 'FEHLER: R�ckbildungsgymnastik in der Gruppe h�chsten 10 Stunden\nschon erfasst '.$erfasst.' Stunden\nes wurde nichts gespeichert\n';
  }
  return '';
}



sub pos270_plausi {
  # Positionsnummer 270 darf die maximale Dauer von 10 Stunden nicht �berschreiten
  my $self=shift;
  my ($zeit_von,$zeit_bis) = ($self->{zeit_von},$self->{zeit_bis});
  my ($posnr,$frau_id)=($self->{posnr},$self->{frau_id});

  return '' if $posnr ne '270';
  # zun�chst die bisherige Dauer berechnen
  my $dauer=0;
  $l->leistungsdaten_werte($frau_id,"ZEIT_VON,ZEIT_BIS","POSNR=$posnr");
  while (my($alt_zeit_von,$alt_zeit_bis)=$l->leistungsdaten_werte_next()) {
    $dauer+=$d->dauer_m($alt_zeit_bis,$alt_zeit_von);
  }
  my $erfasst=sprintf "%3.2f",$dauer/60;
  $erfasst =~ s/\./,/g;
  $dauer += $d->dauer_m($zeit_bis,$zeit_von);
  if ($dauer > (10*60)) {
    return 'FEHLER: R�ckbildungsgymnastik in der Gruppe h�chsten 10 Stunden\nschon erfasst '.$erfasst.' Stunden\nes wurde nichts gespeichert\n';
  }
  return '';
}


sub pos280_290_plausi {
  # pr�ft, ob Posnr 280,290 fr�hestens nach 8 Wochen
  # maximal 4 mal
  # abgerechnet werden --> OK

  my $self=shift;

  return '' if ($self->{posnr} ne '280' && 
		$self->{posnr} ne '281' && 
		$self->{posnr} ne '290');
  return '' if($self->{geb_kind} eq '');

  # fr�hestens
  my $days = Delta_Days(unpack('A4A2A2',$self->{geb_kind}),unpack('A4A2A2',$self->{datum_l}));
  if ($days < 57) {
    return '\nFEHLER: Position '.$self->{posnr}.' fr�hestens 8 Wochen nach der Geburt\nes wurde nicht gespeichert';
  }

  # sp�testens
  my $neun_spaeter=sprintf "%4.4u%2.2u%2.2u",Add_Delta_YM(unpack('A4A2A2',$self->{geb_kind}),0,9);
  if ($self->{datum_l} > $neun_spaeter) {
    return '\nFEHLER: Position '.$self->{posnr}.' nur bis zum Ende 9. Monat nach Geburt,\nEs wurde nichts gespeichert';
  }

  # maximal 4 Mal
  my $pruef_pos=$self->{posnr};
  $pruef_pos .= ',281' if ($pruef_pos eq '280');
  $pruef_pos .= ',280' if ($pruef_pos eq '281');

   if ($l->leistungsdaten_werte($self->{frau_id},"POSNR","POSNR in ($pruef_pos)")>=4) {
    return '\nFEHLER: Position '.$pruef_pos.' maximal 4 mal berechnungsf�hig\nEs wurde nichts gespeichert';
  }
  
  return '';
}


sub nicht_plausi {
  # pr�ft ob Positionsnummer nicht mit anderen Positionsnummern 
  # erfasst werden darf
  # liefert Ergebnis '' wenn kein Fehler aufgetreten ist oder
  # Fehlermeldung wenn Fehler aufgetreten ist
  my $self=shift;
  my ($posnr,$frau_id,$datum_l)=
    ($self->{posnr},$self->{frau_id},$self->{datum_l});

  return '' unless ($self->{nicht});

  if ($l->leistungsdaten_werte($frau_id,"POSNR",
                               "POSNR in ($self->{nicht}) and DATUM='$self->{datum_l}'")) {
    return 'FEHLER: Positionsnummer '.$self->{posnr}.' ist neben Leistungen nach '.$self->{nicht}.'\nan demselben Tag nicht berechnungsf�hig\nes wurde nichts gespeichert';
  }
  return '';
}



sub dauer_plausi {
  # pr�ft, ob begr�ndung f�r Positionsnummer erfasst werden muss,
  # dass ist genau dann der Fall, wenn dauer > DAUER.
  my $self=shift;
  my ($posnr,$dauer,$datum_l,$begruendung)=
    ($self->{posnr},$self->{dauer},$self->{datum_l},$self->{begruendung});


  if ($self->{dauer} > 0 && 
      $self->{dauer} < $d->dauer_m($self->{zeit_bis},$self->{zeit_von}) && 
      $begruendung eq '') {
    return 'FEHLER: Bei Leistung nach Positionsnummer '.$posnr.' l�nger als\n'.$self->{dauer}.' Minuten ist dies zu begr�nden\nes wurde nichts gespeichert';
  }
  return '';
}


sub ltyp_plausi {
  # pr�ft, das Leistungstyp A (Mutterschaftsvorsorge und Schwangeren-
  # betreuung vor Geburt des Kindes erfolgen,
  # C (Wochenbett) nur nach Geburt des Kindes
  # Pr�fung wird nur durchgef�hrt, wenn Geburtsdatum des Kindes bekannt ist
  my $self = shift;
  my ($posnr,$frau_id,$datum_l)=
    ($self->{posnr},$self->{frau_id},$self->{datum_l});

  my $geb_kind=$self->{geb_kind};
  return '' if($geb_kind eq '');
  my $ltyp=$self->{ltyp};

  if ($ltyp eq 'A' && $geb_kind < $datum_l) {
    return 'FEHLER: Leistungen der Schwangerenbetreuung k�nnen nur vor Geburt des\nKindes erbracht werden.\nEs wurde nichts gespeichert';
  }
  if ($ltyp eq 'C' && $geb_kind > $datum_l) {
    return 'FEHLER: Leistungen im Wochenbett k�nnen erst nach Geburt des Kindes\nerbracht werden. Es wurde nichts gespeichert.';
  }
  return '';
}


sub Cd_plausi {
  # pr�ft, ob Posnr 25,26 innerhalb der ersten zehn Tage nach der Geburt
  # abgerechnet werden --> OK
  # oder ob Posnr 25,26,29,32,33 nach zehn Tagen 
  # innerhalb von 8 Wochen = 56 Tage mit Begr�ndung --> OK
  # oder nach 8 Wochen mit Begr�ndung 'auf �rztliche Anordnung' --> OK
  my $self=shift;
  my ($posnr,$datum_l,$begruendung)=    
    ($self->{posnr},$self->{datum_l},$self->{begruendung});

  return '' if ($posnr ne '25' && $posnr ne '26' && $posnr ne '29' &&
                $posnr ne '32' && $posnr ne '33');

  my $geb_kind=$self->{geb_kind};
  return '' if($geb_kind eq '');

  my $days = Delta_Days(unpack('A4A2A2',$geb_kind),unpack('A4A2A2',$datum_l));
  if ($days < 11 && ($posnr eq '25' || $posnr eq '26')) {
    return '';
  } elsif ($days < 11 && $posnr ne '25' && $posnr ne '26' && 
           $begruendung eq '') {
    return '\nFEHLER: innerhalb der ersten 10 Tage d�rfen nur Posnr 25 und 26\nohne Begr�ndung zweimal abgerechnet werden.\nEs wurde nichts gespeichert';
  } elsif ($days < 57 && $begruendung eq '') {
    return '\nFEHLER: Position '.$posnr.' nach 10 Tagen innerhalb 8 Wochen nur mit Begr�ndung.\nEs wurde nichts gespeichert';
  } elsif ($days > 56 && ($begruendung !~ /Anordnung/)) {
    return '\nFEHLER: Position '.$posnr.' nach 8 Wochen nur auf �rztliche Anordnung\nEs wurde nichts gespeichert';
  }
  return '';
}

sub Cd_plausi_neu {
  # pr�ft, ob Posnr 180 bis 211 innerhalb der ersten zehn Tage nach der Geburt
  # abgerechnet werden --> OK
  # mehr als 2 mal mit �rztlicher Anordnung --> OK
  # oder ob Posnr 180 bis 211 nach zehn Tagen 
  # innerhalb von 8 Wochen = 56 Tage mit Begr�ndung --> OK
  # oder nach 8 Wochen mit Begr�ndung 'auf �rztliche Anordnung' --> OK
  my $self=shift;
  my ($posnr,$datum_l,$begruendung)=    
    ($self->{posnr},$self->{datum_l},$self->{begruendung});

  return '' if ($posnr ne '180' && $posnr ne '181' && 
		$posnr ne '200' && $posnr ne '201' &&
		$posnr ne '210' && $posnr ne '211');

  my $geb_kind=$self->{geb_kind};
  return '' if($geb_kind eq '');

  my $anzahl=$l->leistungsdaten_werte($self->{frau_id},"POSNR",
				      "POSNR in (180,181,200,201,210,211) and DATUM='$datum_l'");

  my $days = Delta_Days(unpack('A4A2A2',$geb_kind),unpack('A4A2A2',$datum_l));
  if ($days < 11 && $anzahl < 2) {
    return '';
  } elsif ($days < 11 && $anzahl > 1 && $begruendung !~ /Anordnung/) {
    return '\nFEHLER: Position '.$posnr.' mehr als 2 mal pro Tag nur auf �rztliche Anordnung.\nEs wurde nichts gespeichert';
  } elsif ($days < 57 && $begruendung eq '' && $anzahl > 0) {
    return '\nFEHLER: Position '.$posnr.' nach 10 Tagen innerhalb 8 Wochen nur mit Begr�ndung.\nEs wurde nichts gespeichert';
  } elsif ($days > 56 && ($begruendung !~ /Anordnung/) && $anzahl > 0) {
    return '\nFEHLER: Position '.$posnr.' nach 8 Wochen nur auf �rztliche Anordnung\nEs wurde nichts gespeichert';
  }
  return '';
}


sub Cc_plausi {
  # Leistungen nach 22,23,25 bis 33 und 35 sind nur mehr als 16 mal
  # abrechenbar, wenn �rztlich angeordnet
  # Nach neuer GO Posnr 180 bis 230
  my $self=shift;
  my ($posnr,$datum_l,$begruendung)=   
    ($self->{posnr},$self->{datum_l},$self->{begruendung});

  return '' if ($posnr ne '22' && $posnr ne '23' && $posnr ne '25' &&
                $posnr ne '26' && $posnr ne '27' && $posnr ne '28' &&
                $posnr ne '29' && $posnr ne '30' && $posnr ne '31' &&
                $posnr ne '32' && $posnr ne '33' && $posnr ne '35' &&
		$posnr ne '180' && $posnr ne '181' && 
		$posnr ne '200' && $posnr ne '201' &&
		$posnr ne '210' && $posnr ne '211' &&
		$posnr ne '230');


  my $geb_kind=$self->{geb_kind};
  return '' if ($geb_kind eq '');
  my $days = Delta_Days(unpack('A4A2A2',$geb_kind),unpack('A4A2A2',$datum_l));
  my $zehn_spaeter=join('-',Add_Delta_Days(unpack('A4A2A2',$geb_kind),10));
  if ($days > 10 && 
      ($begruendung !~ /Anordnung/) &&
      ($l->leistungsdaten_werte($self->{frau_id},"POSNR","POSNR in (22,23,25,26,28,29,30,31,32,33,35,180,181,200,201,210,211,230) AND DATUM>'$zehn_spaeter'") > 15) ) {
    return 'FEHLER: Position '.$posnr.' ist ab dem 11 Tag h�chstens 16 mal berechnungsf�hig\nohne �rztliche Anordnung\nes wurde nichts gespeichert';
  }
  return '';
}





sub Begruendung_plausi {
  # Falls in den Leistungsdaten das Feld Begruendungspflicht auf j steht,
  # muss eine Begr�ndung vorhanden sein
  my $self=shift;
  my ($posnr,$datum_l,$begruendung)=    
    ($self->{posnr},$self->{datum_l},$self->{begruendung});

  if (uc $self->{begruendungspflicht} eq 'J' && 
      (!defined($begruendung ) || $begruendung eq '')) {
    return 'FEHLER: Bei Position '.$posnr.' ist eine Begr�ndung notwendig\n es wurde nichts gespeichert';
  }
  return '';
}



sub zeit {
  # liefert die Zeit zu der alternative Positionsnummern ausgew�hlt werden
  # m�ssen
  my $self=shift;

  return $self->{zeit_bis} if($l->zeit_ende($self->{posnr}));
  return $self->{zeit_von};
}


1;
