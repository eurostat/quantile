%macro UPD_lvho07(yyyy,Ucc,Uccs,flag,notBDB);
/*20120229BB changes in age ranges*/
/*20120601MG changed ISCED code */
/*20111123BB ptrevent calculation for DE all years*/
/*20110923BB calculation is done from a new variable HY20 (in IDB) calculated from HY020, PY080 and HY025) */
/*Housing cost burden -  total population */
*** changed age format 5 November 2010 ***;
/*20141106MG to check if working datasets IDB is empty */



PROC DATASETS lib=work kill nolist;
QUIT;

%let cc=%lowcase(&Ucc);
%let yy=%substr(&yyyy,3,2);
%let EU=0;
%let DB100Missing=0;
%if &Uccs=0 %then %let Uccs=("&Ucc");
%else %let EU=1;


%let not60=0;

%if not (&UCC = DE and &year < 2010) %then %do; /* PP 06/12/12 DE now OK for years from 2010 on */

	%if &EU=0 %then %do;

	PROC FORMAT;

	VALUE f_agex (multilabel)
			0 - 17 = "Y_LT18"
			18 - 64 = "Y18-64"
			18 - 24 = "Y18-24"
			25 - 29 = "Y25-29"
			65 - HIGH = "Y_GE65"
			0 - HIGH = "TOTAL"
			0 - 5 = "Y_LT6"
			6 - 11 = "Y6-11"
			12 - 17 = "Y12-17"	
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

	VALUE f_tenstatu (multilabel)
			1 = "OWN_NL"
			2 = "OWN_L"
			3 = "RENT_MKT"
			4 = "RENT_FR"
			1 - 4 = "TOTAL"
			;

	VALUE f_DEG_URB (multilabel)
			1 = "DEG1"
			2 = "DEG2"
			3 = "DEG3"
			1 - 3 = "TOTAL"
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
			6 - 8 = "A_GE2_NDCH"
			9 - 13 = "HH_DCH"
			9 =	 "A1_DCH"
			10 = "A2_1DCH"
			11 = "A2_2DCH"
			12 = "A2_GE3DCH"
			13 = "A_GE3_DCH"
			10 - 13 = "A_GE2_DCH"
			1 - 13 = "TOTAL"
			other = "OTHER"
			;


	VALUE f_QUINTILE (multilabel)
			1 = "QUINTILE1"
			2 = "QUINTILE2"
			3 = "QUINTILE3"
			4 = "QUINTILE4"
			5 = "QUINTILE5"
			1 - 5 = "TOTAL"
			;
	RUN;

/*20141210MG  to check if  DB100 variable  is in D-PDB file:   */

data FDB100;set in.&infil.d;where DB020 in &Uccs;run;   /*20141106MG to check if working datasets IDB is empty */

Proc sql;                                   
Select distinct count(DB010) as N 
	into :nobs
	from  FDB100;
quit;

PROC MEANS DATA=FDB100 	NWAY 	N  	NMISS	;
	VAR DB100;
	CLASS DB020 ;
OUTPUT 	OUT=WORK.NUMMIS
		N()= 
		NMISS()=
	 / AUTONAME AUTOLABEL  WAYS INHERIT
	;
RUN;
Proc sql;                                                
Select distinct DB100_NMiss  as Nn  
	into :NM
	from  work.NUMMIS ;
quit;

%if &nobs=&Nm %then %let DB100Missing=1;


/* End step to check if  DB100 variable is in D-PDB file*/


	*calculate HCB (housing cost burden);

	PROC SQL;
	 CREATE TABLE work.idb AS SELECT DISTINCT IDB.DB010,IDB.DB020, IDB.DB030, IDB.RB030, IDB.RB050a, IDB.AGE,
		 IDB.RB090, IDB.ARPT60i, IDB.QITILE, IDB.HT1, IDB.TENSTA_2,IDB.HY20,  BDBh.HY070G, BDBh.HY070G_F, BDBh.HY070N,
		 BDBh.HH070,
	     %if &DB100Missing=0 %then  %do ;
			  BDBd.DB100, 
		  %end;

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
		%if &DB100Missing=0 %then %do;
		where BDBd.DB100 in(1,2,3) AND IDB.DB020 in &Uccs;
		%end;
		%else  %do;
		where  IDB.DB020 in &Uccs;
		%end;

	QUIT;




	* calculate % missing values;
	PROC SQL noprint;
	CREATE TABLE nfilled AS SELECT DISTINCT DB020, (N(RB030)) AS N1 FROM work.idb WHERE HCB not is missing GROUP BY DB020;
	CREATE TABLE nmissing AS SELECT DISTINCT DB020, (N(RB030)) AS N_1 FROM work.idb WHERE HCB is missing GROUP BY DB020;
	CREATE TABLE mHCB AS SELECT nfilled.DB020, (100/(N1+N_1)*N_1) AS mHCB FROM nfilled LEFT JOIN nmissing ON (nfilled.DB020 = nmissing.DB020);

	CREATE TABLE missunrel AS SELECT mHCB.DB020, 
					max(mHCB,0) AS pcmiss
		FROM mHCB;
	QUIT;


	* Housing cost overburden rate by age, gender and poverty status 
	* calc values, N and total weights;

	%let tab=lvho07a;

	PROC TABULATE data=work.idb out=Ti;
			FORMAT AGE f_agex.;
			FORMAT RB090 f_sex.;
			FORMAT ARPT60i  f_incgrp15.;
			CLASS DB010;
			CLASS DB020;
			CLASS HCB;
			CLASS AGE /MLF;
			CLASS RB090 /MLF;
			CLASS ARPT60i /MLF;
			
		VAR RB050a;
		TABLE DB010 * DB020 * AGE * RB090 * ARPT60i, HCB * RB050a * (RowPctSum N Sum) /printmiss;
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
	   	  iflag
	FROM rdb.&tab
	WHERE  time = &yyyy ;
	CREATE TABLE work.&tab AS
	SELECT 
		Ti.DB020 as geo FORMAT=$5. LENGTH=5,
		Ti.DB010 as time,
		Ti.Age,
		Ti.RB090 as sex,
		ti.ARPT60i as incgrp,
		"PC_POP" as unit,
		ti.HCB,
		Ti.RB050a_PctSum_110111 as ivalue,
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
		    AND (Ti.ARPT60i  = old_flag.incgrp)
	GROUP BY Ti.DB020, ti.AGE, ti.RB090, Ti.ARPT60i;
		QUIT;



	* Update RDB;
	DATA  rdb.&tab(drop=HCB);
	set rdb.&tab (where=(not(time = &yyyy and geo in &Uccs)))
	    work.&tab(where=(HCB = 1)); 
	RUN;
	%put +UPDATED &tab;


	* : Housing cost overburden rate by income quintile 
	* calc values, N and total weights;


	%let tab=lvho07b;

	PROC TABULATE data=work.idb out=Ti;
			FORMAT QITILE f_QUINTILE.;
			CLASS HCB;
			CLASS QITILE /MLF;	
			CLASS DB020;
			CLASS DB010;
		VAR RB050a;
		TABLE DB010 * DB020 * QITILE, HCB * RB050a * (RowPctSum N Sum) /printmiss;
	RUN;

	* fill RDB variables;
	PROC SQL;
	CREATE TABLE work.old_flag AS
	SELECT 
	      time,
	      geo,
		  QUANTILE,
	   	  iflag
	FROM rdb.&tab
	WHERE  time = &yyyy ;
	CREATE TABLE work.&tab AS
	SELECT 
		Ti.DB020 as geo FORMAT=$5. LENGTH=5,
		Ti.DB010 as time,
		Ti.QITILE as QUANTILE,
		"PC_POP" as unit,
		ti.HCB,
		Ti.RB050a_PctSum_0111 as ivalue,
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
		    AND (Ti.QITILE = old_flag.QUANTILE) 
	GROUP BY Ti.DB020, Ti.QITILE;
		QUIT;


	* Update RDB;
	DATA  rdb.&tab(drop=HCB);
	set rdb.&tab(where=(not(time = &yyyy and geo in &Uccs)))
	    work.&tab(where=(HCB = 1 and QUANTILE ne "TOTAL")); 
	RUN;
	%put +UPDATED &tab;



	* Housing cost overburden rate by new tenure status 
	* calc values, N and total weights;

	%let tab=lvho07c;

	PROC TABULATE data=work.idb out=Ti;
			FORMAT TENSTA_2  f_tenstatu.;
			CLASS HCB;
			CLASS TENSTA_2 /MLF;	
		CLASS DB020;
		CLASS DB010;
		VAR RB050a;
		TABLE DB010 * DB020 * TENSTA_2, HCB * RB050a * (RowPctSum N Sum) /printmiss;
	RUN;

	* fill RDB variables;
	PROC SQL;
	CREATE TABLE work.old_flag AS
	SELECT 
	      time,
	      geo,
		  TENURE,
		  iflag
	FROM rdb.&tab
	WHERE  time = &yyyy ;

	CREATE TABLE work.&tab AS
	SELECT 
		Ti.DB020 as geo FORMAT=$5. LENGTH=5,
		Ti.DB010 as time,
		Ti.TENSTA_2 as TENURE,
		"PC_POP" as unit,
		ti.HCB,
		Ti.RB050a_PctSum_0111 as ivalue,
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
		    AND (Ti.TENSTA_2 = old_flag.TENURE) 
			GROUP BY Ti.DB020, Ti.TENSTA_2;
		QUIT;


	* Update RDB;
	DATA  rdb.&tab(drop=HCB);
	set rdb.&tab(where=(not(time = &yyyy and geo in &Uccs)))
	    work.&tab(where=(HCB = 1 and TENURE ne "TOTAL")); 
	RUN;
	%put +UPDATED &tab;


	* Housing cost overburden rate by degree of urbanisation 
	* calc values, N and total weights;

	%let tab=lvho07d;

%if &DB100Missing=0	%then %do; /* 20141106MG  NO DB100 missing  */

	PROC TABULATE data=work.idb out=Ti;
			FORMAT DB100  f_DEG_URB.;
			CLASS HCB;
			CLASS DB100 /MLF;	
		CLASS DB020;
		CLASS DB010;
		VAR RB050a;
		TABLE DB010 * DB020 * DB100, HCB * RB050a * (RowPctSum N Sum) /printmiss;
	RUN;

	* fill RDB variables;
	PROC SQL;
	CREATE TABLE work.old_flag AS
	SELECT 
	      time,
	      geo,
		  DEG_URB,
		  iflag
	FROM rdb.&tab
	WHERE  time = &yyyy ;

	CREATE TABLE work.&tab AS
	SELECT 
		Ti.DB020 as geo FORMAT=$5. LENGTH=5,
		Ti.DB010 as time,
		Ti.DB100 as DEG_URB,
		"PC_POP" as unit,
		ti.HCB,
		Ti.RB050a_PctSum_0111 as ivalue,
		old_flag.iflag as iflag,
		(case /*when (Ti.DB020 in ('LT','IS') and Ti.DB100='DEG2') then 5 /* never DB100=2 for them value = ":"*/
			  when sum(Ti.RB050a_N) < 20 or missunrel.pcmiss > 50 then 2
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
		    AND (Ti.DB100 = old_flag.DEG_URB) 
	GROUP BY Ti.DB020, Ti.DB100;
		QUIT;

	* Update RDB;
	DATA  rdb.&tab(drop=HCB);
	set rdb.&tab(where=(not(time = &yyyy and geo in &Uccs)))
	    work.&tab(where=(HCB = 1 and DEG_URB ne "TOTAL")); 
	RUN;
	%put +UPDATED &tab;

	* Housing cost overburden rate by Household type
	* calc values, N and total weights;
%end;
	%let tab=lvho07e;

	PROC TABULATE data=work.idb out=Ti;
			FORMAT HT1  f_HHTYP.;
			CLASS HCB;
			CLASS HT1 /MLF;	
		CLASS DB020;
		CLASS DB010;
		VAR RB050a;
		TABLE DB010 * DB020 * HT1, HCB * RB050a * (RowPctSum N Sum) /printmiss;
	RUN;

	* fill RDB variables;
	PROC SQL;
	CREATE TABLE work.old_flag AS
	SELECT 
	      time,
	      geo,
		  HHTYP,
		  iflag
	FROM rdb.&tab
	WHERE  time = &yyyy ;

	CREATE TABLE work.&tab AS
	SELECT 
		Ti.DB020 as geo FORMAT=$5. LENGTH=5,
		Ti.DB010 as time,
		Ti.HT1 as HHTYP,
		"PC_POP" as unit,
		ti.HCB,
		Ti.RB050a_PctSum_0111 as ivalue,
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
		    AND (Ti.HT1 = old_flag.HHTYP) 
	GROUP BY Ti.DB020, Ti.HT1;
		QUIT;

	* Update RDB;
	DATA  rdb.&tab(drop=HCB);
	set rdb.&tab(where=(not(time = &yyyy and geo in &Uccs)))
	    work.&tab(where=(HCB = 1 and HHTYP not in ("TOTAL", "OTHER" ))); 
	RUN;
	%put +UPDATED &tab;


	
%end;
	%if &EU %then %do;

	* EU aggregates;

	%let tab=lvho07a;
	%let grpdim=age, sex, incgrp, unit;
	%EUVALS(&Ucc,&Uccs);

	%let tab=lvho07b;
	%let grpdim=QUANTILE, unit;
	%EUVALS(&Ucc,&Uccs);

	%let tab=lvho07c;
	%let grpdim=TENURE, unit;
	%EUVALS(&Ucc,&Uccs);

	%let tab=lvho07d;
	%let grpdim=DEG_URB, unit;
	%EUVALS(&Ucc,&Uccs);

	%let tab=lvho07e;
	%let grpdim=HHTYP, unit;
	%EUVALS(&Ucc,&Uccs);

	%end;

	PROC SQL;  
	     Insert into log.log
	     set date = "&sysdate"d, time = "&systime"t, user = "&sysuserid",
		 report = "* &Ucc - &yyyy * lvho07a (re)calculated *";		  
	QUIT;
		PROC SQL;  
	     Insert into log.log
	     set date = "&sysdate"d, time = "&systime"t, user = "&sysuserid",
		 report = "* &Ucc - &yyyy * lvho07b (re)calculated *";		  
	QUIT;
		PROC SQL;  
	     Insert into log.log
	     set date = "&sysdate"d, time = "&systime"t, user = "&sysuserid",
		 report = "* &Ucc - &yyyy * lvho07c (re)calculated *";		  
	QUIT;
		PROC SQL;  
	     Insert into log.log
	     set date = "&sysdate"d, time = "&systime"t, user = "&sysuserid",
		 report = "* &Ucc - &yyyy * lvho07d (re)calculated *";		  
	QUIT;
		PROC SQL;  
	     Insert into log.log
	     set date = "&sysdate"d, time = "&systime"t, user = "&sysuserid",
		 report = "* &Ucc - &yyyy * lvho07e (re)calculated *";		  
	QUIT;
%end;
%else %do;
	PROC SQL;  
	     Insert into log.log
	     set date = "&sysdate"d, time = "&systime"t, user = "&sysuserid",
		 report = "* &Ucc - &yyyy * NO lvho07 CALCULATION ALLOWED FOR *";		  
	QUIT;
%end;

%let not60=0;
%mend UPD_lvho07;
