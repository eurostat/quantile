/*
. AROPE by most frequent activity status Intersection indicators
*/
/* 20120111MG applid new ACTSTA definition */
/* removed a group by arope in work.&tab*/

%macro UPD_pees02 (yyyy,Ucc,Uccs,flag,notBDB);

PROC DATASETS lib=work kill nolist;
QUIT;
%let tab=pees02;
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
		18 - HIGH = "Y_GE18";

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

VALUE $f_AROPE (multilabel)
	"100" = "R_NDEP_NLOW "
	"101" = "R_NDEP_LOW  "
	"110" = "R_DEP_NLOW  "
	"111" = "R_DEP_LOW   "
	"001" = "NR_NDEP_LOW "
	"010" = "NR_DEP_NLOW "
	"011" = "NR_DEP_LOW  "
	"000" = "NR_NDEP_NLOW";

RUN;

* extract from IDB;

PROC SQL noprint;
Create table work.idb as 
	select distinct DB010, DB020, RB030, RB050a, Age, /* RB090, */ AROPE, ACTSTA
	from idb.IDB&yy as IDB
	where DB020 in &Uccs and age ge 18;
QUIT;

* calculate % missing values;

PROC SQL noprint;

CREATE TABLE nfilled AS SELECT DISTINCT DB020, (N(RB030)) AS N1 FROM work.idb WHERE AROPE not is missing GROUP BY DB020;
CREATE TABLE nmissing AS SELECT DISTINCT DB020, (N(RB030)) AS N_1 FROM work.idb WHERE AROPE is missing GROUP BY DB020;
CREATE TABLE mAROPE AS SELECT nfilled.DB020, (100/(N1+N_1)*N_1) AS mAROPE FROM nfilled LEFT JOIN nmissing ON (nfilled.DB020 = nmissing.DB020);

CREATE TABLE nfilled AS SELECT DISTINCT DB020, (N(RB030)) AS N1 FROM work.idb WHERE ACTSTA not is missing GROUP BY DB020;
CREATE TABLE nmissing AS SELECT DISTINCT DB020, (N(RB030)) AS N_1 FROM work.idb WHERE ACTSTA is missing GROUP BY DB020;
CREATE TABLE mACTSTA AS SELECT nfilled.DB020, (100/(N1+N_1)*N_1) AS mACTSTA FROM nfilled LEFT JOIN nmissing ON (nfilled.DB020 = nmissing.DB020);

CREATE TABLE missunrel AS SELECT mAROPE.DB020, 
	max( mAROPE, mACTSTA) AS pcmiss
	FROM mAROPE

	LEFT JOIN mACTSTA ON (mAROPE.DB020 = mACTSTA.DB020);
QUIT;

* calc values, N and total weights;

PROC TABULATE data=work.idb out=Ti;
		FORMAT AROPE $f_AROPE.;
		FORMAT ACTSTA f_act15.;
		CLASS ACTSTA /MLF;
		CLASS AROPE /MLF;
		CLASS DB020;
	VAR RB050a;
	TABLE DB020  * ACTSTA, AROPE * RB050a * (RowPctSum N Sum) /printmiss;
RUN;

* fill RDB variables;

%macro by_unit(unit,ival); 

PROC SQL;
    CREATE TABLE work.old_flag AS SELECT 
	geo,
	time, 
	indic_il,
	wstatus,
    unit, 
	ivalue,
	iflag
    FROM rdb.&tab
    WHERE geo in &Uccs  and time = &yyyy ;
	
	CREATE TABLE work.&tab AS
	SELECT 
	Ti.DB020 as geo FORMAT=$5. LENGTH=5,
	&yyyy as time,
	Ti.ACTSTA as wstatus,
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
	LEFT JOIN work.old_flag ON (Ti.DB020=old_flag.geo)  AND (Ti.ACTSTA=old_flag.wstatus)  AND (Ti.AROPE=old_flag.indic_il)
	GROUP BY Ti.DB020, ti.ACTSTA 
	ORDER BY Ti.DB020, ti.ACTSTA, Ti.AROPE;
	QUIT;

* Update RDB;

 	DATA  rdb.&tab ; 
 		set rdb.&tab(where=(not(time = &yyyy and geo = "&Ucc" /* and unit = "&unit" */))) 
 	        work.&tab;
 	RUN;
 
%mend by_unit;

	%by_unit(PC_POP,RB050a_PctSum_101);

%end;

%if &EU %then %do;

* EU aggregates;

%let tab=pees02;
%let grpdim= wstatus , indic_il,unit ;
%EUVALS(&Ucc,&Uccs);

%end;

PROC SQL;  
     Insert into log.log
     set date = "&sysdate"d, time = "&systime"t, user = "&sysuserid",
		 report = "* &Ucc - &yyyy * pees02 (re)calculated *";		  
QUIT;

%mend UPD_pees02;
