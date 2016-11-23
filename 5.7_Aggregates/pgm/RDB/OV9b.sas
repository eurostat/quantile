*** OV9b1 / SIP8a *** Proportion of population lacking at least three items in the 'economic strain and durables' dimension 
of the material deprivation items by age, gender and at-risk-of-poverty status;
*** OV9b2 / SIP8b *** Mean number of items lacked by persons considered as deprived in the 'economic strain and durables' dimension
by age, gender and at-risk-of-poverty status;

*** changed age format 4 November 2010 ***;
*remove of filtering of missing on 23/11/2010;
/* flags are taken from the existing data set  on 5/12/2010 */
/* 22/12/2010 modified to eliminate AGE variable from the old_flag dataset    */
/* consistent AGE format already existed with the changed format for the flags*/
*** child age format added  25 October 2011 - 20111025MG***;
%macro UPD_OV9B(yyyy,Ucc,Uccs,flag,notBDB);

/*20120203BB take into account variables removed from 2011 operation (HS010 HS020 HS030)*/ 
/*20110913BB removal of incgrp from breakdown variables and change in flagging procedure*/

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
%let not60=0;
*/
%if &EU=0 %then %do;

PROC FORMAT;

VALUE f_age (multilabel)
		0 - 17 = "Y_LT18"
		18 - 64 = "Y18-64"
		65 - HIGH = "Y_GE65"
		0 - HIGH = "TOTAL";
VALUE f_agex (multilabel)
		0 - 5 = "Y_LT6"
	 	6 - 11 = "Y6-11"
		12 - 17 = "Y12-17"	
		0 - 17 = "Y_LT18"
		18 - 64 = "Y18-64"
		65 - HIGH = "Y_GE65"
		0 - HIGH = "TOTAL";	
		
		
		

VALUE f_sex (multilabel)
		1 = "M"
		2 = "F"
		1 - 2 = "T";

VALUE f_n_item (multilabel)
		0="0"
		1="1"
		2="2"
		3="3"
		4="4"
		5="5"
		6="6"
		7="7"
		8="8"
		9="9"
		0-2="LT3"
		0-3="LT4"
		0-4="LT5"
		3-9="GE3"
		4-9="GE4"
		5-9="GE5" 
		0-9="TOTAL";

RUN;

* extract from IDB;

PROC SQL noprint;
Create table work.bdb as 
	select distinct HB010, HB020, HB030, 
%if &yyyy < 2008  %then %do;
		HS010, HS020, HS030, HS010_F, HS020_F, HS030_F, 
%end;
%else %if &yyyy>2007 and &yyyy<2011 %then %do;
		(case when HS010_F=-5 then 
				case 
				when HS011=2 then 1
				when HS011=3 then 2
				else HS011
				end
		 else HS010
		 end) as HS010,
		(case when HS010_F=-5 then HS011_F
		 else HS010_F
		 end) as HS010_F,
		(case when HS020_F=-5 then 
				case 
				when HS021=2 then 1
				when HS021=3 then 2
				else HS021
				end
		 else HS020
		 end) as HS020,
		(case when HS020_F=-5 then HS021_F
		 else HS020_F
		 end) as HS020_F,

		(case when HS030_F=-5 then 
				case 	
				when HS031=2 then 1
				when HS031=3 then 2
				else HS031
				end
		 else HS030
		 end) as HS030,

		(case when HS030_F=-5 then HS031_F
		 else HS030_F
		 end) as HS030_F,
%end;
%else %do;
		HS011_F AS HS010_F,
		HS021_F AS HS020_F,
		HS031_F AS HS030_F,
		(case when HS011=2 then 1
			  when HS011=3 then 2
			  else HS011 end) as HS010,
		(case when HS021=2 then 1
			  when HS021=3 then 2
			  else HS021 end) as HS020,
		(case when HS031=2 then 1
			  when HS031=3 then 2
			  else HS031 end) as HS030,
%end;
		HS040, HS050, HS060, HS070, HS080, HS100, HS110, HH050
	from in.&infil.h as BDB 
	where HB020 in &Uccs;

Create table work.idb as 
	select distinct DB010, DB020, RB030, RB050a, Age, RB090, HS010, HS020, HS030, HS040, HS050, HS060, HS070,
					HS080, HS100, HS110, HH050, DEP_RELIABILITY
	from idb.IDB&yy as IDB
	left join work.bdb as BDB on (IDB.DB020 = BDB.HB020 and IDB.DB030 = BDB.HB030)
	where DB020 in &Uccs;
QUIT;

* # items lacking;
PROC SQL noprint;

Create table work.lack as 
	select distinct DB010, DB020, RB030, RB050a, Age, RB090, HS010, HS020, HS030, HS040, HS050, HS060, HS070,
					HS080, HS100, HS110, HH050,
					(case when HS010=1 or HS020=1 or HS030=1 then 1 else 0 end) as L1,
					(case when HS040=2 then 1 else 0 end) as L2,
					(case when HS050=2 then 1 else 0 end) as L3,
					(case when HS060=2 then 1 else 0 end) as L4,
					(case when HS070=2 then 1 else 0 end) as L5,
					(case when HS080=2 then 1 else 0 end) as L6,
					(case when HS100=2 then 1 else 0 end) as L7,
					(case when HS110=2 then 1 else 0 end) as L8,
					(case when HH050=2 then 1 else 0 end) as L9

	from work.idb;

Create table work.nlack as 
	select distinct DB010, DB020, RB030, RB050a, Age, RB090, HS010, HS020, HS030, HS040, HS050, HS060, HS070,
					HS080, HS100, HS110, HH050, 
					L1, L2, L3, L4, L5, L6, L7, L8, L9,
					sum(L1, L2, L3, L4, L5, L6, L7, L8, L9) as totL,
					(case when calculated totL ge 3 then 1 else 0 end) as deprived
	from work.lack;
QUIT;

* calculate % missing values;

PROC SQL noprint;

CREATE TABLE nfilled AS SELECT DISTINCT DB020, (N(RB030)) AS N1 FROM work.idb WHERE RB090 not is missing GROUP BY DB020;
CREATE TABLE nmissing AS SELECT DISTINCT DB020, (N(RB030)) AS N_1 FROM work.idb WHERE RB090 is missing GROUP BY DB020;
CREATE TABLE mRB090 AS SELECT nfilled.DB020, (100/(N1+N_1)*N_1) AS mRB090 FROM nfilled LEFT JOIN nmissing ON (nfilled.DB020 = nmissing.DB020);

CREATE TABLE nfilled AS SELECT DISTINCT DB020, (N(RB030)) AS N1 FROM work.idb WHERE AGE not is missing GROUP BY DB020;
CREATE TABLE nmissing AS SELECT DISTINCT DB020, (N(RB030)) AS N_1 FROM work.idb WHERE AGE is missing GROUP BY DB020;
CREATE TABLE mAGE AS SELECT nfilled.DB020, (100/(N1+N_1)*N_1) AS mAGE FROM nfilled LEFT JOIN nmissing ON (nfilled.DB020 = nmissing.DB020);

create table work.mITEM as
 select distinct DB020,
(DEP_RELIABILITY*30) as mITEM  /*if DEP_RELIABILITY=1 then mITEM is like more than 20% missing (unreliable)
								 if DEP_RELIABILITY=2 then mITEM is like more than 50% missing (unreliable not to be published)*/		
 from work.IDB;

CREATE TABLE missunrel AS SELECT mRB090.DB020, 
	max(mRB090, mAGE, mITEM) AS pcmiss
	FROM mRB090 LEFT JOIN mAGE ON (mRB090.DB020 = mAGE.DB020)
				LEFT JOIN mITEM ON (mRB090.DB020 = mITEM.DB020);
QUIT;


* OV9b1 * calc values, N and total weights;

%let tab=OV9B1;

PROC TABULATE data=work.nlack out=Ti;
		FORMAT AGE f_agex.;
		FORMAT RB090 f_sex.;
		FORMAT totL f_n_item.;
		CLASS AGE /MLF;
		CLASS RB090 /MLF;
		CLASS totL /MLF;
		CLASS DB020;
	VAR RB050a ;
	TABLE DB020*  AGE * RB090, totL * RB050a * (RowPctSum N Sum) /printmiss;
RUN;

* fill RDB variables;

%macro by_unit(unit,ival); 

PROC SQL;
CREATE TABLE work.old_flag AS
SELECT distinct
      time,
      geo,
   	  sex,
	  unit,
	  n_item,
      iflag
FROM rdb.&tab
WHERE  time = &yyyy and unit="&unit" and geo ="&Ucc";

CREATE TABLE work.OV9b1 AS
SELECT 
	Ti.DB020 as geo FORMAT=$5. LENGTH=5,
	&yyyy as time,
	Ti.Age,
	Ti.RB090 as sex,
	"&unit" as unit,
	ti.totL as n_item,
	Ti.&ival as ivalue,
	old_flag.iflag as iflag,
	(case when sum(Ti.RB050a_N) < 20 or missunrel.pcmiss > 50 then 2
		  when sum(Ti.RB050a_N) < 50 or missunrel.pcmiss > 20 then 1
		  else 0
	      end) as unrel,
	Ti.RB050a_N as n,
	max(Ti.RB050a_N) as ntot,
	max(Ti.RB050a_Sum) as totwgh,
	"&sysdate" as lastup,
	"&sysuserid" as	lastuser 
FROM Ti LEFT JOIN missunrel ON (Ti.DB020 = missunrel.DB020)
LEFT JOIN work.old_flag ON (Ti.DB020 = old_flag.geo) 
	 AND (Ti.RB090 = old_flag.sex) and (ti.totL = old_flag.n_item) 
	and ("&unit"=old_flag.unit)
GROUP BY Ti.DB020, ti.AGE, ti.RB090
ORDER BY Ti.DB020, ti.AGE, ti.RB090, Ti.totL;
QUIT;

* Update RDB;  

DATA  rdb.OV9b1;
set rdb.OV9b1(where=(not(time = &yyyy and geo = "&Ucc" and unit = "&unit")))
    work.OV9b1; 
RUN;  

%mend by_unit;
	%by_unit(PC_POP,RB050a_PctSum_1101);
	%by_unit(THS_PER,RB050a_Sum/1000);


* OV9b2 * calc values, N and total weights;
%let tab=ov9b2;

PROC TABULATE data=work.nlack out=Ti;
	FORMAT AGE f_age15.;
	FORMAT RB090 f_sex.;
	CLASS AGE /MLF;
	CLASS RB090 /MLF;
	CLASS DB020;
	VAR totL;
	WEIGHT RB050a;
	TABLE DB020 * AGE * RB090, totL * (mean N Sumwgt) /printmiss;
	WHERE deprived;
RUN;

* fill RDB variables;

PROC SQL;
CREATE TABLE work.old_flag AS
SELECT distinct
      time,
      geo,
   	  sex,
	  unit,
	  iflag
FROM rdb.&tab
WHERE  time = &yyyy and unit="AVG" and geo ="&Ucc";

CREATE TABLE work.OV9b2 AS
SELECT 
	Ti.DB020 as geo FORMAT=$5. LENGTH=5,
	&yyyy as time,
	Ti.Age,
	Ti.RB090 as sex,
	"AVG" as unit,
	Ti.totL_Mean as ivalue,
	old_flag.iflag as iflag,
	(case when sum(Ti.totL_N) < 20 or missunrel.pcmiss > 50 then 2
		  when sum(Ti.totL_N) < 50 or missunrel.pcmiss > 20 then 1
		  else 0
	      end) as unrel,
	Ti.totL_N as n,
	sum(Ti.totL_N) as ntot,
	sum(Ti.totL_SumWgt) as totwgh,
	"&sysdate" as lastup,
	"&sysuserid" as	lastuser 
FROM Ti LEFT JOIN missunrel ON (Ti.DB020 = missunrel.DB020)
		LEFT JOIN work.old_flag ON (Ti.DB020 = old_flag.geo) 
	 		AND (Ti.RB090 = old_flag.sex) 
GROUP BY Ti.DB020, ti.AGE, ti.RB090;
QUIT;

*Update RDB;  

DATA  rdb.OV9b2;

set rdb.OV9b2(where=(not(time = &yyyy and geo = "&Ucc")))
    work.OV9b2; 
RUN;  

%end;

%if &EU %then %do;

* EU aggregates;

%let tab=OV9b1;
%let grpdim=age, sex, unit, n_item;
%EUVALS(&Ucc,&Uccs);

%let tab=OV9b2;
%let grpdim=age, sex, unit;
%EUVALS(&Ucc,&Uccs);

%end;

PROC SQL;  
     Insert into log.log
     set date = "&sysdate"d, time = "&systime"t, user = "&sysuserid",
		 report = "* &Ucc - &yyyy * ov9b1 (re)calculated *";		  
QUIT;
PROC SQL;  
     Insert into log.log
     set date = "&sysdate"d, time = "&systime"t, user = "&sysuserid",
		 report = "* &Ucc - &yyyy * ov9b2 (re)calculated *";		  
QUIT;


%mend UPD_OV9B;
