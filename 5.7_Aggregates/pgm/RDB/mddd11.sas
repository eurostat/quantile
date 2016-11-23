/*
. SEVERE MATERIAL DEPRIVATION by age and gender 
*/
%macro UPD_mddd11(yyyy,Ucc,Uccs,flag,notBDB);
*** child age format added  25 October 2011 - 20111025MG***;
*** new age bracket added 55-64 21 June 2012 - 20120621BG***;

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
		0 - 5 = "Y_LT6"
		6 - 10 = "Y6-10"
		6 - 11 = "Y6-11"
		12 - 17 = "Y12-17"
		0 - 17 ="Y_LT18"
		/* */
		0 - 15 = "Y_LT16"
		11 - 15 = "Y11-15"
		16 - HIGH = "Y_GE16"
		0 - 17 = "Y_LT18"
		18 - HIGH = "Y_GE18"
		16 - 24 = "Y16-24"
		18 - 24 = "Y18-24"
		25 - 49 = "Y25-49"
		25 - 54 = "Y25-54"
		0 - 59 = "Y_LT60"
		60 - HIGH = "Y_GE60"
		0 - 64 = "Y_LT65"
		16 - 64 = "Y16-64"
		18 - 64 = "Y18-64"
		50 - 64 = "Y50-64"
		55 - 64 = "Y55-64"
		55 - HIGH = "Y_GE55"
		65 - HIGH = "Y_GE65"
		65 - 74 = "Y65-74"
		0 - 74 = "Y_LT75"
		75 - HIGH = "Y_GE75"
		0 - HIGH = "TOTAL";

VALUE f_sex (multilabel)
		1 = "M"
		2 = "F"
		1 - 2 = "T";


RUN;

* extract from IDB;

PROC SQL noprint;
Create table work.idb as 
	select distinct DB010, DB020, RB030, RB050a, Age, RB090, SEV_DEP, DEP_RELIABILITY
	from idb.IDB&yy as IDB
	where DB020 in &Uccs;
QUIT;

* calculate % missing values;
PROC SQL noprint;

CREATE TABLE nfilled AS SELECT DISTINCT DB020, (N(RB030)) AS N1 FROM work.idb WHERE RB090 not is missing GROUP BY DB020;
CREATE TABLE nmissing AS SELECT DISTINCT DB020, (N(RB030)) AS N_1 FROM work.idb WHERE RB090 is missing GROUP BY DB020;
CREATE TABLE mRB090 AS SELECT nfilled.DB020, (100/(N1+N_1)*N_1) AS mRB090 FROM nfilled LEFT JOIN nmissing ON (nfilled.DB020 = nmissing.DB020);

CREATE TABLE nfilled AS SELECT DISTINCT DB020, (N(RB030)) AS N1 FROM work.idb WHERE AGE not is missing GROUP BY DB020;
CREATE TABLE nmissing AS SELECT DISTINCT DB020, (N(RB030)) AS N_1 FROM work.idb WHERE AGE is missing GROUP BY DB020;
CREATE TABLE mAGE AS SELECT nfilled.DB020, (100/(N1+N_1)*N_1) AS mAGE FROM nfilled LEFT JOIN nmissing ON (nfilled.DB020 = nmissing.DB020);

create table work.mSEV_DEP as
 select distinct DB020,
(DEP_RELIABILITY*30) as mSEV_DEP
 from work.IDB;

CREATE TABLE missunrel AS SELECT mRB090.DB020, 
	max(mRB090, mAGE, mSEV_DEP) AS pcmiss
	FROM mRB090 LEFT JOIN mAGE ON (mRB090.DB020 = mAGE.DB020)
				LEFT JOIN mSEV_DEP ON (mRB090.DB020 = mSEV_DEP.DB020);
QUIT;
* calc values, N and total weights;

PROC TABULATE data=work.idb out=Ti;

		FORMAT AGE f_age15.;
		FORMAT RB090 f_sex.;
		CLASS AGE /MLF;
		CLASS RB090 /MLF;
		CLASS SEV_DEP ;
		CLASS DB020;
	VAR RB050a;

	TABLE DB020 * AGE * RB090, SEV_DEP * RB050a * (RowPctSum N Sum) /printmiss;

RUN;



* fill RDB variables;
%macro by_unit(unit,ival); 

PROC SQL;

/* for getting previous flag */

CREATE TABLE work.old_flag AS
SELECT 	time,
			geo,
			age,
			sex,
			unit,
			iflag
FROM rdb.mddd11 
WHERE geo in &Uccs and unit= "&unit" and time = &yyyy ; 

/* Indicator table */

CREATE TABLE work.mddd11 AS
SELECT 
	Ti.DB020 as geo FORMAT=$5. LENGTH=5,
	&yyyy as time,
	Ti.Age,
	Ti.RB090 as sex,
	Ti.SEV_DEP,
	"&unit" as unit,
	Ti.&ival as ivalue,
	old_flag.iflag as iflag,
	/*"&flag" as iflag FORMAT=$3. LENGTH=3,*/
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
LEFT JOIN work.old_flag ON (Ti.DB020 = old_flag.geo) /* for previous flag */
								AND (Ti.Age = old_flag.Age)
								AND (Ti.RB090 = old_flag.sex)
GROUP BY Ti.DB020, ti.AGE, ti.RB090
ORDER BY Ti.DB020, ti.AGE, ti.RB090;
QUIT;
* Update RDB;

DATA  rdb.mddd11 (drop= SEV_DEP);
set rdb.mddd11(where=(not(time = &yyyy and geo = "&Ucc" and unit = "&unit")))
    work.mddd11;
	where SEV_DEP=1;
RUN;
%mend by_unit;

	%by_unit(PC_POP,RB050a_PctSum_1101);
	%by_unit(THS_PER,RB050a_Sum/1000);


%end;

%if &EU %then %do;

* EU aggregates;

%let tab=mddd11;
%let grpdim=age, sex, unit;
%EUVALS(&Ucc,&Uccs);

%end;

PROC SQL;  
     Insert into log.log
     set date = "&sysdate"d, time = "&systime"t, user = "&sysuserid",
		 report = "* &Ucc - &yyyy * mddd11 (re)calculated *";		  
QUIT;
%mend UPD_mddd11;
