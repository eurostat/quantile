/*
. LWI by most frequent activity status 
*/
/* 20120111MG applid new ACTSTA definition */
/* version of 16/11/2010*/
%macro UPD_lvhl12(yyyy,Ucc,Uccs,flag,notBDB);

PROC DATASETS lib=work kill nolist;
QUIT;

%let cc=%lowcase(&Ucc);
%let yy=%substr(&yyyy,3,2);
%let EU=0;
%if &Uccs=0 %then %let Uccs=("&Ucc");
%else %let EU=1;

* input datasets;
/*
%if &notBDB %then %do;
	libname in "&eusilc/&cc/c&yy"; 
	%let infil=c&cc&yy;
	%end;
%else %do;
	libname in "&eusilc/BDB"; 
	%let infil=BDB_c&yy;
	%end;
*/
%let not60=0;

%if &EU=0 %then %do;

PROC FORMAT;
VALUE f_age (multilabel)
		
		18 - 59 = "Y18-59"
		18 - 24 = "Y18-24"
		25 - 59 = "Y25-59"
		25 - 54 = "Y25-54"	
		25 - 34 = "Y25-34"
		35 - 44 = "Y35-44"
		45 - 54 = "Y45-54"
		55 - 59 = "Y55-59"
		;

VALUE f_sex (multilabel)
		1 = "M"
		2 = "F"
		1 - 2 = "T";

/*20110627BB split EMP in  SAL and NSAL in ACTSTA*/
   /*20120404BB change format according to new ACTSTA categories*/
   VALUE f_act (multilabel)
		1 - 4 = "EMP" /* 1 filled only up to 2008 included, 2,3,4 filled only from 2009 no overlapping*/
		2 = "SAL"
		3 = "NSAL"  
		5 = "UNE"
		6 = "RET"
		7 = "INAC_OTH"
		5 - 8 = "NEMP"
		1 - 8 = "POP";
RUN;

* extract from IDB;

PROC SQL noprint;
Create table work.idb as 
	select distinct DB010, DB020, RB030, PB040, Age, RB090, LWI, ACTSTA
	from idb.IDB&yy as IDB
	where DB020 in &Uccs and idb.Age > 17 and idb.Age < 60 and LWI ne 2;
QUIT;

* calculate % missing values;

PROC SQL noprint;

CREATE TABLE nfilled AS SELECT DISTINCT DB020, (N(RB030)) AS N1 FROM work.idb WHERE AGE not is missing GROUP BY DB020;
CREATE TABLE nmissing AS SELECT DISTINCT DB020, (N(RB030)) AS N_1 FROM work.idb WHERE AGE is missing GROUP BY DB020;
CREATE TABLE mAGE AS SELECT nfilled.DB020, (100/(N1+N_1)*N_1) AS mAGE FROM nfilled LEFT JOIN nmissing ON (nfilled.DB020 = nmissing.DB020);

CREATE TABLE nfilled AS SELECT DISTINCT DB020, (N(RB030)) AS N1 FROM work.idb WHERE RB090 not is missing GROUP BY DB020;
CREATE TABLE nmissing AS SELECT DISTINCT DB020, (N(RB030)) AS N_1 FROM work.idb WHERE RB090 is missing GROUP BY DB020;
CREATE TABLE mRB090 AS SELECT nfilled.DB020, (100/(N1+N_1)*N_1) AS mRB090 FROM nfilled LEFT JOIN nmissing ON (nfilled.DB020 = nmissing.DB020);

CREATE TABLE nfilled AS SELECT DISTINCT DB020, (N(RB030)) AS N1 FROM work.idb WHERE LWI not is missing GROUP BY DB020;
CREATE TABLE nmissing AS SELECT DISTINCT DB020, (N(RB030)) AS N_1 FROM work.idb WHERE LWI is missing GROUP BY DB020;
CREATE TABLE mLWI AS SELECT nfilled.DB020, (100/(N1+N_1)*N_1) AS mLWI FROM nfilled LEFT JOIN nmissing ON (nfilled.DB020 = nmissing.DB020);

CREATE TABLE nfilled AS SELECT DISTINCT DB020, (N(RB030)) AS N1 FROM work.idb WHERE ACTSTA not is missing GROUP BY DB020;
CREATE TABLE nmissing AS SELECT DISTINCT DB020, (N(RB030)) AS N_1 FROM work.idb WHERE ACTSTA is missing GROUP BY DB020;
CREATE TABLE mACTSTA AS SELECT nfilled.DB020, (100/(N1+N_1)*N_1) AS mACTSTA FROM nfilled LEFT JOIN nmissing ON (nfilled.DB020 = nmissing.DB020);


CREATE TABLE missunrel AS SELECT mAGE.DB020, 
	max(mAGE, mRB090, mLWI, mACTSTA) AS pcmiss
	FROM mAGE LEFT JOIN mRB090 ON (mAGE.DB020 = mRB090.DB020)
				LEFT JOIN mLWI ON (mAGE.DB020 = mLWI.DB020)
				LEFT JOIN mACTSTA ON (mAGE.DB020 = mACTSTA.DB020);
QUIT;

* calc values, N and total weights;

PROC TABULATE data=work.idb out=Ti;

		FORMAT AGE f_age15.;
		FORMAT RB090 f_sex.;
		FORMAT ACTSTA f_act.;
		CLASS AGE /MLF;
		CLASS RB090 /MLF;
		CLASS ACTSTA /MLF;
		CLASS LWI ;
		CLASS DB020;
	VAR PB040;

	TABLE DB020 * AGE * RB090 * ACTSTA, LWI * PB040 * (RowPctSum N Sum) /printmiss;

RUN;



* fill RDB variables;
%macro by_unit(unit,ival); 

PROC SQL;

CREATE TABLE work.old_flag AS
SELECT 
	time,
	geo,
	Age,
	sex,
	wstatus,
	unit,
	iflag
FROM rdb.lvhl12 
WHERE geo in &Uccs and unit= "&unit" and time = &yyyy ;

CREATE TABLE work.lvhl12 AS
SELECT 
	Ti.DB020 as geo FORMAT=$5. LENGTH=5,
	&yyyy as time,
	Ti.Age,
	Ti.RB090 as sex,
	Ti.LWI,
	Ti.ACTSTA as wstatus,
	"&unit" as unit,
	Ti.&ival as ivalue,
	old_flag.iflag as iflag FORMAT=$3. LENGTH=3,
	(case when sum(Ti.PB040_N) < 20 or missunrel.pcmiss > 50 then 2
		  when sum(Ti.PB040_N) < 50 or missunrel.pcmiss > 20 then 1
		  else 0
	      end) as unrel,
	Ti.PB040_N as n,
	sum(Ti.PB040_N) as ntot,
	sum(Ti.PB040_Sum) as totwgh,
	"&sysdate" as lastup,
	"&sysuserid" as	lastuser 
FROM Ti LEFT JOIN missunrel ON (Ti.DB020 = missunrel.DB020)
		LEFT JOIN work.old_flag ON (Ti.DB020 = old_flag.geo) AND (Ti.Age = old_flag.Age)
					AND (Ti.RB090 = old_flag.sex) AND (Ti.ACTSTA = old_flag.wstatus)
GROUP BY Ti.DB020, ti.AGE, ti.RB090, Ti.ACTSTA
ORDER BY Ti.DB020, ti.AGE, ti.RB090, Ti.ACTSTA;
QUIT;

* Update RDB;
DATA  rdb.lvhl12 (drop= LWI);
set rdb.lvhl12(where=(not(time = &yyyy and geo = "&Ucc" and unit = "&unit")))
    work.lvhl12;
	where LWI=1;
RUN;
%mend by_unit;

	%by_unit(PC_Y18-59,PB040_PctSum_11101);
	/*%by_unit(THS_PER,PB040_Sum/1000);*/


%end;

%if &EU %then %do;

* EU aggregates;

%let tab=lvhl12;
%let grpdim=age, sex, wstatus, unit;
%EUVALS(&Ucc,&Uccs);

%end;

PROC SQL;  
     Insert into log.log
     set date = "&sysdate"d, time = "&systime"t, user = "&sysuserid",
		 report = "* &Ucc - &yyyy * lvhl12 (re)calculated *";		  
QUIT;

%mend UPD_lvhl12;
