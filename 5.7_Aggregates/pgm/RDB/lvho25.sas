%macro UPD_lvho25(yyyy,Ucc,Uccs,flag,notBDB);
/*20111123BB ptrevent calculation for DE all years*/
/*20110923BB calculation is done from a new variable HY20 (in IDB) calculated from HY020, PY080 and HY025) */
/*Housing cost burden - by age sex and citizen - population greater than 17 */
/* cretaed on 20130717MG  */

PROC DATASETS lib=work kill nolist;
QUIT;

%let cc=%lowcase(&Ucc);
%let yy=%substr(&yyyy,3,2);
%let tab=lvho25;
%let not60=0;
%let EU=0;
%if &Uccs=0 %then %let Uccs=("&Ucc");
%else %let EU=1;


%let not60=0;

%if not (&UCC = DE and &year < 2010) %then %do; /* PP 06/12/12 DE now OK for years from 2010 on */

%if &EU=0 %then %do;

	PROC FORMAT;

	VALUE f_age (multilabel)
		18 - HIGH = "Y_GE18"
		18 - 64 = "Y18-64"
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
			1 - 2 = "T"
			;

	
   VALUE f_CIT_SHIP (multilabel)

		1 = "NAT"
		3 = "EU27_FOR"
		2 = "NEU27_FOR"
		6 = "EU28_FOR"
		4 = "NEU28_FOR"
		2 - 6 = "FOR" ;

 
	RUN;

	*calculate HCB (housing cost burden);

	PROC SQL;
	 CREATE TABLE work.idb AS SELECT DISTINCT IDB.DB010,IDB.DB020, IDB.RB030, IDB.RB050a, IDB.AGE,idb.cit_ship,
		 IDB.RB090,  IDB.HY20,   BDBh.HY070G, BDBh.HY070G_F, BDBh.HY070N,
		 BDBh.HH070,

		 (CASE WHEN BDBh.HY070G_F= -5 THEN BDBh.HY070N ELSE  BDBh.HY070G END) AS HY070,

		 (CASE WHEN (BDBh.HH070 is missing or CALCULATED HY070 is missing or IDB.HY20 is missing) THEN . 
			WHEN ((BDBh.HH070*12) - CALCULATED HY070) <= 0 THEN 0
			WHEN (IDB.HY20 - CALCULATED HY070)<=0 THEN 100
			WHEN (IDB.HY20 - CALCULATED HY070)<((BDBh.HH070*12) - CALCULATED HY070) THEN 100
			ELSE 100*(((BDBh.HH070*12) - CALCULATED HY070)/(IDB.HY20 - CALCULATED HY070)) END) AS HCB1,

		(CASE WHEN CALCULATED HCB1 is missing then .
			WHEN CALCULATED HCB1 > 40 THEN 1
			ELSE 0 END) AS HCB
	 
	 FROM IDB.IDB&yy AS IDB
		left join in.&infil.d as BDBd on (IDB.DB020 = BDBd.DB020 and IDB.DB030 = BDBd.DB030)
		left join in.&infil.h as BDBh on (IDB.DB020 = BDBh.HB020 and IDB.DB030 = BDBh.HB030)
		where IDB.DB020 in &Uccs and age ge 18;
	QUIT;


* calculate % missing values;
	PROC SQL noprint;
	CREATE TABLE nfilled AS SELECT DISTINCT DB020, (N(RB030)) AS N1 FROM work.idb WHERE HCB not is missing GROUP BY DB020;
	CREATE TABLE nmissing AS SELECT DISTINCT DB020, (N(RB030)) AS N_1 FROM work.idb WHERE HCB is missing GROUP BY DB020;
	CREATE TABLE mHCB AS SELECT nfilled.DB020, (100/(N1+N_1)*N_1) AS mHCB FROM nfilled LEFT JOIN nmissing ON (nfilled.DB020 = nmissing.DB020);

	
	CREATE TABLE nfilled AS SELECT DISTINCT DB020, (N(RB030)) AS N1 FROM work.idb WHERE CIT_SHIP not is missing GROUP BY DB020;
	CREATE TABLE nmissing AS SELECT DISTINCT DB020, (N(RB030)) AS N_1 FROM work.idb WHERE CIT_SHIP is missing GROUP BY DB020;
	CREATE TABLE mCIT_SHIP AS SELECT nfilled.DB020, (100/(N1+N_1)*N_1) AS mCIT_SHIP FROM nfilled LEFT JOIN nmissing ON (nfilled.DB020 = nmissing.DB020);

	CREATE TABLE missunrel AS SELECT mHCB.DB020, 
                                 max(mHCB, mCIT_SHIP) AS pcmiss
	FROM mHCB
	LEFT JOIN mCIT_SHIP ON (mHCB.DB020 = mCIT_SHIP.DB020)
	;
	QUIT;


	* Housing cost overburden rate by age, gender and poverty status 
	* calc values, N and total weights;



	PROC TABULATE data=work.idb out=Ti;
			FORMAT AGE f_age.;
			FORMAT RB090 f_sex.;
			FORMAT CIT_SHIP f_CIT_SHIP15.;
			CLASS DB020;
			CLASS AGE /MLF;
			CLASS RB090 /MLF;
			CLASS CIT_SHIP /MLF;
			CLASS HCB;
			
		VAR RB050a;
		TABLE DB020 * AGE * RB090 * CIT_SHIP, HCB * RB050a * (RowPctSum N Sum) /printmiss;
	RUN;

	* fill RDB variables;
	PROC SQL;
	CREATE TABLE work.old_flag AS
	SELECT 
	      time,
	      geo,
		  age,
		  sex,
		  citizen,
	   	  iflag
	FROM rdb.&tab
	WHERE  time = &yyyy ;
	CREATE TABLE work.&tab AS
	SELECT 
		Ti.DB020 as geo FORMAT=$5. LENGTH=5,
		&yyyy as time,
		Ti.Age,
		Ti.RB090 as sex,
		ti.CIT_SHIP as citizen,
		"PC_POP" as unit,
		ti.HCB,
		Ti.RB050a_PctSum_11110 as ivalue,
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
			LEFT JOIN work.old_flag ON (Ti.DB020 = old_flag.geo) 
		    AND (Ti.age = old_flag.age) AND (Ti.RB090  = old_flag.sex) 
		    AND (Ti.CIT_SHIP  = old_flag.citizen)
	GROUP BY Ti.DB020, ti.AGE, ti.RB090, Ti.CIT_SHIP;
		QUIT;


	* Update RDB;
	DATA  rdb.&tab(drop=HCB);
	set rdb.&tab (where=(not(time = &yyyy and geo in &Uccs)))
	    work.&tab(where=(HCB = 1)); 
	RUN;


%end;

	%if &EU %then %do;

	* EU aggregates;

	%let tab=lvho25;
	%let grpdim=age, sex, citizen, unit;
	%EUVALS(&Ucc,&Uccs);

	
	%end;

	PROC SQL;  
	     Insert into log.log
	     set date = "&sysdate"d, time = "&systime"t, user = "&sysuserid",
		 report = "* &Ucc - &yyyy * lvho25 (re)calculated *";		  
	QUIT;
	
%end;
%else %do;
	PROC SQL;  
	     Insert into log.log
	     set date = "&sysdate"d, time = "&systime"t, user = "&sysuserid",
		 report = "* &Ucc - &yyyy * NO lvho25 CALCULATION ALLOWED FOR *";		  
	QUIT;
%end;
%let not60=0;
%mend UPD_lvho25;
