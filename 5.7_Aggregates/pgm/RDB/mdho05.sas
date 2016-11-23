*** changed age format 5 November 2010 ***;
*Lack of bath, or shower and indoor flushing toilet in the dwelling  ;

/* version of 14/01/2011*/

/*20120203BB take into account variables removed from 2011 operation (HH080 HH090)*/ 
%macro UPD_mdho05(yyyy,Ucc,Uccs,flag,notBDB);

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
		9 - 13 = "HH_DCH"
		9 =	 "A1_DCH"
		10 = "A2_1DCH"
		11 = "A2_2DCH"
		12 = "A2_GE3DCH"
		13 = "A_GE3_DCH"
		1 - 13 = "TOTAL"
		;
RUN;

*calculate LACK_BST (lack of bath shower and toilet);

PROC SQL;
 CREATE TABLE work.idb AS SELECT DISTINCT IDB.DB010,IDB.DB020, IDB.DB030, IDB.RB030, IDB.RB050a, IDB.AGE,
	 IDB.RB090, IDB.ARPT60i, IDB.HT1,
	 
	%if &yyyy<2008 %then %do;
		BDB.HH080,
		BDB.HH080_F,
		BDB.HH090,
		BDB.HH090_F,
		(CASE WHEN BDB.HH080= 2 THEN 1 WHEN BDB.HH080= 1 THEN 0 ELSE BDB.HH080 END) AS LACK_BATH_SHOWER,
		(CASE WHEN BDB.HH090= 2 THEN 1 WHEN BDB.HH090= 1 THEN 0 ELSE BDB.HH090 END) AS LACK_TOILET,
	%end;
	%if &yyyy>2007 and &yyyy<2011 %THEN %DO;
		BDB.HH081,
		BDB.HH081_F,
		(CASE WHEN (BDB.HH081_F=1 AND BDB.HH081= 3) THEN 1 WHEN (BDB.HH081_F=-5 AND BDB.HH080= 2) THEN 1 
			WHEN (BDB.HH081_F=1 AND BDB.HH081 in (1,2)) THEN 0 WHEN (BDB.HH081_F=-5 AND BDB.HH080=1) THEN 0 
		ELSE . END) AS LACK_BATH_SHOWER,
	 	BDB.HH091,
	 	BDB.HH091_F,
	 	(CASE WHEN (BDB.HH091_F=1 AND BDB.HH091= 3) THEN 1 WHEN (BDB.HH091_F=-5 AND BDB.HH090= 2) THEN 1 
			WHEN (BDB.HH091_F=1 AND BDB.HH091 in (1,2)) THEN 0 WHEN (BDB.HH091_F=-5 AND BDB.HH090=1) THEN 0 
		ELSE . END) AS LACK_TOILET,
	 %END;
	 /* changed on 14/11/2012 MG */
	 %if &yyyy>2010 %then %do;
		BDB.HH081,
		BDB.HH081_F,
		(CASE WHEN BDB.HH081= 3 THEN 1 
			WHEN BDB.HH081 in (1,2) THEN 0
		ELSE . END) AS LACK_BATH_SHOWER,
	 	BDB.HH091,
	 	BDB.HH091_F,
	 	(CASE WHEN BDB.HH091= 3 THEN 1 
			WHEN BDB.HH091 in (1,2) THEN 0 
		ELSE . END) AS LACK_TOILET,
	 %END;
	 (CASE  WHEN CALCULATED LACK_BATH_SHOWER =1 AND CALCULATED LACK_TOILET = 1 THEN 1
			WHEN (CALCULATED LACK_BATH_SHOWER is missing OR CALCULATED LACK_TOILET is missing ) THEN . ELSE 0 END ) AS LACK_BST
 
 FROM IDB.IDB&yy AS IDB,  in.&infil.H AS BDB
 WHERE (IDB.HT1 <> 16 AND IDB.DB010 = BDB.HB010 AND IDB.DB020 = BDB.HB020 AND IDB.DB030 = BDB.HB030 AND IDB.DB020 in &Uccs);
QUIT;


* calculate % missing values;
PROC SQL noprint;
CREATE TABLE nfilled AS SELECT DISTINCT DB020, (N(RB030)) AS N1 FROM work.idb WHERE LACK_BST not is missing GROUP BY DB020;
CREATE TABLE nmissing AS SELECT DISTINCT DB020, (N(RB030)) AS N_1 FROM work.idb WHERE LACK_BST is missing GROUP BY DB020;
CREATE TABLE mLACK_BST AS SELECT nfilled.DB020, (100/(N1+N_1)*N_1) AS mLACK_BST FROM nfilled LEFT JOIN nmissing ON (nfilled.DB020 = nmissing.DB020);

CREATE TABLE missunrel AS SELECT mLACK_BST.DB020, 
				max(mLACK_BST,0) AS pcmiss
	FROM mLACK_BST;
QUIT;

* Lack of bath, or shower and indoor flushing toilet in the dwelling  by age, gender, poverty status a	nd household type 
* calc values, N and total weights;

PROC TABULATE data=work.idb out=Ti;
		FORMAT AGE f_age15.;
		FORMAT RB090 f_sex.;
		FORMAT ARPT60i  f_incgrp15.;
		FORMAT HT1  f_HHTYP.;
		CLASS DB010;
		CLASS DB020;
		CLASS LACK_BST;
		CLASS AGE /MLF;
		CLASS RB090 /MLF;
		CLASS ARPT60i /MLF;
		CLASS HT1 /MLF;
		
	VAR RB050a;
	TABLE DB010 * DB020 * AGE * RB090 * ARPT60i * HT1, LACK_BST * RB050a * (RowPctSum N Sum) /printmiss;
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
   	  hhtyp,
	  iflag
FROM rdb.mdho05
WHERE  time = &yyyy ;

CREATE TABLE work.mdho05 AS
SELECT 
	Ti.DB020 as geo FORMAT=$5. LENGTH=5,
	Ti.DB010 as time,
	Ti.Age,
	Ti.RB090 as sex,
	ti.ARPT60i as incgrp,
	ti.HT1 as HHTYP,
	"PC_POP" as unit,
	ti.LACK_BST,
	Ti.RB050a_PctSum_1101111 as ivalue,
	old_flag.iflag as iflag,
	/*mmdho05..iflag as iflag, */
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
	AND (Ti.ARPT60i  = old_flag.incgrp) AND (Ti.HT1 = old_flag.hhtyp) 
GROUP BY Ti.DB020, ti.AGE, ti.RB090, Ti.ARPT60i, Ti.HT1;
	QUIT;


* Update RDB;
DATA  rdb.mdho05(drop=LACK_BST);
set rdb.mdho05 (where=(not(time = &yyyy and geo in &Uccs)))
    work.mdho05(where=(LACK_BST = 1)); 
RUN;
%put +UPDATED mdho05;

%end;

%if &EU %then %do;

* EU aggregates;

%let tab=mdho05;
%let grpdim=age, sex, incgrp, HHTYP, unit;
%EUVALS(&Ucc,&Uccs);

%end;

PROC SQL;  
     Insert into log.log
     set date = "&sysdate"d, time = "&systime"t, user = "&sysuserid",
		 report = "* &Ucc - &yyyy * mdho05 (re)calculated *";		  
QUIT;

%mend UPD_mdho05;
