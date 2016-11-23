
%macro UPD_peps01 (yyyy,Ucc,Uccs,flag,notBDB);
/*** Differencies of People at risk of poverty (unit=THS_PER)  between current year and 2008 (peps01a)*/
PROC DATASETS lib=work kill nolist;
QUIT;
%let cc=%lowcase(&Ucc);
%let yy=%substr(&yyyy,3,2);
%let EU=0;
%if &Uccs=0 %then %let Uccs=("&Ucc");
%else %let EU=1;



%let tab=peps01;

%let not60=0;

%if &EU=0 %then %do;

PROC FORMAT; /* change the age codes with new ones and proper for that table*/
VALUE f_age (multilabel)
		0 - 5 = "Y_LT6"
		/*  added */
		6 - 11 = "Y6-11"
		12 - 17 = "Y12-17"	
		0 - 17 = "Y_LT18"	
		/* end */
		6 - 10 = "Y6-10"
		0 - 15 = "Y_LT16"
		11 - 15 = "Y11-15"
		16 - HIGH = "Y_GE16"
		0 - 17 = "Y_LT18"
		18 - HIGH = "Y_GE18"
		16 - 24 = "Y16-24"
		18 - 24 = "Y18-24"
		25 - 49 = "Y25-49"
		25 - 54 = "Y25-54"
		0 - 59 = "Y_LT60"
		60 - HIGH = "Y_GE60"
		0 - 64 = "Y_LT65"
		16 - 64 = "Y16-64"
		18 - 64 = "Y18-64"
		50 - 64 = "Y50-64"
		55 - 64 = "Y55-64"
		55 - HIGH = "Y_GE55"
		65 - HIGH = "Y_GE65"
		65 - 74 = "Y65-74"
		0 - 74 = "Y_LT75"
		75 - HIGH = "Y_GE75"
		0 - HIGH = "TOTAL";

VALUE f_sex (multilabel)
		1 = "M"
		2 = "F"
		1 - 2 = "T";

VALUE $f_AROPE (multilabel)
	"000" ="0"
	OTHER = "1";

RUN;


%macro any_year (any_year,unit); /* macro to calculate the peps01a indicators */
%if &yyyy <2008 %then  %goto exit;
%else %do;
	  %if (&Ucc =MK or &Ucc =HR)  %then %do;
		       %if &yyyy > 2010 %then %do;
	      		%let any_year =2010;
          		%let any_yr =%substr(&any_year,3,2);
	  	   %end;
	  	  %else %goto exit;
	  %end;
	  %else %do;
		  %let any_year =2008;
          %let any_yr =%substr(&any_year,3,2);
	  %end;
Proc sql;
Create Table work.idx as select DISTINCT
		idx.*
		from RDB.peps01 as idx
		where idx.GEO in &Uccs  and idx.time=&any_year   and idx.age = 'TOTAL' and idx.sex = 'T' and idx.unit ='THS_PER';
quit;

proc sql;
    Select distinct count(geo) as N 
	into :nobs
	from  work.idx;
QUIT;
		%if &nobs > 0 %then %do;	

PROC SQL;

CREATE TABLE work.old_flag AS SELECT
	geo,
	time, 
	unit,
	ivalue,
	iflag
FROM rdb.peps01 
WHERE geo in &Uccs   and time = &yyyy and unit = "&unit";
quit;
        data test;
           set RDB.peps01 (where=(time = &yyyy and geo in &Uccs  and unit = "THS_PER" and age='TOTAL' and sex='T'));
		run;
        proc sql;
		Create table work.peps01 as select
					idb.geo,
					&yyyy as time,
					"TOTAL" as Age,
					"T" as sex,
					"&unit" as unit format=$12. length=12,
					idb.ivalue - idx.ivalue as ivalue,
	                old_flag.iflag  as iflag,
	                0 as unrel,
				abs(idb.n-idx.n) as n,
				abs(idb.ntot-idx.ntot) as ntot,
				abs(idb.totwgh-idx.totwgh) as totwgh,
				"&sysdate" as lastup,
				"&sysuserid" as	lastuser 
		 	from test  as idb left join work.idx as idx on (idb.geo = idx.geo) 
            LEFT JOIN work.old_flag ON (idb.geo = old_flag.geo) ;
	   		QUIT;
DATA  rdb.peps01;
set rdb.peps01(where=(not(time = &yyyy and geo = "&Ucc" and unit = "&unit" )))
    work.peps01;
	
RUN;
		%end;
%end;
%exit: %mend any_year;
* fill RDB variables;
%macro by_unit(unit,ival); 
PROC SQL;

CREATE TABLE work.old_flag AS SELECT
	geo,
	time, 
	age,
	sex,
	unit,
	ivalue,
	iflag
FROM rdb.peps01
WHERE geo in &Uccs and unit ="&unit" and time = &yyyy;



CREATE TABLE work.peps01 AS
SELECT 
	Ti.DB020 as geo FORMAT=$5. LENGTH=5,
	&yyyy as time,
	Ti.Age,
	Ti.RB090 as sex,
	Ti.AROPE,
	"&unit" as unit format=$12. length=12,
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
	LEFT JOIN work.old_flag ON (Ti.DB020=old_flag.geo) AND (Ti.Age=old_flag.age) AND ( Ti.RB090 = old_flag.sex) 
GROUP BY Ti.DB020, ti.AGE, ti.RB090
ORDER BY Ti.DB020, ti.AGE, ti.RB090;
QUIT;

* Update RDB;
DATA  rdb.peps01 (drop= AROPE);
set rdb.peps01(where=(not(time = &yyyy and geo = "&Ucc" and unit = "&unit")))
    work.peps01;
	where AROPE="1";
RUN;
%mend by_unit;

/*%if &tab=peps01 %then %do;*/
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
		FORMAT AROPE $f_AROPE.;
		CLASS AGE /MLF;
		CLASS RB090 /MLF;
		CLASS AROPE /MLF;
		CLASS DB020;
	VAR RB050a;

	TABLE DB020 * AGE * RB090, AROPE * RB050a * (RowPctSum N Sum) /printmiss;

RUN;

	%by_unit(PC_POP,RB050a_PctSum_1101);
	%by_unit(THS_PER,RB050a_Sum/1000);

/*%end;*/

%any_year(2008,THS_CD08);

%end;  /* end country calculation */

%if &EU %then %do;

* EU aggregates;
 
%let tab=peps01;
%let grpdim=age, sex, unit;
%EUVALS(&Ucc,&Uccs);  
/*
%let tab=peps18;
%let grpdim= unit;
%EUVALS(&Ucc,&Uccs); */
%end;

%if &yyyy > 2007 %then %do;
PROC SQL;  
     Insert into log.log
     set date = "&sysdate"d, time = "&systime"t, user = "&sysuserid",
		 report = "* &Ucc - &yyyy * peps01 (re)calculated *";		  
QUIT;
PROC SQL;  
     Insert into log.log
     set date = "&sysdate"d, time = "&systime"t, user = "&sysuserid",
		 report = "* &Ucc - &yyyy * peps01a (re)calculated *";		  
QUIT;
%end;
%else %do;
PROC SQL;  
     Insert into log.log
     set date = "&sysdate"d, time = "&systime"t, user = "&sysuserid",
		 report = "* &Ucc - &yyyy * peps01 (re)calculated *";		  
QUIT;
%end;

%mend UPD_peps01;
