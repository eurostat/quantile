

%macro UPD_lvho08(yyyy,Ucc,Uccs,flag,notBDB);

/*. Median of the housing cost burden distribution (median share of housing cost) -  total population */
*** changed age format 5 November 2010 ***;
/*20111123BB prevent calculation for DE all years*/
/*20110923BB calculation is done from a new variable HY20 (in IDB) calculated from HY020, PY080 and HY025) */
/*20141106MG to check if working datasets IDB is empty */

PROC DATASETS lib=work kill nolist;
QUIT;

%let cc=%lowcase(&Ucc);
%let yy=%substr(&yyyy,3,2);
%let EU=0;
%let DB100Missing=0;
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

%if not (&UCC = DE and &year < 2010) %then %do; /* PP 06/12/12 DE now OK for years from 2010 on */

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
	VALUE f_DEG_URB (multilabel)
			1 = "DEG1"
			2 = "DEG2"
			3 = "DEG3"
			1 - 3 = "TOTAL"
			;
	RUN;

	*calculate HCB (housing cost burden);

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

	PROC SQL;
	 CREATE TABLE work.idb AS SELECT DISTINCT IDB.DB010,IDB.DB020, IDB.DB030, IDB.RB030, IDB.RB050a, IDB.AGE,
		 IDB.RB090, IDB.ARPT60i, IDB.QITILE, IDB.HT1, IDB.TENSTA_2, IDB.HY20, BDBh.HY070G, BDBh.HY070G_F, BDBh.HY070N,
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
	CREATE TABLE nfilled AS SELECT DISTINCT DB020, (N(RB030)) AS N1 FROM work.idb WHERE HCB1 not is missing GROUP BY DB020;
	CREATE TABLE nmissing AS SELECT DISTINCT DB020, (N(RB030)) AS N_1 FROM work.idb WHERE HCB1 is missing GROUP BY DB020;
	CREATE TABLE mHCB1 AS SELECT nfilled.DB020, (100/(N1+N_1)*N_1) AS mHCB1 FROM nfilled LEFT JOIN nmissing ON (nfilled.DB020 = nmissing.DB020);

	CREATE TABLE missunrel AS SELECT mHCB1.DB020, 
					max(mHCB1,0) AS pcmiss
		FROM mHCB1;
	QUIT;



	* Median of the housing cost burden distribution by age, and gender and poverty 
	* calc values, N and total weights;

	PROC MEANS DATA=WORK.IDB
		FW=12
		PRINTALLTYPES
		CHARTYPE
		QMETHOD=OS
		NWAY
		VARDEF=DF
		
			SUMWGT 
			N
			MEDIAN	;
		FORMAT  AGE f_AGE. RB090 f_sex. ARPT60i f_incgrp. ;
		VAR HCB1;
		CLASS DB010;
		CLASS DB020 /	MLF;
		CLASS AGE /	MLF;
		CLASS RB090 /	MLF;
		CLASS ARPT60i /	MLF;
		WEIGHT RB050a;

	OUTPUT 	OUT=WORK.Ti(LABEL="Summary Statistics for WORK.IDB")
		
			SUMWGT()=
			N()=	
			MEDIAN()=

		/ AUTONAME AUTOLABEL  WAYS INHERIT
		;
	RUN;

	%let tab=lvho08a;

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
		"PC" as unit,
		Ti.HCB1_Median as ivalue,
			old_flag.iflag as iflag,
		(case when Ti.HCB1_N < 20 or missunrel.pcmiss > 50 then 2
			  when Ti.HCB1_N < 50 or missunrel.pcmiss > 20 then 1
			  else 0
		      end) as unrel,
		Ti.HCB1_N as n,
		Ti.HCB1_N as ntot,
		Ti.HCB1_SumWgt as totwgh,
		"&sysdate" as lastup,
		"&sysuserid" as	lastuser 
	FROM Ti LEFT JOIN missunrel ON (Ti.DB020 = missunrel.DB020)
			LEFT JOIN work.old_flag ON (Ti.DB020 = old_flag.geo) 
		    AND (Ti.age = old_flag.age) AND (Ti.RB090  = old_flag.sex) 
		    AND (Ti.ARPT60i  = old_flag.incgrp)
	 ORDER BY Ti.DB020, ti.AGE, ti.RB090, Ti.ARPT60i;
		QUIT;


	* Update RDB;
	DATA  rdb.&tab;
	set rdb.&tab (where=(not(time = &yyyy and geo in &Uccs)))
	    work.&tab; 
	RUN;
	%put +UPDATED &tab;



	*Median of the housing cost burden distribution by degree of urbanisation 
	* calc values, N and total weights;

	%let tab=lvho08b;
	%if &DB100Missing=0	%then %do; /* 20141106MG  NO DB100 missing  */

	PROC MEANS DATA=WORK.IDB
		FW=12
		PRINTALLTYPES
		CHARTYPE
		QMETHOD=OS
		NWAY
		VARDEF=DF
		
			SUMWGT 
			N
			MEDIAN	;
		FORMAT  DB100 f_DEG_URB.;
		VAR HCB1;
		CLASS DB010;
		CLASS DB020 /	MLF;
		CLASS DB100 /	MLF;
		WEIGHT RB050a;

	OUTPUT 	OUT=WORK.Ti(LABEL="Summary Statistics for WORK.IDB")
		
			SUMWGT()=
			N()=	
			MEDIAN()=

		/ AUTONAME AUTOLABEL  WAYS INHERIT
		;
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
		ti.DB100 as DEG_URB,
		"PC" as unit,
		Ti.HCB1_Median as ivalue,
		old_flag.iflag as iflag,
		(case /*when (Ti.DB020 in ('LT','IS') and Ti.DB100='DEG2') then 5 /* never DB100=2 for them value = ":"*/
			  when Ti.HCB1_N < 20 or missunrel.pcmiss > 50 then 2
			  when Ti.HCB1_N < 50 or missunrel.pcmiss > 20 then 1
			  else 0
		      end) as unrel,
		Ti.HCB1_N as n,
		Ti.HCB1_N as ntot,
		Ti.HCB1_SumWgt as totwgh,
		"&sysdate" as lastup,
		"&sysuserid" as	lastuser 
	FROM Ti LEFT JOIN missunrel ON (Ti.DB020 = missunrel.DB020)
			LEFT JOIN work.old_flag ON (Ti.DB020 = old_flag.geo) 
		    AND (Ti.DB100  = old_flag.DEG_URB) 
	ORDER BY Ti.DB020, ti.DB100;
		QUIT;


	* Update RDB;
	DATA  rdb.&tab;
	set rdb.&tab (where=(not(time = &yyyy and geo in &Uccs)))
	    work.&tab(where=(DEG_URB ne "TOTAL")); 
	RUN;
	%put +UPDATED &tab;

	%end;
%end;
	%if &EU %then %do;

	* EU aggregates;

	%let tab=lvho08a;
	%let grpdim=age, sex, incgrp, unit;
	%EUVALS(&Ucc,&Uccs);

	%let tab=lvho08b;
	%let grpdim=DEG_URB, unit;
	%EUVALS(&Ucc,&Uccs);

	%end;

	PROC SQL;  
	     Insert into log.log
	     set date = "&sysdate"d, time = "&systime"t, user = "&sysuserid",
			 report = "* &Ucc - &yyyy * lvho08a (re)calculated *";		  
	QUIT;
		PROC SQL;  
	     Insert into log.log
	     set date = "&sysdate"d, time = "&systime"t, user = "&sysuserid",
			 report = "* &Ucc - &yyyy * lvho08b (re)calculated *";		  
	QUIT;
%end;
%else %do;
	PROC SQL;  
	     Insert into log.log
	     set date = "&sysdate"d, time = "&systime"t, user = "&sysuserid",
			 report = "* &Ucc - &yyyy * NO lvho08 CALCULATION ALLOWED FOR *";		  
	QUIT;
%end;

%let not60=0;
%mend UPD_lvho08;
