/* script f�r Plausipr�fungen und Navigation 
# im Rahmen der Leistungserfassung

# $Id: leistungen.js,v 1.17 2009-02-23 11:40:26 thomas_baum Exp $
# Tag $Name: not supported by cvs2svn $

# Copyright (C) 2004-2009 Thomas Baum <thomas.baum@arcor.de>
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
*/

//alert("leistung.js wird geladen");


function dia(form) {
  var begruendung = form.begruendung.value;
  //  alert("DIA"+begruendung);
  if (begruendung == 'Attest (auf �rztliche Anordnung)') {
    //   alert("Attest");
    // jetzt neues Feld aufnehmen
    var ueberschrift=document.createElement("TR");
    ueberschrift.id='dia_felder';
    //  alert("�berschrift-Id"+ueberschrift.id);
    var tab=document.getElementById("haupt_tab");
    var km_node=document.getElementById("zeile3_tab");
    tab.insertBefore(ueberschrift,km_node);
    ueberschrift.innerHTML="<td><table><tr><td colspan='2'><b>Diagnose Angaben</b></td></tr><tr><td><b>Schl�ssel</b></td><td><b>Text</b></td></tr><tr><td><input type='text' name='dia_schl' size='12' maxlength='12'></td><td><input type='text' name='dia_text' size='80' maxlength='70'></td></tr></table></td>";
  } else {
    // Felder m�ssen entfernt werden, falls vorhanden
    var tab=document.getElementById("haupt_tab");
    var ueberschrift=document.getElementById("dia_felder");
    // alert("ueberschrift"+ueberschrift);
    // �berschrift nur entfernen, wenn vorhanden
    if (ueberschrift != null) {
      tab.removeChild(ueberschrift);
    }
  }
}


function km(form,einaus) {
  // schaltet die KM Felder f�r Erfassung ein oder aus
  if(einaus == 'J') {
    form.entfernung_tag.disabled=false;
    form.entfernung_nacht.disabled=false;
    var zl_tag = document.getElementsByName('entfernung_tag');
    zl_tag[0].className='enabled';
    var zl_tag = document.getElementsByName('entfernung_nacht');
    zl_tag[0].className='enabled';
    var zl_tag = document.getElementsByName('anzahl_frauen');
    zl_tag[0].className='enabled';
  } else {
    form.entfernung_tag.disabled=true;
    form.entfernung_nacht.disabled=true;
    var zl_tag = document.getElementsByName('entfernung_tag');
    zl_tag[0].className='disabled';
    var zl_tag = document.getElementsByName('entfernung_nacht');
    zl_tag[0].className='disabled';
    var zl_tag = document.getElementsByName('anzahl_frauen');
    zl_tag[0].className='disabled';
    form.entfernung_tag.value=0;
    form.entfernung_nacht.value=0;
  }
}

function zeit(form,einaus) {
  // schaltet die Zeit von bis Felder f�r Erfassung ein oder aus
  if (einaus == 'J') {
    form.zeit_von.disabled=false;
    form.zeit_bis.disabled=false;
    var zl_tag = document.getElementsByName('zeit_von');
    zl_tag[0].className='enabled';
    var zl_tag = document.getElementsByName('zeit_bis');
    zl_tag[0].className='enabled';
    form.zeit_von.focus();
    //    form.zeit_von.select();
  } else {
    form.zeit_von.disabled=true;
    form.zeit_bis.disabled=true;
    var zl_tag = document.getElementsByName('zeit_von');
    zl_tag[0].className='disabled';
    var zl_tag = document.getElementsByName('zeit_bis');
    zl_tag[0].className='disabled';
    form.entfernung_tag.focus();
  }
}


function kurs_knopf() {
  // Feld f�r Anzahl Kurse auf Maske einschalten
  // nur wenn noch nicht vorhanden
  var ueberschrift_vor=document.getElementById("ueberschrift_anz_kurse");
  if (ueberschrift_vor == null) {
    var ueberschrift=document.createElement("TD");
    ueberschrift.id='ueberschrift_anz_kurse';
    //  alert("�berschrift-Id"+ueberschrift.id);
    var tab=document.getElementById("zeile1_tab");
    var preis_node=document.getElementById("preis_tab_id");
    tab.insertBefore(ueberschrift,preis_node);
    ueberschrift.innerHTML="<b>Anzahl&nbsp;Kurse</b>";
    
    var feld=document.createElement("TD");
    feld.id='anz_kurse';
    var tab2=document.getElementById("zeile2_tab");
    var preis_feld=document.getElementById("preis_id");
    tab2.insertBefore(feld,preis_feld);
    feld.innerHTML="<input type='text' name='anzahl_kurse' size='2'>";
  }
}

function loesche_kurs_knopf() {
  // Feld f�r Anzahl Kurse auf Maske ausschalten
  var tab=document.getElementById("zeile1_tab");
  var ueberschrift=document.getElementById("ueberschrift_anz_kurse");
  // alert("ueberschrift"+ueberschrift);
  // �berschrift nur entfernen, wenn vorhanden
  if (ueberschrift != null) {
    tab.removeChild(ueberschrift);
    var tab2=document.getElementById("zeile2_tab");
    var feld=document.getElementById("anz_kurse");
    tab2.removeChild(feld);
  }
  
}


function leistartsuchen (posnr) {
  open("leistungsartauswahl.pl?suchen=Suchen&posnr="+posnr,"leistungsartauswahl","scrollbars=yes,width=700,height=400");
}


function druck (form) {
  //  alert("druck"+form.frau_id.value);
  if (form.frau_id.value > 0) {
    open("../rechnung/rechnung_generierung.pl?frau_id="+form.frau_id.value,"_top");
  } else {
    alert ("Bitte erst Frau ausw�hlen");
  }
}

function aend (fr_id,ls_id,status) {
  // Leistungsposition zum �ndern aufrufen
  //  alert("Hallo aendern"+fr_id+"leist_id"+ls_id);
  if (status == 10) {
    open("rechpos.pl?frau_id="+fr_id+"&leist_id="+ls_id+"&func=2","rechpos");
  } else {
    alert("Rechnung wurde gespeichert, �ndern nicht m�glich");
  }
}
//alert("nach function aendern");

function loe_leistdat (fr_id,ls_id,status) {
  // leistungsposition zum L�schen aufrufen
  // alert("Hallo loeschen"+fr_id+"leist_id"+ls_id);
  if (status == 10) {
    open("rechpos.pl?frau_id="+fr_id+"&leist_id="+ls_id+"&func=3","rechpos");
  } else {
    alert("Rechnung wurde gedruckt, L�schen nicht m�glich");
  }
}

function wo_tag(datum,uhrzeit,form) {
  // liefert den Wochentag zu dem angegebenen Datum und Uhrzeit
  // datum ist im format tt.mm.jjjj
  // 0 ist Sonntag, usw.
  // falls Samstag wird auf 8 gestellt, wenn vor 12:00
  
  if (uhrzeit == '') uhrzeit = '10:00';
  //alert("Hallo2 wo tag"+datum+uhrzeit+form);
  var re =/(\d{1,2})\.(\d{1,2})\.(\d{1,4})/g;
  var re_uhr =/(\d{1,2}):(\d{1,2})/g;
  var ret = re.exec(datum);
  if (ret==null) {re.exec(datum);} // Fehler im Browser beheben
  var j = new Number(RegExp.$3);
  var m = new Number(RegExp.$2);
  var t = new Number(RegExp.$1);
  ret = re_uhr.exec(uhrzeit);
  if (ret==null) {re_uhr.exec(uhrzeit);}
  var h = new Number(RegExp.$1);
  //alert("h"+h);
  m--;
  var d = new Date(j,m,t); 
  var wtag = '';
  if (d.getDay()==0) {wtag = 'Sonntag'};
  if (d.getDay()==1) {wtag = 'Montag'};
  if (d.getDay()==2) {wtag = 'Dienstag'};
  if (d.getDay()==3) {wtag = 'Mittwoch'};
  if (d.getDay()==4) {wtag = 'Donnerstag'};
  if (d.getDay()==5) {wtag = 'Freitag'};
  if (d.getDay()==6 && h < 12) {wtag = 'Samstag vor 12:00'};
  if (d.getDay()==6 && h >= 12) {wtag = 'Samstag nach 12:00'};
  form.wotag.value = wtag;
  //alert("datum"+d);
  
}

function zeit_preis(preis,zeit,mass) {
  // berechnet in Abh�ngigkeit der Zeit den Preis
  // datum ist im format tt.mm.jjjj
  // 0 ist Sonntag, usw.
  var re =/(\d{1,2}):(\d{1,2})/g;
    var ret = re.exec(zeit);
    if (ret==null) {re.exec(zeit);} // Fehler im Browser beheben
    var h = new Number(RegExp.$1);
    var m = new Number(RegExp.$2);
    var minuten = h*60+m;
    var rest = minuten % mass;
    var ber = minuten - rest;
    ber = ber / mass;
    ber++;
    var preis = preis * ber;
    preis = preis + 0.005; // runden
    preisre = /(\d*\.\d{2})/;
    preisre.exec(preis);
    preis = RegExp.$1;
    return preis;
}

function leistung_speicher(formular) {
  //alert("speichern");
  //  Plausipr�fungen, bevor Formular abgeschickt wird.
  if(!uhrzeit_check(formular.zeit_von)) {
    //    alert("Zeit von nicht korrekt erfasst");
    return false;
  }
  if(!uhrzeit_check(formular.zeit_bis)) {
    //    alert("Zeit bis nicht korrekt erfasst");
    return false;
  }
  if(!datum_check(formular.datum)) {
    //    alert("Datum nicht korrekt erfasst");
    return false;
  }
  if(!numerisch_check(formular.entfernung_tag)) {
    //  alert ("numeric pr�fung");
    return false;
  }
  if(!numerisch_check(formular.entfernung_nacht)) {
    //  alert ("numeric pr�fung");
    return false;
  }
  return true;
}

function round(wert) {
  // rundet den angegebenen Wert kaufm�nnisch
  // und liefert den Wert mit 2 NK stellen zur�ck
  wert+=0.005;
  wertre = /(\d*\.\d{2})/;
  wertre.exec(wert);
  return RegExp.$1;
}


function next_satz_leistart(formular) {
  //  alert("next"+formular.leist_id);
  id = formular.leist_id.value;
  if(formular.auswahl.value == 'Anzeigen') {
    open("leistungsarterfassung.pl?func=1&leist_id="+id,"_top");
  } else {
    alert("Bitte Menuepunkt Anzeigen w�hlen");
  }
}


function prev_satz_leistart(formular) {
  id = formular.leist_id.value;
  if(formular.auswahl.value == 'Anzeigen') {
    open("leistungsarterfassung.pl?func=2&leist_id="+id,"_top");
  } else {
    alert("Bitte Menuepunkt Anzeigen w�hlen");
  }
}


function l_eintrag(id) {
  // in Parent Dokument �bernehmen
  var formular=opener.window.name;
  opener.window.location="leistungsarterfassung.pl?func=3&leist_id="+id;
  self.close();
}



//alert("leistungen.js ist geladen");
