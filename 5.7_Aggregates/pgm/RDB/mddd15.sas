/*
. SEVERE MATERIAL DEPRIVATION of 18+ population by broad group of citizenship
*/
/* flags are taken from the existing data set  on 29/11/2010 */
/* version of 22/02/2011*/

%macro UPD_mddd15(yyyy,Ucc,Uccs,flag,notBDB);

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
		18 - HIGH = "Y_GE18"
		18 - 64 = "Y18-64"
		20 - 64 = "Y20-64"
		65 - HIGH = "Y_GE65"
		18 - 59 = "Y18-59"
		60 - HIGH = "Y_GE60"
		18 - 54 = "Y18-54"
		25 - 59 = "Y25-59"
		25 - 54 = "Y25-54"
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
		

RUN;

* extract from IDB;

PROC SQL noprint;
Create table work.idb as 
	select distinct DB010, DB020, RB030, PB040, Age, RB090, SEV_DEP, CIT_SHIP, DEP_RELIABILITY
	from idb.IDB&yy as IDB
	where DB020 in &Uccs and age ge 18;
QUIT;

* calculate % missing values;

PROC SQL noprint;

CREATE TABLE nfilled AS SELECT DISTINCT DB020, (N(RB030)) AS N1 FROM work.idb WHERE AGE not is missing GROUP BY DB020;
CREATE TABLE nmissing AS SELECT DISTINCT DB020, (N(RB030)) AS N_1 FROM work.idb WHERE AGE is missing GROUP BY DB020;
CREATE TABLE mAGE AS SELECT nfilled.DB020, (100/(N1+N_1)*N_1) AS mAGE FROM nfilled LEFT JOIN nmissing ON (nfilled.DB020 = nmissing.DB020);

CREATE TABLE nfilled AS SELECT DISTINCT DB020, (N(RB030)) AS N1 FROM work.idb WHERE RB090 not is missing GROUP BY DB020;
CREATE TABLE nmissing AS SELECT DISTINCT DB020, (N(RB030)) AS N_1 FROM work.idb WHERE RB090 is missing GROUP BY DB020;
CREATE TABLE mRB090 AS SELECT nfilled.DB020, (100/(N1+N_1)*N_1) AS mRB090 FROM nfilled LEFT JOIN nmissing ON (nfilled.DB020 = nmissing.DB020);

CREATE TABLE nfilled AS SELECT DISTINCT DB020, (N(RB030)) AS N1 FROM work.idb WHERE CIT_SHIP not is missing GROUP BY DB020;
CREATE TABLE nmissing AS SELECT DISTINCT DB020, (N(RB030)) AS N_1 FROM work.idb WHERE CIT_SHIP is missing GROUP BY DB020;
CREATE TABLE mCIT_SHIP AS SELECT nfilled.DB020, (100/(N1+N_1)*N_1) AS mCIT_SHIP FROM nfilled LEFT JOIN nmissing ON (nfilled.DB020 = nmissing.DB020);

create table work.mSEV_DEP as
 select distinct DB020,
(DEP_RELIABILITY*30) as mSEV_DEP
 from work.IDB;


CREATE TABLE missunrel AS SELECT mAGE.DB020, 
	max(mAGE, mRB090, mSEV_DEP, mCIT_SHIP) AS pcmiss
	FROM mAGE LEFT JOIN mRB090 ON (mAGE.DB020 = mRB090.DB020)
					LEFT JOIN mCIT_SHIP ON (mAGE.DB020 = mCIT_SHIP.DB020)
						LEFT JOIN mSEV_DEP ON (mAGE.DB020 = mSEV_DEP.DB020);
/* for getting previous flag */						
					
						

QUIT;

* calc values, N and total weights;

PROC TABULATE data=work.idb out=Ti;

		FORMAT AGE f_age15.;
		FORMAT RB090 f_sex.;
		FORMAT CIT_SHIP f_CIT_SHIP.;
		CLASS AGE /MLF;
		CLASS RB090 /MLF;
		CLASS CIT_SHIP /MLF;
		CLASS SEV_DEP ;
		CLASS DB020;

	VAR PB040;

	TABLE DB020 * RB090* AGE * CIT_SHIP , SEV_DEP * PB040 * (RowPctSum N Sum) /printmiss;

RUN;

* fill RDB variables;
%macro by_unit(unit,ival); 
PROC SQL;

CREATE TABLE work.old_flag AS
SELECT 	time,
			geo,
			sex,
			age,
			citizen,
			unit,
			iflag
FROM rdb.mddd15 
WHERE geo in &Uccs and unit= "&unit" and time = &yyyy ; 	

/* Indicator table */
CREATE TABLE work.mddd15 AS
SELECT 
	&yyyy as time,
	Ti.DB020 as geo FORMAT=$5. LENGTH=5,
	Ti.RB090 as sex,
	Ti.Age,
	Ti.CIT_SHIP as citizen length=15,
	Ti.SEV_DEP,
	"&unit" as unit,
	Ti.&ival as ivalue,
	 old_flag.iflag as iflag,
	/*"&flag" as iflag FORMAT=$3. LENGTH=3,*/
	(case when sum(Ti.PB040_N) < 20 or missunrel.pcmiss > 50 then 2
		  when sum(Ti.PB040_N) < 50 or missunrel.pcmiss > 20 then 1
		  else 0
	      end) as unrel,
	Ti.PB040_N as n,
	sum(Ti.PB040_N) as ntot,
	sum(Ti.PB040_Sum) as totwgh,
	"&sysdate" as lastup,
	"&sysuserid" as	lastuser 
FROM Ti LEFT JOIN missunrel ON (Ti.DB020 = missunrel.DB020)
 LEFT JOIN work.old_flag ON (Ti.DB020 = old_flag.geo) /* for previous flag */
								 AND (Ti.RB090 = old_flag.sex)
								AND (Ti.Age = old_flag.age)
								AND (Ti.CIT_SHIP = old_flag.citizen) 
GROUP BY Ti.DB020,ti.RB090, ti.AGE, Ti.CIT_SHIP 
ORDER BY Ti.DB020,ti.RB090, ti.AGE, Ti.CIT_SHIP ;
QUIT;

* Update RDB;
DATA  rdb.mddd15 (drop= SEV_DEP);
set rdb.mddd15(where=(not(time = &yyyy and geo = "&Ucc" and unit = "&unit")))
    work.mddd15;
	where SEV_DEP=1;
RUN; 
%mend by_unit;

	%by_unit(PC_POP,PB040_PctSum_11101);
	*%by_unit(THS_PER,PB040_Sum/1000);


%end;

%if &EU %then %do;

* EU aggregates;

%let tab=mddd15;
%let grpdim= sex, age, citizen, unit;
%EUVALS(&Ucc,&Uccs);

%end;

PROC SQL;  
     Insert into log.log
     set date = "&sysdate"d, time = "&systime"t, user = "&sysuserid",
		 report = "* &Ucc - &yyyy * mddd15 (re)calculated *";		  
QUIT;

%mend UPD_mddd15;
