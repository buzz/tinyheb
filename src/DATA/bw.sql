# Updates f�r tinyHeb
#
# $Id: bw.sql,v 1.1 2009-11-17 10:07:10 thomas_baum Exp $
# Tag $Name: not supported by cvs2svn $
#
# Hebammengeb�hrenordnung f�r Baden-W�rtemberg
#
# PosNr 1a
#
WWWRUN	INSERT	Leistungsart	POSNR='1a' and GUELT_VON='1999-09-01' and GUELT_BIS='9999-12-31'	insert into Leistungsart (ID,POSNR,LEISTUNGSTYP,KBEZ,EINZELPREIS,BEZEICHNUNG,GUELT_VON,GUELT_BIS,FUERZEIT,ZUSATZGEBUEHREN1,SONNTAG,NACHT) values (9999,'1a','A','Hilfeleistung bei Beschwerden',25.56,'Hilfeleistung bei Schwangerschaftsbeschwerden oder bei Wehen, die vor der eigentlichen Geburt oder Fehlgeburt und zeitlich nicht zusammenh�ngend mit ihr auftreten, in oder au�erhalb der Wohnung der Hebamme oder des Entbindungspflegers f�r jede angefangene halbe Stunde','1999-09-01','9999-12-31',30,'','+16a','+16a');
#
# PosNr 1b
#
WWWRUN	INSERT	Leistungsart	POSNR='1b' and GUELT_VON='1999-09-01' and GUELT_BIS='9999-12-31'	insert into Leistungsart (ID,POSNR,LEISTUNGSTYP,KBEZ,EINZELPREIS,BEZEICHNUNG,GUELT_VON,GUELT_BIS,FUERZEIT,ZUSATZGEBUEHREN1,KILOMETER,SONNTAG,NACHT) values (9999,'1b','A','Raterteilung durch Fernsprecher',7.67,'Raterteilung durch Fernsprecher','1999-09-01','9999-12-31',0,'','N','+16a','+16a');
#
# PosNr 1c
#
WWWRUN	INSERT	Leistungsart	POSNR='1c' and GUELT_VON='1999-09-01' and GUELT_BIS='9999-12-31'	insert into Leistungsart (ID,POSNR,LEISTUNGSTYP,KBEZ,EINZELPREIS,BEZEICHNUNG,GUELT_VON,GUELT_BIS,FUERZEIT,ZUSATZGEBUEHREN1,SONNTAG,NACHT) values (9999,'1c','A','Hilfeleistung bei Beschwerden in Wohnung Hebamme',10.23,'Hilfeleistung bei Schwangerschaftsbeschwerden in der Wohnung der Hebamme','1999-09-01','9999-12-31',0,'','+16a','+16a');
#
#
# PosNr 2a
#
WWWRUN	INSERT	Leistungsart	POSNR='2a' and GUELT_VON='1999-09-01' and GUELT_BIS='9999-12-31'	insert into Leistungsart (ID,POSNR,LEISTUNGSTYP,KBEZ,EINZELPREIS,BEZEICHNUNG,GUELT_VON,GUELT_BIS,FUERZEIT,ZUSATZGEBUEHREN1,NICHT) values (9999,'2a','A','Vorsorgeuntersuchung',35.79,'Die Vorsorgeuntersuchung umfa�t folgende Leistungen: Gewichtskontrolle, Blutdruckmessung, Urinuntersuchung auf Eiwei� und Zucker, Kontrolle des Standes der Geb�rmutter, Feststellung der Lage, Stellung und Haltung des Kindes','1999-09-01','9999-12-31',0,'','1a,1b,1c');
#
#
# PosNr 2b
#
WWWRUN	INSERT	Leistungsart	POSNR='2b' and GUELT_VON='1999-09-01' and GUELT_BIS='9999-12-31'	insert into Leistungsart (ID,POSNR,LEISTUNGSTYP,KBEZ,EINZELPREIS,BEZEICHNUNG,GUELT_VON,GUELT_BIS,FUERZEIT,ZUSATZGEBUEHREN1,NICHT) values (9999,'2b','A','Entnahme von K�rpermaterial',9.71,'Entnahme von K�rpermaterial zur Durchf�hrung notwendiger Laboruntersuchungen, je Entnahme einschlie�lich Veranlassung und Befund�bermittlung sowie Versandkosten und Portokosten','1999-09-01','9999-12-31',0,'','');
#
#
# PosNr 3aa
#
WWWRUN	INSERT	Leistungsart	POSNR='3aa' and GUELT_VON='1999-09-01' and GUELT_BIS='9999-12-31'	insert into Leistungsart (ID,POSNR,LEISTUNGSTYP,KBEZ,EINZELPREIS,BEZEICHNUNG,GUELT_VON,GUELT_BIS,FUERZEIT,ZUSATZGEBUEHREN1,NICHT) values (9999,'3aa','A','Geburtsvorbereitung Gruppe',8.18,'Geburtsvorbereitung in Gruppen bis zu zehn Schwangeren','1999-09-01','9999-12-31','E60','','');
#
#
# PosNr 3ab
#
WWWRUN	INSERT	Leistungsart	POSNR='3ab' and GUELT_VON='1999-09-01' and GUELT_BIS='9999-12-31'	insert into Leistungsart (ID,POSNR,LEISTUNGSTYP,KBEZ,EINZELPREIS,BEZEICHNUNG,GUELT_VON,GUELT_BIS,FUERZEIT,ZUSATZGEBUEHREN1,NICHT,BEGRUENDUNGSPFLICHT) values (9999,'3ab','A','Einzelgeburtsvorbereitung',23.52,'Einzelgeburtsvorbereitung auf �rztliche Anordnung','1999-09-01','9999-12-31','E60','','','j');
#
#
# PosNr 3b
#
WWWRUN	INSERT	Leistungsart	POSNR='3b' and GUELT_VON='1999-09-01' and GUELT_BIS='9999-12-31'	insert into Leistungsart (ID,POSNR,LEISTUNGSTYP,KBEZ,EINZELPREIS,BEZEICHNUNG,GUELT_VON,GUELT_BIS,FUERZEIT,ZUSATZGEBUEHREN1,NICHT) values (9999,'3b','A','sonstiger Besuch',28.12,'f�r jeden sonstigen Besuch, insb. Schwangerenberatung �ber Lebensweise und Ern�hrungsweise sowie die Zweckm��igkeit der Inanspruchnahme �rztlicher Betreuung','1999-09-01','9999-12-31',0,'','');
#
#
# PosNr 4
#
WWWRUN	INSERT	Leistungsart	POSNR='4' and GUELT_VON='1999-09-01' and GUELT_BIS='9999-12-31'	insert into Leistungsart (ID,POSNR,LEISTUNGSTYP,KBEZ,EINZELPREIS,BEZEICHNUNG,GUELT_VON,GUELT_BIS,FUERZEIT,ZUSATZGEBUEHREN1,NICHT) values (9999,'4','A','Rhesus-Antik�rper-Prophylaxe',10.23,'F�r die Mitwirkung bei der Rhesus-Antik�rper-Prophylaxe (gegebenenfalls einschlie�lich der Beschaffung des entsprechenden Medikaments)','1999-09-01','9999-12-31',0,'','');
#
#
# PosNr 5
#
WWWRUN	INSERT	Leistungsart	POSNR='5' and GUELT_VON='1999-09-01' and GUELT_BIS='9999-12-31'	insert into Leistungsart (ID,POSNR,LEISTUNGSTYP,KBEZ,EINZELPREIS,BEZEICHNUNG,GUELT_VON,GUELT_BIS,FUERZEIT,ZUSATZGEBUEHREN1,NICHT) values (9999,'5','A','CTG �berwachung',11.25,'kardiographische �berwachung','1999-09-01','9999-12-31',0,'','');
#
#
#
# Leistungsgruppe B Geburtshilfe
#
# PosNr 6a
#
WWWRUN	INSERT	Leistungsart	POSNR='6a' and GUELT_VON='1999-09-01' and GUELT_BIS='9999-12-31'	insert into Leistungsart (ID,POSNR,LEISTUNGSTYP,KBEZ,EINZELPREIS,BEZEICHNUNG,GUELT_VON,GUELT_BIS,FUERZEIT,ZUSATZGEBUEHREN1,NICHT) values (9999,'6a','B','Hausgeburt',664.68,'F�r den Beistand bei einer regelm��igen oder einer fr�hzeitigen Hausgeburt','1999-09-01','9999-12-31',0,'','');
#
#
# PosNr 6b
#
WWWRUN	INSERT	Leistungsart	POSNR='6b' and GUELT_VON='1999-09-01' and GUELT_BIS='9999-12-31'	insert into Leistungsart (ID,POSNR,LEISTUNGSTYP,KBEZ,EINZELPREIS,BEZEICHNUNG,GUELT_VON,GUELT_BIS,FUERZEIT,ZUSATZGEBUEHREN1,NICHT) values (9999,'6b','B',"Geburt im K'haus",357.90,'Hilfe bei der Geburt eines Kindes im Krankenhaus','1999-09-01','9999-12-31',0,'','');
#
#
# PosNr 6c
#
WWWRUN	INSERT	Leistungsart	POSNR='6c' and GUELT_VON='1999-09-01' and GUELT_BIS='9999-12-31'	insert into Leistungsart (ID,POSNR,LEISTUNGSTYP,KBEZ,EINZELPREIS,BEZEICHNUNG,GUELT_VON,GUELT_BIS,FUERZEIT,ZUSATZGEBUEHREN1,NICHT) values (9999,'6c','B','Geburt au�erkl. �rztl. Leitung',357.90,'Hilfe bei einer au�erklinischen Geburt in einer Einrichtung unter �rztl. Leitung','1999-09-01','9999-12-31',0,'','');
#
#
# PosNr 6d
#
WWWRUN	INSERT	Leistungsart	POSNR='6d' and GUELT_VON='1999-09-01' and GUELT_BIS='9999-12-31'	insert into Leistungsart (ID,POSNR,LEISTUNGSTYP,KBEZ,EINZELPREIS,BEZEICHNUNG,GUELT_VON,GUELT_BIS,FUERZEIT,ZUSATZGEBUEHREN1,NICHT) values (9999,'6d','B','Geburt au�erkl. Leitung Heb.',562.42,'Hilfe bei einer au�erklinischen Geburt in einer von Hebammen geleiteten Einrichtung','1999-09-01','9999-12-31',0,'','');
#
#
# PosNr 7
#
WWWRUN	INSERT	Leistungsart	POSNR='7' and GUELT_VON='1999-09-01' and GUELT_BIS='9999-12-31'	insert into Leistungsart (ID,POSNR,LEISTUNGSTYP,KBEZ,EINZELPREIS,BEZEICHNUNG,GUELT_VON,GUELT_BIS,FUERZEIT,ZUSATZGEBUEHREN1,NICHT) values (9999,'7','B','Zuschlag Zwillinge',102.26,'Zuschlag f�r Hilfe bei der Geburt von Zwillingen und mehr Kindern, f�r das zweite und jedes weitere Kind','1999-09-01','9999-12-31',0,'','');
#
#
# PosNr 8a
#
WWWRUN	INSERT	Leistungsart	POSNR='8a' and GUELT_VON='1999-09-01' and GUELT_BIS='9999-12-31'	insert into Leistungsart (ID,POSNR,LEISTUNGSTYP,KBEZ,EINZELPREIS,BEZEICHNUNG,GUELT_VON,GUELT_BIS,FUERZEIT,ZUSATZGEBUEHREN1,NICHT) values (9999,'8a','B','Dammri�/-schnitt  I./II.',43.46,'N�hen eines kleinen Dammschnitts oder eines Dammrisses','1999-09-01','9999-12-31',0,'','');
#
#
# PosNr 8b
#
WWWRUN	INSERT	Leistungsart	POSNR='8b' and GUELT_VON='1999-09-01' and GUELT_BIS='9999-12-31'	insert into Leistungsart (ID,POSNR,LEISTUNGSTYP,KBEZ,EINZELPREIS,BEZEICHNUNG,GUELT_VON,GUELT_BIS,FUERZEIT,ZUSATZGEBUEHREN1,NICHT,SAMSTAG,SONNTAG,NACHT) values (9999,'8b','B','2. Hebamme',23.52,'Hilfe bei einer au�erklinischen Geburt oder Fehlgeburt durch eine zweite Hebamme f�r jede angefangene halbe Stunde','1999-09-01','9999-12-31',30,'','','8c','8c','8c');
#
#
# PosNr 8c
#
WWWRUN	INSERT	Leistungsart	POSNR='8c' and GUELT_VON='1999-09-01' and GUELT_BIS='9999-12-31'	insert into Leistungsart (ID,POSNR,LEISTUNGSTYP,KBEZ,EINZELPREIS,BEZEICHNUNG,GUELT_VON,GUELT_BIS,FUERZEIT,ZUSATZGEBUEHREN1,NICHT) values (9999,'8c','B','2. Hebamme Sa,So,Nacht',29.65,'Hilfe bei einer au�erklinischen Geburt oder Fehlgeburt durch eine zweite Hebamme f�r jede angefangene halbe Stunde','1999-09-01','9999-12-31',30,'','');
#
#
# PosNr 9
#
WWWRUN	INSERT	Leistungsart	POSNR='9' and GUELT_VON='1999-09-01' and GUELT_BIS='9999-12-31'	insert into Leistungsart (ID,POSNR,LEISTUNGSTYP,KBEZ,EINZELPREIS,BEZEICHNUNG,GUELT_VON,GUELT_BIS,FUERZEIT,ZUSATZGEBUEHREN1,NICHT) values (9999,'9','B','Fehlgeburt',163.61,'F�r den Beistand bei Fehlgeburt oder bei Abnahme einer Mole','1999-09-01','9999-12-31',0,'','');
#
#
# PosNr 10
#
WWWRUN	INSERT	Leistungsart	POSNR='10' and GUELT_VON='1999-09-01' and GUELT_BIS='9999-12-31'	insert into Leistungsart (ID,POSNR,LEISTUNGSTYP,KBEZ,EINZELPREIS,BEZEICHNUNG,GUELT_VON,GUELT_BIS,FUERZEIT,ZUSATZGEBUEHREN1,NICHT) values (9999,'10','B','nicht vollendete Hausgeburt',29.65,'F�r den Beistand bei einer nicht vollendeten Hausgeburt oder einer nicht vollendeten au�erklinischen Geburt in einer von Hebammen oder Entbindungspflegern geleiteten Einrichtung, wenn die Krei�ende vor Beendigung der Geburt oder Fehlgeburt in ein Krankenhaus aufgenommen wird und die Hebamme oder der Entbindungspfleger dort keinen weiteren Beistand leistet, f�r die Dauer bis zu sechs Stunden','1999-09-01','9999-12-31',0,'','');
#
#
# PosNr 11
#
WWWRUN	INSERT	Leistungsart	POSNR='11' and GUELT_VON='1999-09-01' and GUELT_BIS='9999-12-31'	insert into Leistungsart (ID,POSNR,LEISTUNGSTYP,KBEZ,EINZELPREIS,BEZEICHNUNG,GUELT_VON,GUELT_BIS,FUERZEIT,ZUSATZGEBUEHREN1,NICHT) values (9999,'11','B',"nicht vollendete Geburt K'haus",168.73,'F�r den Beistand bei einer nicht vollendeten Geburt in einem Krankenhaus oder in einer au�erklinischen Einrichtung unter �rztlicher Leitung, wenn die Krei�ende in ein anderes Krankenhaus verlegt wird und die Hebamme oder der Entbindungspfleger dort keinen weiteren Beistand leistet, f�r die Dauer bis zu sechs Stunden','1999-09-01','9999-12-31',0,'','');
#
#
# PosNr 12a
#
WWWRUN	INSERT	Leistungsart	POSNR='12a' and GUELT_VON='1999-09-01' and GUELT_BIS='9999-12-31'	insert into Leistungsart (ID,POSNR,LEISTUNGSTYP,KBEZ,EINZELPREIS,BEZEICHNUNG,GUELT_VON,GUELT_BIS,FUERZEIT,ZUSATZGEBUEHREN1,NICHT) values (9999,'12a','B','Zuschlag zu 9,10,11',18.41,'F�r jede weitere angefangene halbe Stunde in den F�llen der Nummern 9, 10 und 11','1999-09-01','9999-12-31',30,'','');
#
#
# PosNr 12b
#
WWWRUN	INSERT	Leistungsart	POSNR='12b' and GUELT_VON='1999-09-01' and GUELT_BIS='9999-12-31'	insert into Leistungsart (ID,POSNR,LEISTUNGSTYP,KBEZ,EINZELPREIS,BEZEICHNUNG,GUELT_VON,GUELT_BIS,FUERZEIT,ZUSATZGEBUEHREN1,NICHT) values (9999,'12b','B','Perinatalerhebung',5.11,'Standardisierte Perinatalerhebung bei einer au�erklinischen Geburt einschlie�lich Versandkosten und Portokosten','1999-09-01','9999-12-31',0,'','');
#
#
#
# Leistungsgruppe C 
# Leistungen nach der Geburt
#
# PosNr 13aa
#
WWWRUN	INSERT	Leistungsart	POSNR='13aa' and GUELT_VON='1999-09-01' and GUELT_BIS='9999-12-31'	insert into Leistungsart (ID,POSNR,LEISTUNGSTYP,KBEZ,EINZELPREIS,BEZEICHNUNG,GUELT_VON,GUELT_BIS,FUERZEIT,ZUSATZGEBUEHREN1,NICHT,EINMALIG,SAMSTAG,SONNTAG,NACHT) values (9999,'13aa','C','Hausbesuch',40.90,'Hausbesuch nach der Geburt','1999-09-01','9999-12-31',0,'','','+13d','','+16b','');
#
#
# PosNr 13ab
#
WWWRUN	INSERT	Leistungsart	POSNR='13ab' and GUELT_VON='1999-09-01' and GUELT_BIS='9999-12-31'	insert into Leistungsart (ID,POSNR,LEISTUNGSTYP,KBEZ,EINZELPREIS,BEZEICHNUNG,GUELT_VON,GUELT_BIS,FUERZEIT,ZUSATZGEBUEHREN1,NICHT,EINMALIG,SAMSTAG,SONNTAG,NACHT) values (9999,'13ab','C',"Besuch im Krankenhaus",16.36,'Besuch im Krankenhaus oder in einer au�erklinischen Einrichtung unter �rztlicher Leitungs, t�glich einmal','1999-09-01','9999-12-31',0,'','','+13d','','+16b','');
#
#
# PosNr 13ac
#
WWWRUN	INSERT	Leistungsart	POSNR='13ac' and GUELT_VON='1999-09-01' and GUELT_BIS='9999-12-31'	insert into Leistungsart (ID,POSNR,LEISTUNGSTYP,KBEZ,EINZELPREIS,BEZEICHNUNG,GUELT_VON,GUELT_BIS,FUERZEIT,ZUSATZGEBUEHREN1,NICHT,EINMALIG,SAMSTAG,SONNTAG,NACHT) values (9999,'13ac','C',"Besuch in Einr.Leitung Heb.",32.72,'Besuch in einer von Hebammen oder Entbindungspflegern geleiteten Einrichtung, t�glich einmal','1999-09-01','9999-12-31',0,'','','+13d','','','+16b');
#
#
# PosNr 13bb
#
WWWRUN	INSERT	Leistungsart	POSNR='13bb' and GUELT_VON='1999-09-01' and GUELT_BIS='9999-12-31'	insert into Leistungsart (ID,POSNR,LEISTUNGSTYP,KBEZ,EINZELPREIS,BEZEICHNUNG,GUELT_VON,GUELT_BIS,FUERZEIT,ZUSATZGEBUEHREN1,NICHT,EINMALIG,SAMSTAG,SONNTAG,NACHT,KILOMETER) values (9999,'13bb','C',"fernm�ndliche Beratung",7.67,'ferndm�ndliche Beratung','1999-09-01','9999-12-31',0,'','','','','','','N');
#
#
# PosNr 13d
#
WWWRUN	INSERT	Leistungsart	POSNR='13d' and GUELT_VON='1999-09-01' and GUELT_BIS='9999-12-31'	insert into Leistungsart (ID,POSNR,LEISTUNGSTYP,KBEZ,EINZELPREIS,BEZEICHNUNG,GUELT_VON,GUELT_BIS,FUERZEIT,ZUSATZGEBUEHREN1,NICHT,EINMALIG,SAMSTAG,SONNTAG,NACHT,KILOMETER) values (9999,'13d','C',"Zuschlag 1. Besuch",9.20,'Zuschlag erster Besuch','1999-09-01','9999-12-31',0,'','','','','','','N');
#
#
# PosNr 14
#
WWWRUN	INSERT	Leistungsart	POSNR='14' and GUELT_VON='1999-09-01' and GUELT_BIS='9999-12-31'	insert into Leistungsart (ID,POSNR,LEISTUNGSTYP,KBEZ,EINZELPREIS,BEZEICHNUNG,GUELT_VON,GUELT_BIS,FUERZEIT,ZUSATZGEBUEHREN1,NICHT,EINMALIG,SAMSTAG,SONNTAG,NACHT,KILOMETER) values (9999,'14','C',"Zuschlag Zwillinge",14.32,'Zuschlag Zwillinge','1999-09-01','9999-12-31',0,'','','','','','','N');
#
#
# PosNr 15
#
WWWRUN	INSERT	Leistungsart	POSNR='15' and GUELT_VON='1999-09-01' and GUELT_BIS='9999-12-31'	insert into Leistungsart (ID,POSNR,LEISTUNGSTYP,KBEZ,EINZELPREIS,BEZEICHNUNG,GUELT_VON,GUELT_BIS,FUERZEIT,ZUSATZGEBUEHREN1,NICHT,EINMALIG,SAMSTAG,SONNTAG,NACHT) values (9999,'15','C',"�berwachung",30.68,'�berwachung, je angefange halbe Stunde','1999-09-01','9999-12-31',30,'','','','','+16b','+16b');
#
#
# PosNr 16a
#
WWWRUN	INSERT	Leistungsart	POSNR='16a' and GUELT_VON='1999-09-01' and GUELT_BIS='9999-12-31'	insert into Leistungsart (ID,POSNR,LEISTUNGSTYP,KBEZ,EINZELPREIS,PROZENT,BEZEICHNUNG,GUELT_VON,GUELT_BIS,FUERZEIT,ZUSATZGEBUEHREN1,NICHT,EINMALIG,SAMSTAG,SONNTAG,NACHT) values (9999,'16a','A',"Zuschlag zu 1",0,0.30,'Die Geb�hren nach den Nummern 1 erh�ht sich um 30 vom Hundert bei Leistungen an Sonntagen und Feiertagen; gleiches gilt f�r die Geb�hren nach Nummer 1 bei Leistungen w�hrend der Nacht','1999-09-01','9999-12-31',0,'','','','','','');
#
#
# PosNr 16b
#
WWWRUN	INSERT	Leistungsart	POSNR='16b' and GUELT_VON='1999-09-01' and GUELT_BIS='9999-12-31'	insert into Leistungsart (ID,POSNR,LEISTUNGSTYP,KBEZ,EINZELPREIS,PROZENT,BEZEICHNUNG,GUELT_VON,GUELT_BIS,FUERZEIT,ZUSATZGEBUEHREN1,NICHT,EINMALIG,SAMSTAG,SONNTAG,NACHT) values (9999,'16b','C',"Zuschlag zu 13, 15",0,0.30,'Die Geb�hren nach den Nummern 13 sowie 15 erh�hen sich um 30 vom Hundert bei Leistungen an Sonntagen und Feiertagen; gleiches gilt f�r die Geb�hren nach Nummer 15 bei Leistungen w�hrend der Nacht','1999-09-01','9999-12-31',0,'','','','','','');
#
#
# PosNr 17
#
WWWRUN	INSERT	Leistungsart	POSNR='17' and GUELT_VON='1999-09-01' and GUELT_BIS='9999-12-31'	insert into Leistungsart (ID,POSNR,LEISTUNGSTYP,KBEZ,EINZELPREIS,BEZEICHNUNG,GUELT_VON,GUELT_BIS,FUERZEIT,ZUSATZGEBUEHREN1,NICHT,EINMALIG,SAMSTAG,SONNTAG,NACHT) values (9999,'17','C',"R�ckbildungsgymnastik",8.18,'R�ckbildungsgymnastik bei Unterweisung in der Gruppe, bis zu zehn Wochnerinnen je Gruppe und h�chstens zehn Stunden, f�r jede W�chnerin je Unterrichtsstunde (60 Minuten)','1999-09-01','9999-12-31','E60','','','','','','');
#
#
# PosNr 18
#
WWWRUN	INSERT	Leistungsart	POSNR='18' and GUELT_VON='1999-09-01' and GUELT_BIS='9999-12-31'	insert into Leistungsart (ID,POSNR,LEISTUNGSTYP,KBEZ,EINZELPREIS,BEZEICHNUNG,GUELT_VON,GUELT_BIS,FUERZEIT,ZUSATZGEBUEHREN1,NICHT,EINMALIG,SAMSTAG,SONNTAG,NACHT) values (9999,'18','C',"Neugeborenen-Erstuntersuchung",13.29,'Neugeborenen-Erstuntersuchung','1999-09-01','9999-12-31',0,'','','','','','');
#
#
# PosNr 19
#
WWWRUN	INSERT	Leistungsart	POSNR='19' and GUELT_VON='1999-09-01' and GUELT_BIS='9999-12-31'	insert into Leistungsart (ID,POSNR,LEISTUNGSTYP,KBEZ,EINZELPREIS,BEZEICHNUNG,GUELT_VON,GUELT_BIS,FUERZEIT,ZUSATZGEBUEHREN1,NICHT,EINMALIG,SAMSTAG,SONNTAG,NACHT) values (9999,'19','C',"Entnahme K�rpermaterial",9.71,'F�r die Entnahme von K�rpermaterial beim Kind zur Durchf�hrung notwendiger Laboruntersuchungen, Versandkosten und Portokosten sowie Dokumentation','1999-09-01','9999-12-31',0,'','','','','','');
#
#
# PosNr 20a
#
WWWRUN	INSERT	Leistungsart	POSNR='20a' and GUELT_VON='1999-09-01' and GUELT_BIS='9999-12-31'	insert into Leistungsart (ID,POSNR,LEISTUNGSTYP,KBEZ,EINZELPREIS,BEZEICHNUNG,GUELT_VON,GUELT_BIS,FUERZEIT,ZUSATZGEBUEHREN1,NICHT,EINMALIG,SAMSTAG,SONNTAG,NACHT) values (9999,'20a','C',"Beratung bei Stillschwierigkeiten",40.90,'Beratung der Mutter bei Stillschwierigkeiten','1999-09-01','9999-12-31',0,'','','','','','');
#
#
# PosNr 20b
#
WWWRUN	INSERT	Leistungsart	POSNR='20b' and GUELT_VON='1999-09-01' and GUELT_BIS='9999-12-31'	insert into Leistungsart (ID,POSNR,LEISTUNGSTYP,KBEZ,EINZELPREIS,BEZEICHNUNG,GUELT_VON,GUELT_BIS,FUERZEIT,ZUSATZGEBUEHREN1,NICHT,EINMALIG,SAMSTAG,SONNTAG,NACHT) values (9999,'20b','C',"fernm�dliche Beratung bei Stillschw.",7.67,'Fernm�ndliche Beratung der Mutter bei Stillschwierigkeiten','1999-09-01','9999-12-31',0,'','','','','','');
#
#
# PosNr 21
#
WWWRUN	INSERT	Leistungsart	POSNR='21' and GUELT_VON='1999-09-01' and GUELT_BIS='9999-12-31'	insert into Leistungsart (ID,POSNR,LEISTUNGSTYP,KBEZ,EINZELPREIS,BEZEICHNUNG,GUELT_VON,GUELT_BIS,FUERZEIT,ZUSATZGEBUEHREN1,NICHT,EINMALIG,SAMSTAG,SONNTAG,NACHT) values (9999,'21','C',"eine Bescheinigung",4.09,'F�r eine Bescheinigung neben der Geb�hr f�r die Untersuchung oder f�r den Besuch','1999-09-01','9999-12-31',0,'','','','','','');
#
#
# PosNr 22
#
WWWRUN	INSERT	Leistungsart	POSNR='22' and GUELT_VON='1999-09-01' and GUELT_BIS='9999-12-31'	insert into Leistungsart (ID,POSNR,LEISTUNGSTYP,KBEZ,EINZELPREIS,BEZEICHNUNG,GUELT_VON,GUELT_BIS,FUERZEIT,ZUSATZGEBUEHREN1,NICHT,EINMALIG,SAMSTAG,SONNTAG,NACHT) values (9999,'22','C',"Anmeldung Standesamt",6.14,'Anmeldung der Geburt beim Standesamt','1999-09-01','9999-12-31',0,'','','','','','');
#
#
#
#
#
# Leistungsgruppe W, gibts nicht in Baden-W�rttemberg
# in tinyHeb schon
#
# PosNr BW300 Wegegeld nicht mehr als 2 KM Tag
#
WWWRUN	INSERT	Leistungsart	POSNR='BW300' and GUELT_VON='1999-09-01' and GUELT_BIS='9999-12-31'	insert into Leistungsart (ID,POSNR,LEISTUNGSTYP,KBEZ,EINZELPREIS,BEZEICHNUNG,GUELT_VON,GUELT_BIS,FUERZEIT) values (9999,'BW300','W','Wegegeld nicht mehr als 2 KM bei Tag',1.53,'Wegegeld bei einer Entfernung von nicht mehr als zwei Kilometern zwischen der Wohnung oder Praxis der Hebamme und der Stelle der Leistung','1999-09-01','9999-12-31',0);
#
# PosNr BW301 anteiliges Wegegeld nicht mehr als 2 KM Tag
#
WWWRUN	INSERT	Leistungsart	POSNR='BW301' and GUELT_VON='1999-09-01' and GUELT_BIS='9999-12-31'	insert into Leistungsart (ID,POSNR,LEISTUNGSTYP,KBEZ,EINZELPREIS,BEZEICHNUNG,GUELT_VON,GUELT_BIS,FUERZEIT) values (9999,'BW301','W','ant. Wegegeld nicht mehr als 2 KM bei Tag',1.53,'anteiliges Wegegeld bei einer Entfernung von nicht mehr als zwei Kilometern zwischen der Wohnung oder Praxis der Hebamme und der Stelle der Leistung','1999-09-01','9999-12-31',0);
#
# PosNr BW310 Wegegeld nicht mehr als 2 KM Nacht
#
WWWRUN	INSERT	Leistungsart	POSNR='BW310' and GUELT_VON='1999-09-01' and GUELT_BIS='9999-12-31'	insert into Leistungsart (ID,POSNR,LEISTUNGSTYP,KBEZ,EINZELPREIS,BEZEICHNUNG,GUELT_VON,GUELT_BIS,FUERZEIT) values (9999,'BW310','W','Wegegeld nicht mehr als 2 KM bei Nacht',2.30,'Wegegeld bei einer Entfernung von nicht mehr als zwei Kilometern zwischen der Wohnung oder Praxis der Hebamme und der Stelle der Leistung in der Zeit von 20:00 bis 8:00','1999-09-01','9999-12-31',0);
#
# PosNr BW311 anteiliges Wegegeld nicht mehr als 2 KM Nacht
#
WWWRUN	INSERT	Leistungsart	POSNR='BW311' and GUELT_VON='1999-09-01' and GUELT_BIS='9999-12-31'	insert into Leistungsart (ID,POSNR,LEISTUNGSTYP,KBEZ,EINZELPREIS,BEZEICHNUNG,GUELT_VON,GUELT_BIS,FUERZEIT) values (9999,'BW311','W','ant. Wegegeld nicht mehr als 2 KM bei Nacht',2.30,'anteiliges Wegegeld bei einer Entfernung von nicht mehr als zwei Kilometern zwischen der Wohnung oder Praxis der Hebamme und der Stelle der Leistung in der Zeit von 20:00 bis 8:00','1999-09-01','9999-12-31',0);
#
# PosNr BW320 Wegegeld mehr als 2 KM Tag
#
WWWRUN	INSERT	Leistungsart	POSNR='BW320' and GUELT_VON='1999-09-01' and GUELT_BIS='9999-12-31'	insert into Leistungsart (ID,POSNR,LEISTUNGSTYP,KBEZ,EINZELPREIS,BEZEICHNUNG,GUELT_VON,GUELT_BIS,FUERZEIT) values (9999,'BW320','W','Wegegeld von mehr als 2 KM bei Tag',0.56,'Wegegeld bei einer Entfernung von mehr als zwei Kilometern zwischen der Wohnung oder Praxis der Hebamme und der Stelle der Leistung, f�r jeden zur�ckgelegten Kilometer','1999-09-01','9999-12-31',0);
#
# PosNr BW321 anteiliges Wegegeld mehr als 2 KM Tag
#
WWWRUN	INSERT	Leistungsart	POSNR='BW321' and GUELT_VON='1999-09-01' and GUELT_BIS='9999-12-31'	insert into Leistungsart (ID,POSNR,LEISTUNGSTYP,KBEZ,EINZELPREIS,BEZEICHNUNG,GUELT_VON,GUELT_BIS,FUERZEIT) values (9999,'BW321','W','ant. Wegegeld von mehr als 2 KM bei Tag',0.56,'anteiliges Wegegeld bei einer Entfernung von mehr als zwei Kilometern zwischen der Wohnung oder Praxis der Hebamme und der Stelle der Leistung, f�r jeden zur�ckgelegten Kilometer','1999-09-01','9999-12-31',0);
#
# PosNr BW330 Wegegeld mehr als 2 KM Nacht
#
WWWRUN	INSERT	Leistungsart	POSNR='BW330' and GUELT_VON='1999-09-01' and GUELT_BIS='9999-12-31'	insert into Leistungsart (ID,POSNR,LEISTUNGSTYP,KBEZ,EINZELPREIS,BEZEICHNUNG,GUELT_VON,GUELT_BIS,FUERZEIT) values (9999,'BW330','W','Wegegeld von mehr als 2 KM bei Nacht',0.56,'Wegegeld bei einer Entfernung von mehr als zwei Kilometern zwischen der Wohnung oder Praxis der Hebamme und der Stelle der Leistung in der Zeit von 20:00 bis 8:00, f�r jeden zur�ckgelegten Kilometer','1999-09-01','9999-12-31',0);
#
#
# PosNr 331 anteiliges Wegegeld mehr als 2 KM Nacht
#
WWWRUN	INSERT	Leistungsart	POSNR='BW331' and GUELT_VON='1999-09-01' and GUELT_BIS='9999-12-31'	insert into Leistungsart (ID,POSNR,LEISTUNGSTYP,KBEZ,EINZELPREIS,BEZEICHNUNG,GUELT_VON,GUELT_BIS,FUERZEIT) values (9999,'BW331','W','ant. Wegegeld von mehr als 2 KM bei Nacht',0.56,'anteiliges Wegegeld bei einer Entfernung von mehr als zwei Kilometern zwischen der Wohnung oder Praxis der Hebamme und der Stelle der Leistung in der Zeit von 20:00 bis 8:00, f�r jeden zur�ckgelegten Kilometer','1999-09-01','9999-12-31',0);
