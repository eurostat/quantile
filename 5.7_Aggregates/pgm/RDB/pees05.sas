/*
. AROPE by education level - Intersection indicators
*/
/* version of 07/06/2011*/
/* removed a group by arope in work.&tab*/
/*20120601MG changed ISCED code */
%macro UPD_pees05 (yyyy,Ucc,Uccs,flag,notBDB);

PROC DATASETS lib=work kill nolist;
QUIT;

%let tab=pees05;
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

VALUE f_educ (multilabel)
		0 - 2 = "ED0-2"
		3 - 4 = "ED3_4"
		5 - 6 = "ED5_6"
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
	select distinct DB010, DB020, RB030, RB050a, Age, AROPE, PE40
	from idb.IDB&yy as IDB
	where DB020 in &Uccs and age ge 18;
QUIT;

* calculate % missing values;

PROC SQL noprint;

CREATE TABLE nfilled AS SELECT DISTINCT DB020, (N(RB030)) AS N1 FROM work.idb WHERE AROPE not is missing GROUP BY DB020;
CREATE TABLE nmissing AS SELECT DISTINCT DB020, (N(RB030)) AS N_1 FROM work.idb WHERE AROPE is missing GROUP BY DB020;
CREATE TABLE mAROPE AS SELECT nfilled.DB020, (100/(N1+N_1)*N_1) AS mAROPE FROM nfilled LEFT JOIN nmissing ON (nfilled.DB020 = nmissing.DB020);

CREATE TABLE nfilled AS SELECT DISTINCT DB020, (N(RB030)) AS N1 FROM work.idb WHERE PE40 not is missing GROUP BY DB020;
CREATE TABLE nmissing AS SELECT DISTINCT DB020, (N(RB030)) AS N_1 FROM work.idb WHERE PE40 is missing GROUP BY DB020;
CREATE TABLE mPE40 AS SELECT nfilled.DB020, (100/(N1+N_1)*N_1) AS mPE40 FROM nfilled LEFT JOIN nmissing ON (nfilled.DB020 = nmissing.DB020);

CREATE TABLE missunrel AS SELECT mAROPE.DB020, 
	max( mAROPE, mPE40) AS pcmiss
	FROM mAROPE 
	LEFT JOIN mPE40 ON (mAROPE.DB020 = mPE40.DB020);
QUIT;

* calc values, N and total weights;

PROC TABULATE data=work.idb out=Ti;
	    FORMAT AROPE $f_AROPE12.;
		FORMAT PE40 f_educ15.;
		CLASS PE40 /MLF;
		CLASS AROPE /MLF;
		CLASS DB020;
	VAR RB050a;

	TABLE DB020 * PE40, AROPE * RB050a * (RowPctSum N Sum) /printmiss;
RUN;

* fill RDB variables;

%let ival=RB050a_PctSum_101;
%let unit=PC_POP;

	PROC SQL;
    CREATE TABLE work.old_flag AS SELECT
	geo,
	time, 
	isced97,
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
		Ti.PE40 as isced97,
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
	LEFT JOIN work.old_flag ON (Ti.DB020=old_flag.geo) AND (Ti.PE40=old_flag.isced97) AND (Ti.AROPE=old_flag.indic_il)
	GROUP BY Ti.DB020, ti.PE40
	ORDER BY Ti.DB020, ti.PE40, Ti.AROPE;

	QUIT;

* Update RDB;
 	DATA  rdb.&tab ; 
 		set rdb.&tab(where=(not(time = &yyyy and geo = "&Ucc" ))) 
 	        work.&tab;
 	RUN;

%end;

%if &EU %then %do;

* EU aggregates;

%let grpdim= isced97,indic_il, unit ;

%EUVALS(&Ucc,&Uccs);

%end;

PROC SQL;  
     Insert into log.log
     set date = "&sysdate"d, time = "&systime"t, user = "&sysuserid",
		 report = "* &Ucc - &yyyy * &tab (re)calculated *";		  
QUIT;

%mend UPD_pees05;
