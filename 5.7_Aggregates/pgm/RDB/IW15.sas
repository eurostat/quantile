
*** IN-WORK At-risk-poverty-rate by age and gender  and citizen ***;

%macro UPD_iw15(yyyy,Ucc,Uccs,flag) /store;
/* flags are taken from the existing data set  on 7/12/2010 */
/* 22/12/2010 modified to eliminate AGE variable from the old_flag dataset   */
/* consistent AGE format already existed with the changed format for the flags*/
/* 20120111MG applyed new ACTSTA definition */
/* 20120120MG applyed mEUvals to calcultion aggregates */
/* 20131002mg REMOVED acsta */
PROC DATASETS lib=work kill nolist;
QUIT;
%let tab=iw15;
%let cc=%lowcase(&Ucc);
%let yy=%substr(&yyyy,3,2);
%let EU=0;
%if &Uccs=0 %then %let Uccs=("&Ucc");
%else %let EU=1; 

*** At-risk-poverty-rate by age and gender ***;
/* 20110909BG updating the age formats in accordance with the dissemination requirements*/
PROC FORMAT;
VALUE f_age (multilabel)
 	18 - HIGH = "Y_GE18"

		18 - 64 = "Y18-64"
		20 - 64 = "Y20-64"

		65 - HIGH = "Y_GE65"

		18 - 59 = "Y18-59"

		60 - HIGH = "Y_GE60"

		18 - 54 = "Y18-54"

		25 - 59 = "Y25-59"

		25 - 54 = "Y25-54"
		20 - 64 = "Y20-64"
		55 - 64 = "Y55-64"

		55 - HIGH = "Y_GE55";
		
	VALUE f_sex (multilabel)
		1 = "M"
		2 = "F"
		1 - 2 = "T";
		
    VALUE f_CIT_SHIP (multilabel)
		1 = "NAT"
		3 = "EU27_FOR"
		2 = "NEU27_FOR"
		6 = "EU28_FOR"
		4 = "NEU28_FOR"
		2 - 6 = "FOR" ;

 /*20110627BB  ADD ACTSTA as breakdown*/
   /*20120404BB change format according to new ACTSTA categories*/
   VALUE f_act (multilabel)
		1 - 4 = "EMP" /* 1 filled only up to 2008 included, 2,3,4 filled only from 2009 no overlapping*/
		2 = "SAL"
		3 = "NSAL"  
		;
RUN;

PROC SQL noprint;
Create table work.idb as 
	select DB010, DB020, DB030, RB030, PB040, ARPT60i, 
			Age, RB090, CIT_SHIP 
	from idb.IDB&yy
	where ACTSTA in(1,2,3,4) and
			age ge 18 and DB010 = &yyyy and DB020 in &Uccs;
Select distinct count(DB010) as N 
	into :nobs
	from  work.idb;
Create table work.&tab like rdb.&tab; 
QUIT;
* calculate % missing values;

PROC SQL noprint;


CREATE TABLE nfilled AS SELECT DISTINCT DB020, (N(RB030)) AS N1 FROM work.idb WHERE ARPT60i not is missing GROUP BY DB020;
CREATE TABLE nmissing AS SELECT DISTINCT DB020, (N(RB030)) AS N_1 FROM work.idb WHERE ARPT60i is missing GROUP BY DB020;
CREATE TABLE mARPT60i AS SELECT nfilled.DB020, (100/(N1+N_1)*N_1) AS mARPT60i FROM nfilled LEFT JOIN nmissing ON (nfilled.DB020 = nmissing.DB020);

CREATE TABLE nfilled AS SELECT DISTINCT DB020, (N(RB030)) AS N1 FROM work.idb WHERE CIT_SHIP not is missing GROUP BY DB020;
CREATE TABLE nmissing AS SELECT DISTINCT DB020, (N(RB030)) AS N_1 FROM work.idb WHERE CIT_SHIP is missing GROUP BY DB020;
CREATE TABLE mCIT_SHIP AS SELECT nfilled.DB020, (100/(N1+N_1)*N_1) AS mCIT_SHIP FROM nfilled LEFT JOIN nmissing ON (nfilled.DB020 = nmissing.DB020);

CREATE TABLE missunrel AS SELECT mARPT60i.DB020,
                                 max(mARPT60i, mCIT_SHIP) AS pcmiss
	FROM mARPT60i
	LEFT JOIN mCIT_SHIP ON (mARPT60i.DB020 = mCIT_SHIP.DB020)
	;;
QUIT;

%if &nobs > 0
%then %do;

%if &EU=0 %then %do;

	%let arpt=ARPT60i;

	PROC TABULATE data=work.idb out=Ti;
		FORMAT AGE f_age15.;
		FORMAT RB090 f_sex.;
	
		FORMAT CIT_SHIP f_cit_ship15.;
		CLASS DB020;
		CLASS AGE /MLF;
		CLASS RB090 /MLF;
		
		Class CIT_SHIP /MLF;
		CLASS &arpt ;
		VAR PB040;

	TABLE DB020 * AGE * RB090 *CIT_SHIP , &arpt * PB040 * (RowPctSum N Sum) /printmiss;

	RUN;
	
		
	PROC SQL;
	CREATE TABLE work.old_flag AS
SELECT distinct
      time,
      geo,
	  sex,
	  age,
	   citizen,
	  iflag
FROM rdb.&tab

WHERE  time = &yyyy  and geo ="&Ucc";

	CREATE TABLE work.&tab AS
    SELECT 
		"&Ucc" as geo,
		&yyyy as time,
		Ti.Age,
		Ti.RB090 as sex,
	
		Ti.CIT_SHIP as citizen,
		ti.ARPT60i as ARPT60i,
		"PC_POP" as unit,
		Ti.PB040_PctSum_11110 as ivalue,
		old_flag.iflag as iflag, 
        
	(case when sum(Ti.PB040_N) < 20 or missunrel.pcmiss > 50 then 2
		  when sum(Ti.PB040_N) < 50 or missunrel.pcmiss > 20 then 1
		  else 0
	      end) as unrel,
		Ti.PB040_N as n,
		sum(Ti.PB040_N) as ntot,
		sum(Ti.PB040_Sum) as totwgh,
		"&sysdate" as lastup,
		"&sysuserid" as	lastuser 
		FROM Ti	left JOIN missunrel ON (Ti.DB020 = missunrel.DB020)
		LEFT JOIN work.old_flag ON (Ti.RB090  = old_flag.sex) AND (Ti.age = old_flag.age) and 
		(Ti.CIT_SHIP= old_flag.citizen) 
GROUP BY Ti.DB020, ti.age,ti.rb090,Ti.CIT_SHIP
;
	QUIT;


* Update RDB;   

DATA  rdb.&tab (drop= &arpt);
set rdb.&tab(where=(not(time = &yyyy and geo = "&Ucc")))
    work.&tab;
	where &arpt=1;
RUN;
 
%end; 
%if &EU %then %do;
 
	* EU aggregates;
	
	%let grpdim=age,sex ,citizen,unit;
	%EUVALS(&Ucc,&Uccs);
%end;

	%if &euok = 0 and &EU %then %do;
		PROC SQL;  
		Insert into log.log
		set date = "&sysdate"d, time = "&systime"t, user = "&sysuserid",
			report = "* &Ucc - &yyyy * NO enought countries available! ";		  
		QUIT;
		%end;
		%else %do;
		PROC SQL;  
		Insert into log.log
		set date = "&sysdate"d, time = "&systime"t, user = "&sysuserid",
			report = "* &Ucc - &yyyy * &tab (re)calculated *";		  
		QUIT;
	%end;
%end;
%else %do; 
PROC SQL;  
     Insert into log.log
     set date = "&sysdate"d, time = "&systime"t, user = "&sysuserid",
		 report = "* &Ucc - &yyyy * NO DATA !";		  
QUIT;
%end;

%mend UPD_iw15;
