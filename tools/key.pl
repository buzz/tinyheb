#!/usr/bin/perl -w
# -d:DProf
# -d:ptkdb
# -wT

# extrahiert aus Schl�sseldateien des Trust Center ITSG die einzelnen
# Schl�ssel

# $Id$
# Tag $Name$

# Copyright (C) 2005 - 2011 Thomas Baum <thomas.baum@arcor.de>
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

BEGIN {
  if(eval "use Crypt::OpenSSL::X509;1") {
    warn "using Crypt::OpenSSL::X509";
    *main::ssl_func= \&get_all_x509;
  } else {
    warn "using OpenSSL command line";
    *main::ssl_func= \&get_all;
  }
#  *main::ssl_func= \&get_all;
}


use strict;
use Date::Calc qw(This_Year Decode_Month Add_Delta_DHMS);
use Getopt::Std;
use File::Copy;

use lib '../';
use Heb_krankenkassen;
use Heb;


my $k = new Heb_krankenkassen;
my $h = new Heb;

my $openssl ='openssl';
my $root_cert_counter=0;

$openssl = $h->win32_openssl() if ($^O =~ /MSWin32/);


if (!defined($openssl)) {
  die "konnte openssl Installation nicht finden\n";
}

my %option = ();
getopts("cstvp:f:o:hu",\%option);

if ($option{h}) {
  print "
 usage:  $0 options dateien pfad
 -v <-> debug/verbose
 -p <-> path
 -f <-> file
 -o <-> output path
 -u <-> update auf Datenbank
 -t <-> hTml formatierte Ausgabe
 -s <-> speichert die einzelnen Zertifikate in jeweils eigener Datei
 -c <-> speichert Zertifikat der Hebamme im korrekten Verzeichnis
 -h <-> help
";
  exit;
}




use lib "../";
my $debug = $option{v} || 0;
my $save_cert = $option{c} || '';
my $eingabe = $option{f} || '';
my $pfad = $option{p} || '';
my $o_pfad = $option{o} || 'keys/';
my $html = $option{t} || '';
my $save = $option{s} || 0;


my $counter=0; # Z�hlt die eingelesenen Zertifikate

our $path = $ENV{HOME}; # f�r tempor�re Dateien
if ($^O =~ /MSWin32/) {
  $path .='/tinyheb';
  mkdir "$path" if (!(-d "$path")); # Zielverzeichnis anlegen
} else {
  $path .='/.tinyheb';
}
		   
my $orig_path = $path;

mkdir "$path" if(!(-d "$path"));
if (!(-d "$path/tmp")) { # Zielverzeichnis anlegen
  mkdir "$path/tmp";
}
$path.='/tmp';
$path='/tmp/wwwrun/' if ($html);

if (!(-d "$o_pfad") && $save) {
  die "der Ausgabepfad: $o_pfad existiert nicht, bitte anlegen\n";
}

print "<table>" if $html;

		     

#$eingabe = 'kostentraeger/'.$eingabe;
print "Einlesen der Daten von Datei: $eingabe\n" if $debug;

my @dateien = split ' ',$eingabe;

foreach my $file (@dateien) {
  $file = $pfad.$file;
  # �ffnen der Datei mit den Informationen
  open FILE, $file or die "Konnte Datei $file nicht zum Lesen �ffnen $!\n";
  
  my $line_counter = 0; 
  my $zeile = '';
  my $file_counter = 1; # Z�hler f�r Ausgabe Datei
  my $erg = ''; # ergebnisstring f�r update auf Datenbank
  my $ik = 0;
  
  # �ffnen Datei zum schreiben
  unlink("$path/tmpcert.pem");
  open SCHREIB, ">$path/tmpcert.pem"
    or die "Konnte Datei nicht zum schreiben �ffnen $!\n";
  
  print SCHREIB "-----BEGIN CERTIFICATE-----\n";
 LINE:while ($zeile=<FILE>) {
    my $ent = chomp($zeile);
    if (length($zeile)>1) {
      print SCHREIB $zeile."\n";
      $erg .= $zeile."\n";
    } else {  
      print SCHREIB "-----END CERTIFICATE-----\n";
      close(SCHREIB);
      

      my ($ik,
	  $organisation,
	  $herausgeber,
	  $ansprechpartner,
	  $start,
	  $ende,
	  $serial,
	  $algorithmus,
	  $pubkey_laenge)=ssl_func("$path/tmpcert.pem");

      die "konnte Seriennummer eines Zertifikates nicht ermittlen\n" unless ($serial);
      print "Seriennummer $serial\n" if $debug;

      $counter++;
#      my ($pubkey_laenge,$algorithmus)=get_public_key("$path/tmpcert.pem");
      print "public key: $pubkey_laenge, algo: $algorithmus\n" if $debug;

      if ($pubkey_laenge < 2000) {
	print "Schl�ssel zu kurz f�r IK: $ik Schl�ssell�nge: $pubkey_laenge < 2000 entweder die Datei annahme-pkcs.key oder gesamt-pkcs.key einspielen, die Vearbeitung wird abgebrochen\n";
	die;
      }


      print "Einlesen Schl�ssel f�r IK: $ik\n" if $debug && $ik;
      if ($ik) {
	copy("$path/tmpcert.pem","$o_pfad/$ik.pem") if (-e "$path/tmpcert.pem" && $save);
      } else {
	print "keine IK Nummer im Zertifikat enthalten\n" if $debug;
	$root_cert_counter++;
	copy("$path/tmpcert.pem","$o_pfad/root$root_cert_counter.pem") if (-e "$path/tmpcert.pem" && $save);
      }
      if ($ik && $save_cert && $ik eq $h->parm_unique('HEB_IK')) {
	if (-e "$path/tmpcert.pem") {
	  copy("$path/tmpcert.pem","$orig_path/privkey/$ik.pem");
	  print "Habe Zerfikat fuer $ik nach $orig_path/privkey/$ik.pem kopiert\n";
	}
      }
      if (($save_cert || $save) && $counter % 100 == 0) {
	print "verarbeitete Zertifikate $counter\r";
      }

      if ($ik && 
	  $herausgeber !~ /ITSG TrustCenter fuer sonstige Leistungserbringer/ && 
	  $herausgeber !~ /DKTIG TrustCenter fuer Krankenhaeuser und Leistungserbringer PKC/) {
	print "Herausgeber des Schl�ssels/ Zertifikats ist nicht das Trustcenter f�r sonstige Leistungserbringer, Verarbeitung wird abgebrochen\n";
	die;
      }
#      create_parms($ik) if ($ik);
      print_html($ik,$organisation,$ansprechpartner,$start,$ende,$herausgeber,$serial,$pubkey_laenge,$algorithmus) if ($html && $ik);      

     if ($ik && $option{u} && $k->krankenkasse_sel('NAME',$ik)) {
	# kasse existiert update machen
	$k->krankenkassen_up_pubkey($erg,$ik);
      }

      $erg = '';
      $ik=0;

      # n�chste Datei zum Schreiben �ffnen
      unlink("$path/tmpcert.pem");
      open SCHREIB, ">$path/tmpcert.pem"
	or die "Konnte Datei nicht zum schreiben �ffnen $!\n";
      print SCHREIB "-----BEGIN CERTIFICATE-----\n";

      print "------------------------------\n" if $debug;
    }
  }
  close (FILE);
  print SCHREIB "-----END CERTIFICATE-----\n";
  close (SCHREIB);
}
unlink("$path/tmpcert.pem");

print "</table>" if $html;

if ($save_cert || $save) {
  print "verarbeitete Zertifikate $counter\n";
}


sub get_all {
  my ($cert_name) = @_;
  system("$openssl x509 -in $cert_name -subject -dates -serial -noout -certopt no_header -certopt no_subject -certopt no_sigdump -certopt no_validity -certopt no_serial -certopt no_version -certopt no_issuer -certopt no_signame -text") if $debug;
  open LESNAME,"$openssl x509 -in $cert_name -subject -dates -serial -noout -certopt no_header -certopt no_subject -certopt no_sigdump -certopt no_validity -certopt no_serial -certopt no_version -certopt no_issuer -certopt no_signame -text |" or 
    die "konnte aus Zertifikat keine Organisation ermitteln\n";

  my $guelt_von=undef;
  my $guelt_bis=undef;
  my $herausgeber=undef;
  my $ansprechpartner=undef;
  my $organisation=undef;
  my $serial=undef;
  my $ik=undef;
  my $algorithmus=undef;
  my $pubkey_laenge=undef;

  while (my $name=<LESNAME>) {
    if ($name =~ /^notBefore=(.*?)$/) {
      $guelt_von=$1;
    }
    if ($name =~ /^notAfter=(.*?)$/) {
      $guelt_bis=$1;
    }
    if ($name =~ /OU=(.*?)\/OU=/) {
      $organisation=$1;
    }
    if ($name =~ /O=(.*?)\/OU/) {
      $herausgeber=$1;
    }
    if ($name =~ /CN=(.*?)$/) {
      $ansprechpartner=$1;
    }
    if ($name =~ /^serial=(.*?)$/) {
      $serial=hex($1);
    }
    if ($name =~ /OU=IK(\d{9})/) {
      $ik=$1;
    }
    if ($name =~ /Public Key Algorithm: (.*?)$/) {
      $algorithmus = $1;
    }
    if ($name =~ /Public[- ]Key: \((\d{1,4}) bit/) {
      $pubkey_laenge = $1;
    }
  }
  close(LESNAME);
  return ($ik,$organisation,$herausgeber,$ansprechpartner,$guelt_von,$guelt_bis,$serial,$algorithmus,$pubkey_laenge);

}


sub get_all_x509 {
  my ($cert_name) = @_;
  my $x509 = Crypt::OpenSSL::X509->new_from_file($cert_name);

  my $guelt_von=$x509->notBefore();
  my $guelt_bis=$x509->notAfter();
  my $herausgeber=$x509->issuer();
  my $ansprechpartner=undef;
  my $organisation='';
  my $serial=hex($x509->serial());
  my $ik=undef;
  my $algorithmus='';
  my $pubkey=$x509->pubkey();
  my $modulus=$x509->modulus();
  my $pubkey_laenge=length($modulus)*4;
  my $cert=$x509->as_string(1);

  my $name = $x509->subject();


  (undef,undef,$organisation,$ik,$ansprechpartner) = split ',',$name;
  $organisation = '' unless($organisation);
  $organisation =~ s/ OU=//;
  $ik = '' unless($ik);
  $ik =~ s/ OU=IK//;
  $ansprechpartner='' unless($ansprechpartner);
  $ansprechpartner =~ s/ CN=//;

  (undef,$herausgeber) = split ',',$herausgeber;
  $herausgeber =~ s/ O=//;

  return ($ik,$organisation,$herausgeber,$ansprechpartner,$guelt_von,$guelt_bis,$serial,$algorithmus,$pubkey_laenge);

}




sub print_html {
  # ausgabe der ermittleten Infos als HTML
  my ($ik,$organisation,$ansprechpartner,$guelt_von,$guelt_bis,$herausgeber,$serial,$pubkey_laenge,$algorithmus)=@_;

  my ($kname)=$k->krankenkasse_sel('KNAME',$ik);
  my $print_name = $kname;
  $print_name ='' unless(defined($kname));
  print "<tr><td>";

  print "<h2>&nbsp;</h2>\n";
  print '<table border="1" align="left" style="margin-bottom: +2em; width: 16cm; empty-cells: show">';
  print "<caption style='caption-side: top;'><h2>$ik $print_name</h2></caption>\n";
  print "<tr>\n";
  print "<th style='width:2cm; text-align:left'>Feld</th><th style='width:9cm; text-align:left'>Wert</th></tr>\n";
  print "<tr><td>Seriennummer</td><td style='vertical-align:top'>$serial</td></tr>\n";
  print "<tr><td>Organisation</td><td style='vertical-align:top'>$organisation</td></tr>\n";
  print "<tr><td>Ansprechpartner</td><td style='vertical-align:top'>$ansprechpartner</td></tr>\n";
  print "<tr><td>G�ltig von</td><td style='vertical-align:top'>$guelt_von</td></tr>\n";
  print "<tr><td>G�ltig bis</td><td style='vertical-align:top'>$guelt_bis</td></tr>\n";
  print "<tr><td>Herausgeber</td><td style='vertical-align:top'>$herausgeber</td></tr>\n";
  print "<tr><td>L�nge des Schl�ssels</td><td style='vertical-align:top'>$pubkey_laenge bit</td></tr>\n";
  print "<tr><td>Algorithmus des Schl�ssels</td><td style='vertical-align:top'>$algorithmus</td></tr>\n";
  my $test_ind = $h->parm_unique('IK'.$ik);
  my ($ktr,$da)=$k->krankenkasse_ktr_da($ik);
  my $status_edi='';
  $status_edi = 'bisher kein Schl�ssel' unless(defined($test_ind));
  $status_edi .= ', wird nicht angelegt, weil keine Datenannahmestelle' if($da != $ik && $da != 0 || !(defined($kname)));
  $status_edi='Testphase' if (defined($test_ind) && $test_ind == 0);
  $status_edi='Erprobungsphase' if (defined($test_ind) && $test_ind == 1);
  $status_edi='Echtbetrieb' if (defined($test_ind) && $test_ind == 2);
  print "<tr><td>Status Datenaustausch</td><td style='vertical-align:top'>$status_edi</td></tr>\n";
  print "</table><br/><br/>\n\n";
  print "</td></tr>";
}



sub create_parms {
  # legt Parameter an, falls zur Datennahmestelle noch keine
  # vorhanden sind
  my ($ik)=@_;
  my ($kname,$email)=$k->krankenkasse_sel('KNAME,EMAIL',$ik);
  if (defined($kname)) {
    my $test_ind = $h->parm_unique('IK'.$ik);
    if (defined($test_ind)) {
      print "Datenannahmestelle $ik ist schon im Datenhaushalt mit: $test_ind\n";
      print "<br/>" if ($html);
    } else {
      my ($ktr,$da)=$k->krankenkasse_ktr_da($ik);
      print "$ik ist nicht im Datenhaushalt,\nKTR: $ktr, DA: $da ";
      print "<br/>" if ($html);
      if ($da == $ik || $da == 0) {
	print "wird als Datenannahmestelle angelegt\n";
	print "IK$ik. 00\n";
	print "DTAUS$ik 1\n";
	print "SCHL$ik 03\n";
	print "SIG$ik 00\n";
	print "MAIL$ik $email\n";
	if ($option{u}) {
	  $h->parm_ins("IK$ik","00","Datenannahmestelle ($kname) Testindikator 0=Test, 1=Erprobungsphase,2=Produktion");
	  $h->parm_ins("DTAUS$ik","01","Datenaustauschreferenz f�r diese Datenannahmestelle ($kname)");
	  $h->parm_ins("SCHL$ik","03","Verschl�sselung f�r diese Datenannahmestelle ($kname)");
	  $h->parm_ins("SIG$ik","00","Signatur f�r diese Datenannahmestelle ($kname)");
	  $h->parm_ins("MAIL$ik",$email,"Mail Adresse der Datenanname stelle ($kname)");
	}
      } else {
	print "wird nicht angelegt, weil keine Datenannahmestelle\n" if(!$html);
      }
    }
  } else {
    print "ist weder Datenannahmestelle noch Krankenkasse\n" if(!$html);
    print "<br/>" if ($html);
  }
  
}

1;
