/*
. AROPE by broad group of citizenship - Intersection indicators
*/

/* version of 07/06/2011*/
/* removed a group by arope in work.&tab*/

%macro UPD_pees06 (yyyy,Ucc,Uccs,flag,notBDB);

PROC DATASETS lib=work kill nolist;
QUIT;

%let tab=pees06;
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

PROC FORMAT; /* change the age codes with new ones and proper for that table*/

VALUE f_age (multilabel)
		18 - HIGH = "Y_GE18"
		;

VALUE f_CIT_SHIP (multilabel)
		1 = "NAT"
		3 = "EU27_FOR"
		2 = "NEU27_FOR"
		6 = "EU28_FOR"
		4 = "NEU28_FOR"
		2 - 6 = "FOR" ;

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
	select distinct DB010, DB020, RB030, RB050a, Age, AROPE, CIT_SHIP
	from idb.IDB&yy as IDB
	where DB020 in &Uccs and age ge 18;
QUIT;

* calculate % missing values;

PROC SQL noprint;

CREATE TABLE nfilled AS SELECT DISTINCT DB020, (N(RB030)) AS N1 FROM work.idb WHERE AGE not is missing GROUP BY DB020;
CREATE TABLE nmissing AS SELECT DISTINCT DB020, (N(RB030)) AS N_1 FROM work.idb WHERE AGE is missing GROUP BY DB020;
CREATE TABLE mAGE AS SELECT nfilled.DB020, (100/(N1+N_1)*N_1) AS mAGE FROM nfilled LEFT JOIN nmissing ON (nfilled.DB020 = nmissing.DB020);

CREATE TABLE nfilled AS SELECT DISTINCT DB020, (N(RB030)) AS N1 FROM work.idb WHERE AROPE not is missing GROUP BY DB020;
CREATE TABLE nmissing AS SELECT DISTINCT DB020, (N(RB030)) AS N_1 FROM work.idb WHERE AROPE is missing GROUP BY DB020;
CREATE TABLE mAROPE AS SELECT nfilled.DB020, (100/(N1+N_1)*N_1) AS mAROPE FROM nfilled LEFT JOIN nmissing ON (nfilled.DB020 = nmissing.DB020);

CREATE TABLE nfilled AS SELECT DISTINCT DB020, (N(RB030)) AS N1 FROM work.idb WHERE CIT_SHIP not is missing GROUP BY DB020;
CREATE TABLE nmissing AS SELECT DISTINCT DB020, (N(RB030)) AS N_1 FROM work.idb WHERE CIT_SHIP is missing GROUP BY DB020;
CREATE TABLE mCIT_SHIP AS SELECT nfilled.DB020, (100/(N1+N_1)*N_1) AS mCIT_SHIP FROM nfilled LEFT JOIN nmissing ON (nfilled.DB020 = nmissing.DB020);

CREATE TABLE missunrel AS SELECT mAGE.DB020, 
	max(mAGE, mAROPE, mCIT_SHIP) AS pcmiss
	FROM mAGE 
	LEFT JOIN mAROPE ON (mAGE.DB020 = mAROPE.DB020)
	LEFT JOIN mCIT_SHIP ON (mAGE.DB020 = mCIT_SHIP.DB020);
QUIT;

* calc values, N and total weights;

PROC TABULATE data=work.idb out=Ti;
		FORMAT AGE f_age15.;
		FORMAT AROPE $f_AROPE12.;
		FORMAT CIT_SHIP f_cit_ship15.;
		CLASS AGE /MLF;
		CLASS CIT_SHIP /MLF;
		CLASS AROPE /MLF;
		CLASS DB020;
	VAR RB050a;
	TABLE DB020 * AGE  * CIT_SHIP, AROPE * RB050a * (RowPctSum N Sum) /printmiss;
RUN;

* fill RDB variables;

%let ival=RB050a_PctSum_1101;
%let unit=PC_POP;

	PROC SQL;
    CREATE TABLE work.old_flag AS SELECT
	geo,
	time, 
	citizen,
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
		Ti.CIT_SHIP as citizen,
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
	LEFT JOIN work.old_flag ON (Ti.DB020=old_flag.geo) AND (Ti.CIT_SHIP=old_flag.citizen) AND (Ti.AROPE=old_flag.indic_il)
	GROUP BY Ti.DB020, ti.AGE, ti.CIT_SHIP
	ORDER BY Ti.DB020, ti.AGE, ti.CIT_SHIP,Ti.AROPE;
	QUIT;

 	DATA  rdb.&tab ; 
 		set rdb.&tab(where=(not(time = &yyyy and geo = "&Ucc" ))) 
 	        work.&tab;
 	RUN;

%end;

%if &EU %then %do;

* EU aggregates;

%let grpdim= citizen,indic_il, unit ;

%EUVALS(&Ucc,&Uccs);

%end;

PROC SQL;  
     Insert into log.log
     set date = "&sysdate"d, time = "&systime"t, user = "&sysuserid",
		 report = "* &Ucc - &yyyy * &tab (re)calculated *";		  
QUIT;

%mend UPD_pees06;
