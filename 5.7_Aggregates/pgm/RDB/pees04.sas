/*
. AROPE by  household type - Intersection indicators
*/

/* version of 07/06/2011*/
/* removed a group by arope in work.&tab*/

%macro UPD_pees04 (yyyy,Ucc,Uccs,flag,notBDB);

PROC DATASETS lib=work kill nolist;
QUIT;
%let tab=pees04;
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

VALUE f_ht (multilabel)
		1 - 8 = "HH_NDCH"
		1-5 =	 "A1"
/*		1,2 = "A1_LT64"
		3,4 = "A1_GE65"
*/
		1,3 = "A1M"
		2,4 = "A1F"
/*		6,7 = "A2"
		6 =	 "A2_2LT65"
		7 =	 "A2_GE1_GE65"
		8 =	 "A_GE3"
*/
		9 - 13 = "HH_DCH"
		9 =	 "A1_DCH"
/*		10 = "A2_1DCH"
		11 = "A2_2DCH"
		12 = "A2_GE3DCH"
		13 = "A_GE3_DCH"
*/
		6 - 8 = "A_GE2_NDCH"
		10 - 13 = "A_GE2_DCH"
		;

VALUE $f_AROPE (multilabel)
"100" = "R_NDEP_NLOW  "
"101" = "R_NDEP_LOW   "
"110" = "R_DEP_NLOW   "
"111" = "R_DEP_LOW    "
"001" = "NR_NDEP_LOW  "
"010" = "NR_DEP_NLOW  "
"011" = "NR_DEP_LOW   "
"000" = "NR_NDEP_NLOW ";


RUN;

* extract from IDB;

PROC SQL noprint;
Create table work.idb as 
	select distinct DB010, DB020, RB030, RB050a, Age, RB090, AROPE, HT1
	from idb.IDB&yy as IDB
	where HT1 between 1 and 13 and DB020 in &Uccs;
QUIT;

* calculate % missing values;

PROC SQL noprint;

CREATE TABLE nfilled AS SELECT DISTINCT DB020, (N(RB030)) AS N1 FROM work.idb WHERE HT1 not is missing GROUP BY DB020;
CREATE TABLE nmissing AS SELECT DISTINCT DB020, (N(RB030)) AS N_1 FROM work.idb WHERE HT1 is missing GROUP BY DB020;
CREATE TABLE mHT1 AS SELECT nfilled.DB020, (100/(N1+N_1)*N_1) AS mHT1 FROM nfilled LEFT JOIN nmissing ON (nfilled.DB020 = nmissing.DB020);

CREATE TABLE nfilled AS SELECT DISTINCT DB020, (N(RB030)) AS N1 FROM work.idb WHERE AROPE not is missing GROUP BY DB020;
CREATE TABLE nmissing AS SELECT DISTINCT DB020, (N(RB030)) AS N_1 FROM work.idb WHERE AROPE is missing GROUP BY DB020;
CREATE TABLE mAROPE AS SELECT nfilled.DB020, (100/(N1+N_1)*N_1) AS mAROPE FROM nfilled LEFT JOIN nmissing ON (nfilled.DB020 = nmissing.DB020);


CREATE TABLE missunrel AS SELECT mAROPE.DB020, 
	max( mHT1,  mAROPE) AS pcmiss
	FROM mAROPE 
	LEFT JOIN mHT1 ON (mAROPE.DB020 = mHT1.DB020);
QUIT;

* calc values, N and total weights;

PROC TABULATE data=work.idb out=Ti;

		FORMAT AROPE $f_AROPE12.;
		FORMAT HT1 f_ht15.;		
		CLASS HT1 /MLF;
		CLASS AROPE /MLF;
		CLASS DB020;
	VAR RB050a;

	TABLE DB020 * HT1, AROPE * RB050a * (RowPctSum N Sum) /printmiss;

RUN;



* fill RDB variables;

%let ival=RB050a_PctSum_101;
%let unit=PC_POP;

	PROC SQL;
    CREATE TABLE work.old_flag AS SELECT
	geo,
	time, 
	hhtyp,
	indic_il,
	unit,
	ivalue,
	iflag
	FROM rdb.&tab
	WHERE geo in &Uccs  and time = &yyyy;
	
CREATE TABLE work.&tab AS
SELECT 
	Ti.DB020 as geo FORMAT=$5. LENGTH=5,
	&yyyy as time,
	Ti.HT1 as hhtyp,
	Ti.AROPE as indic_il,
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
	LEFT JOIN work.old_flag ON (Ti.DB020=old_flag.geo)  AND (Ti.HT1=old_flag.hhtyp) AND (Ti.AROPE=old_flag.indic_il)
GROUP BY Ti.DB020,  ti.HT1
ORDER BY Ti.DB020,  ti.HT1,Ti.AROPE;
QUIT;
	
* Update RDB;

	DATA  rdb.&tab ; 
 		set rdb.&tab(where=(not(time = &yyyy and geo = "&Ucc" ))) 
 	        work.&tab;
 	RUN;
 
%end;

%if &EU %then %do;

* EU aggregates;

%let grpdim= hhtyp, indic_il, unit ;
%EUVALS(&Ucc,&Uccs);

%end;

PROC SQL;  
     Insert into log.log
     set date = "&sysdate"d, time = "&systime"t, user = "&sysuserid",
		 report = "* &Ucc - &yyyy * &tab (re)calculated *";		  
QUIT;

%mend UPD_pees04;
