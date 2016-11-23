%macro UPD_lvho05_06(yyyy,Ucc,Uccs,flag,notBDB);
/*Overcrowding rate -  total population BY age AND at risk of poverty*/
*** changed age format 5 November 2010 ***;
/*20120601MG changed Tesntatu  code and rename it in TENURE */
/*20141106MG to check if working datasets IDB is empty */
/*201412100MG to check if DB100 varible is missing */
PROC DATASETS lib=work kill nolist;
QUIT;

%let cc=%lowcase(&Ucc);
%let yy=%substr(&yyyy,3,2);
%let EU=0;

/* to check if the  result is fine */
%let c_obsa=0;
%let c_obsb=0;
%let c_obsc=0;
%let c_obsd=0;
%let c_obs06=0;
%let nobs=0;
%let DB100Missing=0;

%if &Uccs=0 %then %let Uccs=("&Ucc");
%else %let EU=1;


%let not60=0;

%if &EU=0 %then %do;


PROC FORMAT;
VALUE f_age (multilabel)
		0 - 17 = "Y_LT18"
		18 - 64 = "Y18-64"
		65 - HIGH = "Y_GE65"
		0 - HIGH = "TOTAL"
		other = .;
		
		VALUE f_agex (multilabel)
		0 - 5 = "Y_LT6"
	 	6 - 11 = "Y6-11"
		12 - 17 = "Y12-17"	
		0 - 17 = "Y_LT18"
		18 - 64 = "Y18-64"
		65 - HIGH = "Y_GE65"
		0 - HIGH = "TOTAL"
		other = .;
		
VALUE f_sex (multilabel)
		1 = "M"
		2 = "F"
		1 - 2 = "T"
		;

VALUE f_incgrp (multilabel)
		0,1 = "TOTAL"
		0 = "A_MD60"
		1 = "B_MD60"
		;

VALUE f_tenstatu (multilabel)
		1 = "OWN_NL"
		2 = "OWN_L"
		3 = "RENT_MKT"
		4 = "RENT_FR"
		1 - 4 = "TOTAL"
		;

VALUE f_DEG_URB (multilabel)
		1 = "DEG1"
		2 = "DEG2"
		3 = "DEG3"
		1 - 3 = "TOTAL"
		;

VALUE f_HHTYP (multilabel)
		1 - 8 = "HH_NDCH"
		1-4 =	 "A1" 
		1,2 = "A1_LT65"
		3,4 = "A1_GE65"
		1,3 = "A1M"
		2,4 = "A1F"
		6,7 = "A2"
		6 =	 "A2_2LT65"
		7 =	 "A2_GE1_GE65"
		8 =	 "A_GE3"
		6 - 8 = "A_GE2_NDCH"
		9 - 13 = "HH_DCH"
		9 =	 "A1_DCH"
		10 = "A2_1DCH"
		11 = "A2_2DCH"
		12 = "A2_GE3DCH"
		13 = "A_GE3_DCH"
		10 - 13 = "A_GE2_DCH"
		1 - 13 = "TOTAL"
		;

RUN;
/*20141210MG  to check if  DB100 variable  is in D-PDB file:   */

data FDB100;set in.&infil.d;where DB020 in &Uccs;run;   /*20141106MG to check if working datasets IDB is empty */

Proc sql;                                   
Select distinct count(DB010) as N 
	into :nobs
	from  FDB100;
quit;

PROC MEANS DATA=FDB100 	NWAY 	N  	NMISS	;
	VAR DB100;
	CLASS DB020 ;
OUTPUT 	OUT=WORK.NUMMIS
		N()= 
		NMISS()=
	 / AUTONAME AUTOLABEL  WAYS INHERIT
	;
RUN;
Proc sql;                                                
Select distinct DB100_NMiss  as Nn  
	into :NM
	from  work.NUMMIS ;
quit;

%if &nobs=&Nm %then %let DB100Missing=1;



/* End step to check if  DB100 variable is in D-PDB file*/

%macro without_single (tabname);
%let not60=0;/* allows calculation of aggregates if less than 70% of pop*/
PROC SQL noprint;
Create table work.idb as 
	select distinct IDB.DB010, IDB.DB020, IDB.DB030, 
	     %if &DB100Missing=0 %then  %do ;
			  BDBd.DB100, 
		  %end;
	 IDB.RB030, IDB.RB050a, IDB.Age,
       IDB.RB090, IDB.ARPT60i,IDB.OVERCROWDED, IDB.TENSTA_2, IDB.HT1
	from idb.IDB&yy as IDB
	left join in.&infil.d as BDBd on (IDB.DB020 = BDBd.DB020 and IDB.DB030 = BDBd.DB030)
		
		%if &DB100Missing=0 %then %do;
		where BDBd.DB100 in(1,2,3) AND IDB.DB020 in &Uccs;
		%end;
		%else  %do;
		where  IDB.DB020 in &Uccs;
		%end;




* calculate % missing values;
PROC SQL noprint;
CREATE TABLE nfilled AS SELECT DISTINCT DB020, (N(RB030)) AS N1 FROM work.idb WHERE OVERCROWDED not is missing GROUP BY DB020;
CREATE TABLE nmissing AS SELECT DISTINCT DB020, (N(RB030)) AS N_1 FROM work.idb WHERE OVERCROWDED is missing GROUP BY DB020;
CREATE TABLE mOVERCROWDED AS SELECT nfilled.DB020, (100/(N1+N_1)*N_1) AS mOVERCROWDED FROM nfilled LEFT JOIN nmissing ON (nfilled.DB020 = nmissing.DB020);

CREATE TABLE missunrel AS SELECT mOVERCROWDED.DB020, 
				max(mOVERCROWDED,0) AS pcmiss
	FROM mOVERCROWDED;
QUIT;

* &tabname.a Overcrowding rate by age gender and income group
* calc values, N and total weights;
%if &tabname=lvho05 %then %do;
%let tab=&tabname.a;

DATA WORK.idb1;
set work.idb;
RUN;

%end;
%else %if &tabname=lvho06 %then %do;
%let tab=&tabname;
%let not60=0; 

DATA WORK.idb1;
set work.idb;
where HT1  not in (1,2,3,4);
RUN;

%end;

PROC TABULATE data=work.idb1 out=Ti;
		FORMAT AGE f_agex15.;
		FORMAT RB090 f_sex.;
		FORMAT ARPT60i  f_incgrp15.;
		CLASS DB010;
		CLASS DB020;
		CLASS OVERCROWDED;
		CLASS AGE /MLF;
		CLASS RB090 /MLF;
		CLASS ARPT60i /MLF;
		
	VAR RB050a;
	TABLE DB010 * DB020 * AGE * RB090 * ARPT60i, OVERCROWDED * RB050a * (RowPctSum N Sum) /printmiss;
RUN;
* fill RDB variables;
PROC SQL;
CREATE TABLE work.old_flag AS
SELECT 
      time,
      geo,
	  age,
	  sex,
	  incgrp,
   	  iflag
FROM rdb.&tab
WHERE  time = &yyyy ;

CREATE TABLE work.&tab AS
SELECT 
	Ti.DB020 as geo FORMAT=$5. LENGTH=5,
	Ti.DB010 as time,
	Ti.Age,
	Ti.RB090 as sex,
	ti.ARPT60i as incgrp,
	"PC_POP" as unit,
	ti.OVERCROWDED,
	Ti.RB050a_PctSum_110111 as ivalue, 
	old_flag.iflag as iflag,
	(case when sum(Ti.RB050a_N) < 20 or missunrel.pcmiss > 50 then 2
		  when sum(Ti.RB050a_N) < 50 or missunrel.pcmiss > 20 then 1
		  else 0
	      end) as unrel,
	Ti.RB050a_N as n,
	sum(Ti.RB050a_N) as ntot,
	sum(Ti.RB050a_Sum) as totwgh,
	"&sysdate" as lastup,
	"&sysuserid" as	lastuser 
FROM Ti LEFT JOIN missunrel ON (Ti.DB020 = missunrel.DB020)
LEFT JOIN work.old_flag ON (Ti.DB020 = old_flag.geo) 
	    AND (Ti.age = old_flag.age) AND (Ti.RB090  = old_flag.sex) 
	    AND (Ti.ARPT60i  = old_flag.incgrp)
GROUP BY Ti.DB020, ti.AGE, ti.RB090, Ti.ARPT60i;

	QUIT;

* Update RDB;
DATA  rdb.&tab(drop=OVERCROWDED);
set rdb.&tab(where=(not(time = &yyyy and geo in &Uccs)))
work.&tab(where=(OVERCROWDED = 1)) ; 
RUN;
%put +UPDATED &tab;


* &tabname.b Overcrowding rate by household type
* calc values, N and total weights;
%let not60=0;
%if &tabname=lvho05 %then %do; /* only calculation for lvho05*/

%let tab=&tabname.b;

DATA  WORK.idb2;
set work.idb;
where HT1  not in (16);
RUN;

PROC TABULATE data=work.idb2 out=Ti;
		FORMAT HT1  f_HHTYP.;
		CLASS OVERCROWDED;
		CLASS HT1 /MLF;	
	CLASS DB020;
	CLASS DB010;
	VAR RB050a;
	TABLE DB010 * DB020 * HT1, OVERCROWDED * RB050a * (RowPctSum N Sum) /printmiss;
RUN;


* fill RDB variables;
PROC SQL;
CREATE TABLE work.old_flag AS
SELECT 
      time,
      geo,
	  HHTYP,
	  iflag
FROM rdb.&tab
WHERE  time = &yyyy ;
CREATE TABLE work.&tab AS
SELECT 
	Ti.DB020 as geo FORMAT=$5. LENGTH=5,
	Ti.DB010 as time,
	Ti.HT1 as HHTYP,
	"PC_POP" as unit,
	ti.OVERCROWDED,
	Ti.RB050a_PctSum_0111 as ivalue,
	old_flag.iflag as iflag,
	(case when sum(Ti.RB050a_N) < 20 or missunrel.pcmiss > 50 then 2
		  when sum(Ti.RB050a_N) < 50 or missunrel.pcmiss > 20 then 1
		  else 0
	      end) as unrel,
	Ti.RB050a_N as n,
	sum(Ti.RB050a_N) as ntot,
	sum(Ti.RB050a_Sum) as totwgh,
	"&sysdate" as lastup,
	"&sysuserid" as	lastuser 
FROM Ti LEFT JOIN missunrel ON (Ti.DB020 = missunrel.DB020)
LEFT JOIN work.old_flag ON (Ti.DB020 = old_flag.geo) 
	 AND (Ti.HT1 = old_flag.hhtyp) 
		
GROUP BY Ti.DB020, Ti.HT1;
	QUIT;

* Update RDB;
DATA  rdb.&tab(drop=OVERCROWDED);
set rdb.&tab(where=(not(time = &yyyy and geo in &Uccs)))
    work.&tab(where=(OVERCROWDED = 1 and HHTYP ne "TOTAL")); 
RUN;
%put +UPDATED &tab;



* &tabname.c Overcrowding rate by tenure status
* calc values, N and total weights;

%let tab=&tabname.c;

PROC TABULATE data=work.idb out=Ti;
		FORMAT TENSTA_2  f_tenstatu.;
		CLASS OVERCROWDED;
		CLASS TENSTA_2 /MLF;	
	CLASS DB020;
	CLASS DB010;
	VAR RB050a;
	TABLE DB010 * DB020 * TENSTA_2, OVERCROWDED * RB050a * (RowPctSum N Sum) /printmiss;
RUN;

* fill RDB variables;
PROC SQL;
CREATE TABLE work.old_flag AS
SELECT 
      time,
      geo,
	  TENURE,
	  iflag
FROM rdb.&tab
WHERE  time = &yyyy ;

CREATE TABLE work.&tab AS
SELECT 
	Ti.DB020 as geo FORMAT=$5. LENGTH=5,
	Ti.DB010 as time,
	Ti.TENSTA_2 as TENURE,
	"PC_POP" as unit,
	ti.OVERCROWDED,
	Ti.RB050a_PctSum_0111 as ivalue,
	old_flag.iflag as iflag,
	(case when sum(Ti.RB050a_N) < 20 or missunrel.pcmiss > 50 then 2
		  when sum(Ti.RB050a_N) < 50 or missunrel.pcmiss > 20 then 1
		  else 0
	      end) as unrel,
	Ti.RB050a_N as n,
	sum(Ti.RB050a_N) as ntot,
	sum(Ti.RB050a_Sum) as totwgh,
	"&sysdate" as lastup,
	"&sysuserid" as	lastuser 
FROM Ti LEFT JOIN missunrel ON (Ti.DB020 = missunrel.DB020)
		LEFT JOIN work.old_flag ON (Ti.DB020 = old_flag.geo) 
	AND (Ti.TENSTA_2  = old_flag.TENURE) 
		
GROUP BY Ti.DB020, Ti.TENSTA_2;
	QUIT;

* Update RDB;
DATA  rdb.&tab(drop=OVERCROWDED);
set rdb.&tab(where=(not(time = &yyyy and geo in &Uccs)))
    work.&tab(where=(OVERCROWDED = 1 and TENURE ne "TOTAL")); 
RUN;
%put +UPDATED &tab;


* &tabname.d Overcrowding rate by degree of urbanisation
* calc values, N and total weights;

%let tab=&tabname.d;

%if &DB100Missing=0	 %then %do; /* 20141106MG  NO DB100 missing  */


PROC TABULATE data=work.idb out=Ti;
		FORMAT DB100  f_DEG_URB.;
		CLASS OVERCROWDED;
		CLASS DB100 /MLF;	
	CLASS DB020;
	CLASS DB010;
	VAR RB050a;
	TABLE DB010 * DB020 * DB100, OVERCROWDED * RB050a * (RowPctSum N Sum) /printmiss;
RUN;

* fill RDB variables;
PROC SQL;
CREATE TABLE work.old_flag AS
SELECT 
      time,
      geo,
	  DEG_URB,
   	  iflag
FROM rdb.&tab
WHERE  time = &yyyy ;

CREATE TABLE work.&tab AS
SELECT 
	Ti.DB020 as geo FORMAT=$5. LENGTH=5,
	Ti.DB010 as time,
	Ti.DB100 as DEG_URB,
	"PC_POP" as unit,
	ti.OVERCROWDED,
	Ti.RB050a_PctSum_0111 as ivalue,
	old_flag.iflag as iflag,
	(case /*when (Ti.DB020 in ('LT','IS') and Ti.DB100='DEG2') then 5 /* never DB100=2 for them value = ":"*/
		  when sum(Ti.RB050a_N) < 20 or missunrel.pcmiss > 50 then 2
		  when sum(Ti.RB050a_N) < 50 or missunrel.pcmiss > 20 then 1
		  else 0
	      end) as unrel,
	Ti.RB050a_N as n,
	sum(Ti.RB050a_N) as ntot,
	sum(Ti.RB050a_Sum) as totwgh,
	"&sysdate" as lastup,
	"&sysuserid" as	lastuser 
FROM Ti LEFT JOIN missunrel ON (Ti.DB020 = missunrel.DB020)
		LEFT JOIN work.old_flag ON (Ti.DB020 = old_flag.geo) 
	AND (Ti.DB100  = old_flag.DEG_URB)  
GROUP BY Ti.DB020, Ti.DB100;
	QUIT;

* Update RDB;
DATA  rdb.&tab(drop=OVERCROWDED);
set rdb.&tab(where=(not(time = &yyyy and geo in &Uccs)))
    work.&tab(where=(OVERCROWDED = 1 and DEG_URB ne "TOTAL")); 
RUN;
%put +UPDATED &tab;
%end;
%end;
%mend without_single;
%without_single(lvho05);
%without_single(lvho06);

%end;

%if &EU %then %do;

* EU aggregates;

%let tab=lvho05a;
%let grpdim=age, sex, incgrp, unit;
%EUVALS(&Ucc,&Uccs);

%let tab=lvho06;
%let grpdim=age, sex, incgrp, unit;
%EUVALS(&Ucc,&Uccs);

%let tab=lvho05b;
%let grpdim=HHTYP, unit;
%EUVALS(&Ucc,&Uccs);

%let tab=lvho05c;
%let grpdim=TENURE, unit;
%EUVALS(&Ucc,&Uccs);

%let tab=lvho05d;
%let grpdim=DEG_URB, unit;
%EUVALS(&Ucc,&Uccs);

%end;

%if &nobs > 0
	%then %do;
	proc sql noprint;
			select count(*) into :c_obsa from lvho05a;
	quit;
 	proc sql noprint;
			select count(*) into :c_obsb from lvho05b;
	quit;
	proc sql noprint;
			select count(*) into :c_obsc from lvho05c;
	quit;
	%if   %sysfunc(exist(lvho05d)) %then %do;
	proc sql noprint;
			select count(*) into :c_obsd from lvho05d;
	quit;
	%end;
	proc sql noprint;
			select count(*) into :c_obs06 from lvho06;
	quit;
%end;
%if &c_obsa > 0 %then %do;
PROC SQL;  
     Insert into log.log
     set date = "&sysdate"d, time = "&systime"t, user = "&sysuserid",
		 report = "* &Ucc - &yyyy * lvho05a  (re)calculated *";
	QUIT;
%end;
%if &c_obsb > 0 %then %do;
	PROC SQL;  
     Insert into log.log
     set date = "&sysdate"d, time = "&systime"t, user = "&sysuserid",
		 report = "* &Ucc - &yyyy * lvho05b  (re)calculated *";
	QUIT;
	%end;
%if &c_obsc > 0 %then %do;
	PROC SQL;  
     Insert into log.log
     set date = "&sysdate"d, time = "&systime"t, user = "&sysuserid",
		 report = "* &Ucc - &yyyy * lvho05c (re)calculated *";
	QUIT;
%end;
%if &c_obsd > 0 %then %do;
	PROC SQL;  
     Insert into log.log
     set date = "&sysdate"d, time = "&systime"t, user = "&sysuserid",
		 report = "* &Ucc - &yyyy * lvho05d (re)calculated *";
	QUIT;
%end;
%if &c_obs06 > 0 %then %do;
PROC SQL;  
     Insert into log.log
     set date = "&sysdate"d, time = "&systime"t, user = "&sysuserid",
		 report = "* &Ucc - &yyyy * lvho06  (re)calculated *";			 
QUIT;
%end;
%let not60=0;
%mend UPD_lvho05_06;
