%macro UPD_mdho06(yyyy,Ucc,Uccs,flag,notBDB);
/*Housing cost burden -  total population */
*** changed age format 5 November 2010 ***;

/*20120229BB correction of a bug from 20120203BB changes calculation before 2008 were not possible*/
/*20120203BB take into account variables removed from 2011 operation (HH080 HH090)*/ 
/*20120601MG changed ISCED code */
*version of 25/10/2011;
 /*20141106MG to check if working datasets IDB is empty */


PROC DATASETS lib=work kill nolist;
QUIT;

%let cc=%lowcase(&Ucc);
%let yy=%substr(&yyyy,3,2);
%let DB100Missing=0;
%let EU=0;
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
		other = "OTHER"
		;

VALUE f_QUINTILE (multilabel)
		1 = "QUINTILE1"
		2 = "QUINTILE2"
		3 = "QUINTILE3"
		4 = "QUINTILE4"
		5 = "QUINTILE5"
		1 - 5 = "TOTAL"
		;
RUN;

*calculate SEVERE_HH_DEP (severe housing deprivation);
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

PROC SQL;
 CREATE TABLE work.idb AS SELECT DISTINCT IDB.DB010,IDB.DB020, IDB.DB030, IDB.RB030, IDB.RB050a, IDB.AGE,
	 IDB.RB090, IDB.ARPT60i, IDB.HT1, IDB.TENSTA_2,  IDB.OVERCROWDED,


         %if &DB100Missing=0 %then  %do ;
			  BDBd.DB100, 
		  %end;

	 BDBh.HH040,
	 (CASE WHEN BDBh.HH040=1 THEN 1 WHEN BDBh.HH040=2 THEN 0 ELSE BDBh.HH040 END) AS LEAKING_ROOF,
	
	%if &yyyy<2008 %then %do;
		BDBh.HH080,
		BDBh.HH080_F,
		BDBh.HH090,
		BDBh.HH090_F,
		(CASE WHEN BDBh.HH080= 2 THEN 1 WHEN BDBh.HH080= 1 THEN 0 ELSE BDBh.HH080 END) AS LACK_BATH_SHOWER,
		(CASE WHEN BDBh.HH090= 2 THEN 1 WHEN BDBh.HH090= 1 THEN 0 ELSE BDBh.HH090 END) AS LACK_TOILET,
	%end;
	%if &yyyy>2007 and &yyyy<2011 %THEN %DO;
		BDBh.HH081,
		BDBh.HH081_F,
		(CASE WHEN (BDBh.HH081_F=1 AND BDBh.HH081= 3) THEN 1 WHEN (BDBh.HH081_F=-5 AND BDBh.HH080= 2) THEN 1 
			WHEN (BDBh.HH081_F=1 AND BDBh.HH081 in (1,2)) THEN 0 WHEN (BDBh.HH081_F=-5 AND BDBh.HH080=1) THEN 0 
		ELSE . END) AS LACK_BATH_SHOWER,
	 	BDBh.HH091,
	 	BDBh.HH091_F,
	 	(CASE WHEN (BDBh.HH091_F=1 AND BDBh.HH091= 3) THEN 1 WHEN (BDBh.HH091_F=-5 AND BDBh.HH090= 2) THEN 1 
			WHEN (BDBh.HH091_F=1 AND BDBh.HH091 in (1,2)) THEN 0 WHEN (BDBh.HH091_F=-5 AND BDBh.HH090=1) THEN 0 
		ELSE . END) AS LACK_TOILET,
	 %END;
	 %if &yyyy>2010 %then %do;
		BDBh.HH081,
		BDBh.HH081_F,
		(CASE WHEN BDBh.HH081= 3 THEN 1 
			WHEN BDBh.HH081 in (1,2) THEN 0
		ELSE . END) AS LACK_BATH_SHOWER,
	 	BDBh.HH091,
	 	BDBh.HH091_F,
	 	(CASE WHEN BDBh.HH091= 3 THEN 1 
			WHEN BDBh.HH091 in (1,2) THEN 0 
		ELSE . END) AS LACK_TOILET,
	 %END;

	(CASE  WHEN CALCULATED LACK_BATH_SHOWER =1 AND CALCULATED LACK_TOILET = 1 THEN 1
		  WHEN (CALCULATED LACK_BATH_SHOWER is missing OR CALCULATED LACK_TOILET is missing ) THEN . ELSE 0 END ) AS LACK_BST,

	BDBh.HS160,
	BDBh.HS160_F,
	 (CASE WHEN BDBh.HS160=1 THEN 1 WHEN BDBh.HS160=2 THEN 0 ELSE . END) AS TOO_DARK,

	 (CASE  WHEN IDB.OVERCROWDED =1 AND(CALCULATED LEAKING_ROOF = 1 OR CALCULATED LACK_BST = 1 OR CALCULATED TOO_DARK = 1)THEN 1
			WHEN (IDB.OVERCROWDED is missing /*OR CALCULATED LEAKING_ROOF is missing OR CALCULATED LACK_BST is missing OR CALCULATED TOO_DARK is missing*/) THEN . 
			ELSE 0 END ) AS SEVERE_HH_DEP
 
 FROM IDB.IDB&yy AS IDB
	left join in.&infil.d as BDBd on (IDB.DB020 = BDBd.DB020 and IDB.DB030 = BDBd.DB030)
	left join in.&infil.h as BDBh on (IDB.DB020 = BDBh.HB020 and IDB.DB030 = BDBh.HB030)



		%if &DB100Missing=0 %then %do;
		where BDBd.DB100 in(1,2,3) AND IDB.DB020 in &Uccs;
		%end;
		%else  %do;
		where  IDB.DB020 in &Uccs;
		%end;



QUIT;


* calculate % missing values;
PROC SQL noprint;
CREATE TABLE nfilled AS SELECT DISTINCT DB020, (N(RB030)) AS N1 FROM work.idb WHERE SEVERE_HH_DEP not is missing GROUP BY DB020;
CREATE TABLE nmissing AS SELECT DISTINCT DB020, (N(RB030)) AS N_1 FROM work.idb WHERE SEVERE_HH_DEP is missing GROUP BY DB020;
CREATE TABLE mSEVERE_HH_DEP AS SELECT nfilled.DB020, (100/(N1+N_1)*N_1) AS mSEVERE_HH_DEP FROM nfilled LEFT JOIN nmissing ON (nfilled.DB020 = nmissing.DB020);

CREATE TABLE missunrel AS SELECT mSEVERE_HH_DEP.DB020, 
				max(mSEVERE_HH_DEP,0) AS pcmiss
	FROM mSEVERE_HH_DEP;
QUIT;


* Severe housing deprivation rate by age, gender and poverty status 
* calc values, N and total weights;

%let tab=mdho06a;

PROC TABULATE data=work.idb out=Ti;
		FORMAT AGE f_agex15.;
		FORMAT RB090 f_sex.;
		FORMAT ARPT60i  f_incgrp15.;
		CLASS DB010;
		CLASS DB020;
		CLASS SEVERE_HH_DEP;
		CLASS AGE /MLF;
		CLASS RB090 /MLF;
		CLASS ARPT60i /MLF;
		
	VAR RB050a;
	TABLE DB010 * DB020 * AGE * RB090 * ARPT60i, SEVERE_HH_DEP * RB050a * (RowPctSum N Sum) /printmiss;
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
	ti.SEVERE_HH_DEP,
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
	AND  (Ti.Age = old_flag.Age) AND (Ti.RB090  = old_flag.sex) 
	AND (Ti.ARPT60i  = old_flag.incgrp) 
GROUP BY Ti.DB020, ti.AGE, ti.RB090, Ti.ARPT60i;
	QUIT;




* Update RDB;
DATA  rdb.&tab(drop=SEVERE_HH_DEP);
set rdb.&tab (where=(not(time = &yyyy and geo in &Uccs)))
    work.&tab(where=(SEVERE_HH_DEP = 1)); 
RUN;
%put +UPDATED &tab;


*: Severe housing deprivation rate by household type 
* calc values, N and total weights;


%let tab=mdho06b;

PROC TABULATE data=work.idb out=Ti;
		FORMAT HT1 f_HHTYP.;
		CLASS SEVERE_HH_DEP;
		CLASS HT1 /MLF;	
		CLASS DB020;
		CLASS DB010;
	VAR RB050a;
	TABLE DB010 * DB020 * HT1, SEVERE_HH_DEP * RB050a * (RowPctSum N Sum) /printmiss;
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
	ti.SEVERE_HH_DEP,
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
DATA  rdb.&tab(drop=SEVERE_HH_DEP);
set rdb.&tab(where=(not(time = &yyyy and geo in &Uccs)))
    work.&tab(where=(SEVERE_HH_DEP = 1 and HHTYP not in  ("TOTAL", "OTHER" ))); 
RUN;
%put +UPDATED &tab;


* Severe housing deprivation rate by new tenure status 
* calc values, N and total weights;

%let tab=mdho06c;

PROC TABULATE data=work.idb out=Ti;
		FORMAT TENSTA_2  f_tenstatu.;
		CLASS SEVERE_HH_DEP;
		CLASS TENSTA_2 /MLF;	
	CLASS DB020;
	CLASS DB010;
	VAR RB050a;
	TABLE DB010 * DB020 * TENSTA_2, SEVERE_HH_DEP * RB050a * (RowPctSum N Sum) /printmiss;
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
	ti.SEVERE_HH_DEP,
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
DATA  rdb.&tab(drop=SEVERE_HH_DEP);
set rdb.&tab(where=(not(time = &yyyy and geo in &Uccs)))
    work.&tab(where=(SEVERE_HH_DEP = 1 and TENURE ne "TOTAL")); 
RUN;
%put +UPDATED &tab;


* Severe housing deprivation rate by degree of urbanisation 
* calc values, N and total weights;

%let tab=mdho06d;
%put marina;
%put &DB100Missing;
%if &DB100Missing=0	 %then %do; /* 20141106MG  NO DB100 missing  */
PROC TABULATE data=work.idb out=Ti;
		FORMAT DB100  f_DEG_URB.;
		CLASS SEVERE_HH_DEP;
		CLASS DB100 /MLF;	
	CLASS DB020;
	CLASS DB010;
	VAR RB050a;
	TABLE DB010 * DB020 * DB100, SEVERE_HH_DEP * RB050a * (RowPctSum N Sum) /printmiss;
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
	ti.SEVERE_HH_DEP,
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
DATA  rdb.&tab(drop=SEVERE_HH_DEP);
set rdb.&tab(where=(not(time = &yyyy and geo in &Uccs)))
    work.&tab(where=(SEVERE_HH_DEP = 1 and DEG_URB ne "TOTAL")); 
RUN;
%put +UPDATED &tab;

%end;
%end;

%if &EU %then %do;

* EU aggregates;

%let tab=mdho06a;
%let grpdim=age, sex, incgrp, unit;
%EUVALS(&Ucc,&Uccs);

%let tab=mdho06b;
%let grpdim=HHTYP, unit;
%EUVALS(&Ucc,&Uccs);

%let tab=mdho06c;
%let grpdim=TENURE, unit;
%EUVALS(&Ucc,&Uccs);

%let tab=mdho06d;
%let grpdim=DEG_URB, unit;
%EUVALS(&Ucc,&Uccs);

%end;

PROC SQL;  
     Insert into log.log
     set date = "&sysdate"d, time = "&systime"t, user = "&sysuserid",
		 report = "* &Ucc - &yyyy * mdho06a (re)calculated *";		  
QUIT;
PROC SQL;  
     Insert into log.log
     set date = "&sysdate"d, time = "&systime"t, user = "&sysuserid",
		 report = "* &Ucc - &yyyy * mdho06b (re)calculated *";		  
QUIT;
PROC SQL;  
     Insert into log.log
     set date = "&sysdate"d, time = "&systime"t, user = "&sysuserid",
		 report = "* &Ucc - &yyyy * mdho06c (re)calculated *";		  
QUIT;
PROC SQL;  
     Insert into log.log
     set date = "&sysdate"d, time = "&systime"t, user = "&sysuserid",
		 report = "* &Ucc - &yyyy * mdho06d (re)calculated *";		  
QUIT;
%let not60=0;
%mend UPD_mdho06;
