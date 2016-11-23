%macro UPD_lvho16(yyyy,Ucc,Uccs,flag,notBDB);
* lvhlo16 Overcrowding rate by age gender and C_BIRTH

/* created on 20130717MG  */
PROC DATASETS lib=work kill nolist;
QUIT;

%let cc=%lowcase(&Ucc);
%let yy=%substr(&yyyy,3,2);
%let not60=0;/* allows calculation of aggregates if less than 70% of pop*/
%let tab=lvho16;
%let EU=0;
%if &Uccs=0 %then %let Uccs=("&Ucc");
%else %let EU=1;

%let not60=0;

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
		1 - 2 = "T"
		;

VALUE f_c_birth (multilabel)

		1 = "NAT"
		3 = "EU27_FOR"
		2 = "NEU27_FOR"
		6 = "EU28_FOR"
		4 = "NEU28_FOR"
		2 - 6 = "FOR" ;

RUN;


PROC SQL noprint;
Create table work.idb as 
	select distinct IDB.DB010, IDB.DB020, IDB.DB030, IDB.RB030, IDB.RB050a, IDB.Age, IDB.RB090, 
			IDB.OVERCROWDED,IDB.c_birth
	from idb.IDB&yy as IDB
	
		where  IDB.DB020 in &Uccs and age ge 18;

Select distinct count(DB010) as N 
	into :nobs
	from  work.idb;
QUIT;
%if &nobs > 0
%then %do;

* calculate % missing values;
PROC SQL noprint;
CREATE TABLE nfilled AS SELECT DISTINCT DB020, (N(RB030)) AS N1 FROM work.idb WHERE OVERCROWDED not is missing GROUP BY DB020;
CREATE TABLE nmissing AS SELECT DISTINCT DB020, (N(RB030)) AS N_1 FROM work.idb WHERE OVERCROWDED is missing GROUP BY DB020;
CREATE TABLE mOVERCROWDED AS SELECT nfilled.DB020, (100/(N1+N_1)*N_1) AS mOVERCROWDED FROM nfilled LEFT JOIN nmissing ON (nfilled.DB020 = nmissing.DB020);

CREATE TABLE nfilled AS SELECT DISTINCT DB020, (N(RB030)) AS N1 FROM work.idb WHERE c_birth not is missing GROUP BY DB020;
CREATE TABLE nmissing AS SELECT DISTINCT DB020, (N(RB030)) AS N_1 FROM work.idb WHERE c_birth is missing GROUP BY DB020;
CREATE TABLE mc_birth AS SELECT nfilled.DB020, (100/(N1+N_1)*N_1) AS mc_birth FROM nfilled LEFT JOIN nmissing ON (nfilled.DB020 = nmissing.DB020);

CREATE TABLE missunrel AS SELECT mOVERCROWDED.DB020, 
                                 max(mOVERCROWDED, mc_birth) AS pcmiss
	FROM mOVERCROWDED
	LEFT JOIN mc_birth ON (mOVERCROWDED.DB020 = mc_birth.DB020)
	;;
QUIT;


%if &EU=0 %then %do;

* calc values, N and total weights;


PROC TABULATE data=work.idb out=Ti;
		FORMAT AGE f_age15.;
		FORMAT RB090 f_sex.;
		FORMAT c_birth f_c_birth15.;
		CLASS DB020;
		CLASS AGE /MLF;
		CLASS RB090 /MLF;
		CLASS c_birth /MLF;
		CLASS OVERCROWDED;
		VAR RB050a;
	TABLE DB020 * AGE * RB090*c_birth , OVERCROWDED * RB050a * (RowPctSum N Sum) /printmiss;
RUN;

* fill RDB variables;
PROC SQL;
CREATE TABLE work.old_flag AS
SELECT 
      time,
      geo,
	  age,
	  sex,
	  c_birth,
   	  iflag
FROM rdb.&tab
WHERE  time = &yyyy ;

CREATE TABLE work.&tab AS
SELECT 
	Ti.DB020 as geo FORMAT=$5. LENGTH=5,
	&yyyy as time,
	Ti.Age,
	Ti.RB090 as sex,
	ti.c_birth as c_birth,
	ti.OVERCROWDED,
	"PC_POP" as unit,
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
	    AND (Ti.c_birth  = old_flag.c_birth)
GROUP BY Ti.DB020, ti.AGE, ti.RB090, Ti.c_birth;

	QUIT;

* Update RDB;
DATA  rdb.&tab(drop=OVERCROWDED);
set rdb.&tab(where=(not(time = &yyyy and geo in &Uccs)))
work.&tab(where=(OVERCROWDED = 1)) ; 
RUN;

%end;

%if &EU %then %do;

	* EU aggregates;
	
	%let grpdim=age,sex ,c_birth,unit;
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
%let not60=0;
%mend UPD_lvho16;
