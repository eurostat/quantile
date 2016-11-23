/*
. AROPE by age and gender - Intersection indicators
*/
/* version of 07/06/2011*/
/* removed a group by arope in work.&tab*/
/*BB20120706  add some new age breakdowns*/
%macro UPD_pees01(yyyy,Ucc,Uccs,flag,notBDB);

PROC DATASETS lib=work kill nolist;
QUIT;
%global NotDatabase;

%let tab=pees01;
%let NotDatabase=0;
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
		0 - 17 = "Y_LT18"
		18 - HIGH = "Y_GE18"
		18 - 49 = "Y18-49"
		18 - 59 = "Y18-59"
		18 - 64 = "Y18-64"
		25 - 54 = "Y25-54"
		50 - 64 = "Y50-64"
		55 - 64 = "Y55-64"
		65 - HIGH = "Y_GE65"
		0 - HIGH = "TOTAL";

VALUE f_sex (multilabel)
		1 = "M"
		2 = "F"
		1 - 2 = "T";

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
	select distinct DB010, DB020, RB030, RB050a, Age, RB090, AROPE
	from idb.IDB&yy as IDB
	where DB020 in &Uccs;
QUIT;

* calculate % missing values;

PROC SQL noprint;
CREATE TABLE nfilled AS SELECT DISTINCT DB020, (N(RB030)) AS N1 FROM work.idb WHERE AGE not is missing GROUP BY DB020;
CREATE TABLE nmissing AS SELECT DISTINCT DB020, (N(RB030)) AS N_1 FROM work.idb WHERE AGE is missing GROUP BY DB020;
CREATE TABLE mAGE AS SELECT nfilled.DB020, (100/(N1+N_1)*N_1) AS mAGE FROM nfilled LEFT JOIN nmissing ON (nfilled.DB020 = nmissing.DB020);

CREATE TABLE nfilled AS SELECT DISTINCT DB020, (N(RB030)) AS N1 FROM work.idb WHERE RB090 not is missing GROUP BY DB020;
CREATE TABLE nmissing AS SELECT DISTINCT DB020, (N(RB030)) AS N_1 FROM work.idb WHERE RB090 is missing GROUP BY DB020;
CREATE TABLE mRB090 AS SELECT nfilled.DB020, (100/(N1+N_1)*N_1) AS mRB090 FROM nfilled LEFT JOIN nmissing ON (nfilled.DB020 = nmissing.DB020);

CREATE TABLE nfilled AS SELECT DISTINCT DB020, (N(RB030)) AS N1 FROM work.idb WHERE AROPE not is missing GROUP BY DB020;
CREATE TABLE nmissing AS SELECT DISTINCT DB020, (N(RB030)) AS N_1 FROM work.idb WHERE AROPE is missing GROUP BY DB020;
CREATE TABLE mAROPE AS SELECT nfilled.DB020, (100/(N1+N_1)*N_1) AS mAROPE FROM nfilled LEFT JOIN nmissing ON (nfilled.DB020 = nmissing.DB020);

CREATE TABLE missunrel AS SELECT mAGE.DB020, 
	max(mAGE, mRB090, mAROPE) AS pcmiss
	FROM mAGE LEFT JOIN mRB090 ON (mAGE.DB020 = mRB090.DB020)
	LEFT JOIN mAROPE ON (mAGE.DB020 = mAROPE.DB020);
QUIT;

* calc values, N and total weights;
PROC TABULATE data=work.idb out=Ti;
		FORMAT AGE f_age15.;
		FORMAT RB090 f_sex.;
	    FORMAT AROPE $f_AROPE13.;
		CLASS AGE /MLF;
		CLASS RB090 /MLF;
		CLASS AROPE /MLF;
		CLASS DB020;
	VAR RB050a;
	TABLE DB020 * AGE * RB090, AROPE * RB050a * (RowPctSum N Sum) /printmiss;
RUN;

* fill RDB variables;

%macro by_unit(unit,ival); 
PROC SQL;
    CREATE TABLE work.old_flag AS SELECT
	geo,
	time, 
	age,
	sex,
	indic_il,
	unit,
	ivalue,
	iflag
    FROM rdb.&tab
    WHERE geo in &Uccs and unit ="&unit" and time = &yyyy ;
QUIT;

Proc sql;
   CREATE TABLE work.&tab AS
   SELECT 
	Ti.DB020 as geo FORMAT=$5. LENGTH=5,
	&yyyy as time,
	Ti.Age,
	Ti.RB090 as sex,
	Ti.arope as indic_il,
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
	  LEFT JOIN work.old_flag ON (Ti.DB020=old_flag.geo) AND (Ti.Age=old_flag.age) AND ( Ti.RB090 = old_flag.sex) and ( Ti.AROPE = old_flag.indic_il)  
GROUP BY Ti.DB020, ti.AGE, ti.RB090
ORDER BY Ti.DB020, ti.AGE, ti.RB090, Ti.arope;
QUIT;

* Update RDB;

/* before to update it checks if the indicator already exists */
	DATA  rdb.&tab ; 
		set rdb.&tab(where=(not(time = &yyyy and geo = "&Ucc" and unit = "&unit"))) 
	        work.&tab;
	RUN;
%mend by_unit;

	%by_unit(THS_PER,RB050a_Sum/1000);
	%by_unit(PC_POP,RB050a_PctSum_1101);

%end;

%if &EU %then %do;

* EU aggregates;

%let grpdim=age, sex, indic_il, unit;
%EUVALS(&Ucc,&Uccs);

%end;

PROC SQL;  
     Insert into log.log
     set date = "&sysdate"d, time = "&systime"t, user = "&sysuserid",
		 report = "* &Ucc - &yyyy * &tab (re)calculated *";		  
QUIT;

%mend UPD_pees01;
