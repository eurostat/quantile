/*
. SEVERE MATERIAL DEPRIVATION by income quintile and household type 
*/

/* 20110824BB remove gendre breakdown*/

%macro UPD_mddd13(yyyy,Ucc,Uccs,flag,notBDB);

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

VALUE f_quintile (multilabel)
		1 - 5 = "TOTAL"
		1 = "QUINTILE1"
		2 = "QUINTILE2"
		3 = "QUINTILE3"
		4 = "QUINTILE4"
		5 = "QUINTILE5";

VALUE f_ht (multilabel)
		1 - 8 = "HH_NDCH"
		1-5 =	 "A1" 
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
		1 - 13 = "TOTAL";

RUN;

* extract from IDB;

PROC SQL noprint;
Create table work.idb as 
	select distinct DB010, DB020, RB030, RB050a, QITILE, HT1, SEV_DEP, DEP_RELIABILITY
	from idb.IDB&yy as IDB
	where HT1 between 1 and 13 and DB020 in &Uccs;
QUIT;

* calculate % missing values;

PROC SQL noprint;

CREATE TABLE nfilled AS SELECT DISTINCT DB020, (N(RB030)) AS N1 FROM work.idb WHERE HT1 not is missing GROUP BY DB020;
CREATE TABLE nmissing AS SELECT DISTINCT DB020, (N(RB030)) AS N_1 FROM work.idb WHERE HT1 is missing GROUP BY DB020;
CREATE TABLE mHT1 AS SELECT nfilled.DB020, (100/(N1+N_1)*N_1) AS mHT1 FROM nfilled LEFT JOIN nmissing ON (nfilled.DB020 = nmissing.DB020);

CREATE TABLE nfilled AS SELECT DISTINCT DB020, (N(RB030)) AS N1 FROM work.idb WHERE QITILE not is missing GROUP BY DB020;
CREATE TABLE nmissing AS SELECT DISTINCT DB020, (N(RB030)) AS N_1 FROM work.idb WHERE QITILE is missing GROUP BY DB020;
CREATE TABLE mQITILE AS SELECT nfilled.DB020, (100/(N1+N_1)*N_1) AS mQITILE FROM nfilled LEFT JOIN nmissing ON (nfilled.DB020 = nmissing.DB020);

create table work.mSEV_DEP as
 select distinct DB020,
(DEP_RELIABILITY*30) as mSEV_DEP
 from work.IDB;

CREATE TABLE missunrel AS SELECT mQITILE.DB020, 
	max(mSEV_DEP, mQITILE, mHT1) AS pcmiss
	FROM mQITILE LEFT JOIN mHT1 ON (mQITILE.DB020 = mHT1.DB020)
				 LEFT JOIN mSEV_DEP ON (mQITILE.DB020 = mSEV_DEP.DB020);
QUIT;

* calc values, N and total weights;

PROC TABULATE data=work.idb out=Ti;

		FORMAT QITILE f_quintile.;
		FORMAT HT1 f_ht15.;
		CLASS DB020;
		CLASS QITILE /MLF;
		CLASS HT1 /MLF ;
		CLASS SEV_DEP ;
		
		VAR RB050a;

	TABLE DB020 * QITILE * HT1, SEV_DEP * RB050a * (RowPctSum N Sum) /printmiss;

RUN;



* fill RDB variables;
%macro by_unit(unit,ival); 

PROC SQL;

/* for getting previous flag */

CREATE TABLE work.old_flag AS
SELECT DISTINCT
			time,
			geo,
			quantile,
			hhtyp,
			unit,
			iflag
FROM rdb.mddd13 
WHERE geo in &Uccs and unit= "&unit" and time = &yyyy ; 

/* Indicator table */

CREATE TABLE work.mddd13 AS
SELECT 
	&yyyy as time,
	Ti.DB020 as geo FORMAT=$5. LENGTH=5,
	Ti.QITILE as quantile,
	Ti.HT1 as hhtyp,
	Ti.SEV_DEP,
	"&unit" as unit,
	Ti.&ival as ivalue,
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
LEFT JOIN work.old_flag ON (Ti.DB020 = old_flag.geo) /* for previous flag */
								AND (Ti.QITILE = old_flag.quantile)
								AND (Ti.HT1 = old_flag.hhtyp)
GROUP BY Ti.DB020, ti.QITILE, ti.HT1
ORDER BY Ti.DB020, ti.QITILE, ti.HT1;
QUIT;

* Update RDB;
DATA  rdb.mddd13 (drop= SEV_DEP);
set rdb.mddd13(where=(not(time = &yyyy and geo = "&Ucc" and unit = "&unit")))
    work.mddd13;
	where SEV_DEP=1;
RUN;
%mend by_unit;

	%by_unit(PC_POP,RB050a_PctSum_1110);
	*%by_unit(THS_PER,RB050a_Sum/1000);


%end;

%if &EU %then %do;

* EU aggregates;

%let tab=mddd13;
%let grpdim= quantile, hhtyp, unit;
%EUVALS(&Ucc,&Uccs);

%end;

PROC SQL;  
     Insert into log.log
     set date = "&sysdate"d, time = "&systime"t, user = "&sysuserid",
		 report = "* &Ucc - &yyyy * mddd13 (re)calculated *";		  
QUIT;

%mend UPD_mddd13;
