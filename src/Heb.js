/* script f�r generelle Plausipr�fungen und Navigation
# im Rahmen der Leistungserfassung

# $Id: Heb.js,v 1.16 2009-05-31 04:48:19 thomas_baum Exp $
# Tag $Name: not supported by cvs2svn $

# Copyright (C) 2004 - 2009 Thomas Baum <thomas.baum@arcor.de>
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


//alert("Heb.js wird geladen");

function haupt() {
  // springt von einem Untermenue ins Hauptmenue
open("../hebamme.html","_top");
}

function stamm(id,formular) {
  // springt von einem Untermenue in die Stammdatenerfassung
  if (formular.name != 'rechnungen_gen' && formular.name != 'rechposbear' &&
      formular.name != 'mahnung_gen') {
    open("stammdatenerfassung.pl?func=3&frau_id="+id,"_top");
  } else {
    open("../erfassung/stammdatenerfassung.pl?func=3&frau_id="+id,"_top");
  }
}

function plz_check(plz) {
  // pr�ft ob die erfasste PLZ einen g�ltigen Wert hat
  re=/^\d{5}$/;
  if (plz.value != '' && !re.test(plz.value)) {
    alert("Bitte PLZ 5 stellig numerisch erfassen");
    plz.focus();
    plz.select();
    return false;
  }
  return true;
}

function numerisch_check(num) {
  // pr�ft ob der �bergebene Wert numerisch oder leer ist.
  if (num.value == '') { return true; }
  re=/^\d{0,5},{0,1}\d{0,2}$/;
  if (num.value != '' && !re.test(num.value)) {
    alert("Bitte numerischen Wert erfassen");
    num.focus();
    num.select();
    return false;
  }
  return true;
}


function datum_check(datum) {
// pr�ft ob Datum im Format tt.mm.jjjj erfasst wurde, oder leer ist
  //  alert("datum value"+datum.value);
  if (datum.value == '') { return true; }
  re=/^(\d{1,2})[\.,](\d{1,2})[\.,](\d{1,4})$/;
  var ret = re.exec(datum.value);
  var j = Number (RegExp.$3);
  var m = Number (RegExp.$2);
  var t = Number (RegExp.$1);
  //alert("datum_check"+datum);
  if (!ret) {
    re=/^(\d{2})(\d{2})(\d{2})$/;
    ret = re.exec(datum.value);
    j = Number (RegExp.$3);
    m = Number (RegExp.$2);
    t = Number (RegExp.$1);   
    if(!ret) {
      alert("Bitte Datum im Format tt.mm.jjjj erfassen");
      datum.select();
      datum.focus();
      return false;
    }
  } 

  if (j>99 && j<1900) {
    alert("Bitte g�ltiges Datum erfassen");
    datum.select();
    datum.focus();
    return false;
    }
  if (j<50 && j<100) {j += 2000;}
  if (j>49 && j<100) {j += 1900;}
  // pr�fen ob Datum existiert, z.B. 31.2.05
  if (t > 31 || m > 12 ||
      m == 0 || t == 0 ||
      (m == 2 && t > 29) ||  // Februar
      (m == 2 && t > 28 && (!(j % 4)==0)) || // Februar ohne Schaltjahr
      ((m==4 || m==6 || m==9 || m==11) && t > 30) // Monate mit 30 Tagen
      ) {
    alert("Bitte g�ltiges Datum erfassen");
    datum.select();
    datum.focus();
    return false;
  }
  datum.value=RegExp.$1+"."+RegExp.$2+"."+j;
  return true;
}


function uhrzeit_check(uhrzeit) {
  if (uhrzeit.value != '') {
    //             alert ("Uhrzeit"+Event.type);
    // pr�ft ob Uhrzeit im Format hh:mm oder hhmm erfasst wurde, oder leer ist
    re=/^(\d{1,2}):(\d{1,2})$/;
      if (re.test(uhrzeit.value) && (RegExp.$1 < 24 && RegExp.$2 < 60)) {
	return true;
      } else {
	//	alert("noch nicht korrekt 2");
	re2=/^(\d{1,2})(\d{2})$/;
	if (re2.test(uhrzeit.value) && RegExp.$1 < 24 && RegExp.$2 < 60) {
	  uhrzeit.value=RegExp.$1+':'+RegExp.$2;
	  return true;
	} else {
	  alert("Bitte g�ltige Uhrzeit im Format hh:mm erfassen");
	  uhrzeit.select();
	  uhrzeit.focus();
	  return false;
	}
      }
  }
  return true;
}

function set_focus(formular) {
// setzt den Focus auf das erste Formularfeld das leer ist
var i=formular.length;
var y=1;
while ( i >= 1 ) {
	if (undefined != formular.elements[i]) {
      	if (formular.elements[i].value == '') {
           y = i;
        }
    }
  i--;
}
formular.elements[y].focus();
formular.elements[y].select();
}
  
function auswahl_wechsel (formular) {
// in Abh�ngigkeit der gew�hlten Funktion werden Kn�pfe disabled/enabled
	var wert=formular.auswahl.value;
	//	alert("auswahl wechsel"+wert+formular.auswahl.value);
	switch (wert) {
	case 'Neu': {
		//alert("neu");
		formular.vorheriger.disabled=true;
		formular.naechster.disabled=true;
		formular.reset.disabled=false;
		formular.abschicken.disabled=false;
		formular.abschicken.value='Speichern';
		break;
		}
	case '�ndern': {
		//alert("�ndern");
		formular.vorheriger.disabled=true;
		formular.naechster.disabled=true;
		formular.reset.disabled=true;
		formular.abschicken.disabled=false;
		formular.abschicken.value='Speichern';
		break;
		}
	case 'Anzeigen': {
		//alert("anzeigen");
		formular.vorheriger.disabled=false;
		formular.naechster.disabled=false;
		formular.reset.disabled=true;
		formular.abschicken.disabled=true;
		break;
		}
	case 'L�schen': {
		//alert("loeschen");
		formular.vorheriger.disabled=true;
		formular.naechster.disabled=true;
		formular.reset.disabled=false;
		formular.abschicken.disabled=false;
		formular.abschicken.value='L�schen';
		break;
		}
	default: {
		alert("default");
		}
	}
}		

//alert("heb.js ist geladen");
