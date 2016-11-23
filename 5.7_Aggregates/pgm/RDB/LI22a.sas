*** At-risk-poverty-rate anchored at a fixed moment in time (2005), by age and gender ***;
*** changed age format 4 November 2010 ***;

%macro UPD_li22a(yyyy,Ucc,Uccs,flag) /store;

%if &yyyy > 2005
%then %do;

PROC DATASETS lib=work kill nolist;
QUIT;

%let cc=%lowcase(&Ucc);
%let yy=%substr(&yyyy,3,2);
%let EU=0;
%if &Uccs=0 %then %let Uccs=("&Ucc");
%else %let EU=1; 

PROC FORMAT;
    VALUE f_age (multilabel)
		0 - 17 = "Y_LT18"
		18 - 64 = "Y18-64"
		65 - HIGH = "Y_GE65"
		0 - HIGH = "TOTAL"
		;

	VALUE f_sex (multilabel)
		1 = "M"
		2 = "F"
		1 - 2 = "T";
RUN;

PROC SQL noprint;
Create table work.idb as 
	select db.DB010, db.DB020, DB030, RB030, RB050a,
			Age, RB090, EQ_INC20, &arpt2005 as ARPT60_2005, &idx2005 as idx2005,
		   (&arpt2005 * &idx2005 / 100) as ARPT60idx,
	       (case
		    when EQ_INC20 < calculated ARPT60idx then 1
			else 0
			end) as ARPT60ix
 	from idb.IDB&yy as db
	where age ge 0 and db.DB010 = &yyyy and db.DB020 in &Uccs;

Select distinct count(DB010) as N 
	into :nobs
	from  work.idb;
Create table work.li22 like rdb.li22; 
QUIT;

%if &nobs > 0
%then %do;

PROC TABULATE data=work.idb out=Ti0;
	FORMAT AGE f_age15.;
	FORMAT RB090 f_sex.;
	VAR RB050a;
	CLASS AGE /MLF;
	CLASS ARPT60ix;
	CLASS RB090 /MLF;
	TABLE ARPT60ix,  AGE * RB090 * (RB050a * (ColPctSum  N)) /printmiss;
RUN;
PROC SQL;
	Create table Ti as
	select *,
		sum(RB050a_N) as ntot
	from Ti0
	group by Age, RB090;
QUIT;

PROC TABULATE data=work.idb out=Tt;
	FORMAT AGE f_age9.;
	FORMAT RB090 f_sex.;
	VAR RB050a;
	CLASS AGE /MLF;
	CLASS RB090 /MLF;
	TABLE RB090, Age * (RB050a * (PctSum Sum));
RUN;

PROC TABULATE data=work.idb out=Tp;
	FORMAT AGE f_age9.;
	FORMAT RB090 f_sex.;
	VAR RB050a;
	CLASS AGE /MLF;
	CLASS RB090 /MLF;
	TABLE RB090, Age * (RB050a * (PctSum Sum));
	WHERE ARPT60ix = 1;
RUN;

PROC SQL;
INSERT INTO li22 SELECT 
	"&Ucc" as geo,
	&yyyy as time,
	Ti.Age,
	Ti.RB090 as sex,
	Ti.RB050a_PctSum_101 as ivalue,
	"&flag" as iflag,
	(case when ntot < 20 then 2
		  when ntot < 50 then 1
		  else 0
	      end) as unrel,
	Ti.RB050a_N as n,
	ntot,
	Tt.RB050a_PctSum_00 as totpop,
	Tp.RB050a_PctSum_00 as poorpop,
	Tt.RB050a_Sum as totwgh,
	Tp.RB050a_Sum as poorwgh,
	"&sysdate" as lastup,
	"&sysuserid" as	lastuser 
FROM Ti LEFT JOIN Tt ON (Ti.RB090 = Tt.RB090) AND (Ti.Age = Tt.Age) 
	    LEFT JOIN Tp ON (Ti.RB090 = Tp.RB090) AND (Ti.Age = Tp.Age)
WHERE ARPT60ix=1;
QUIT;

* Update RDB;
DATA  rdb.li22;
set rdb.li22(where=(not(time = &yyyy and geo = "&Ucc")))
    work.li22; 
run;

PROC SQL;  
     Insert into log.log
     set date = "&sysdate"d, time = "&systime"t, user = "&sysuserid",
		 report = "* &Ucc - &yyyy * li22 (re)calculated *";		  
QUIT;

%end;
%else %do; 
PROC SQL;  
     Insert into log.log
     set date = "&sysdate"d, time = "&systime"t, user = "&sysuserid",
		 report = "* &Ucc - &yyyy * NO DATA !";		  
QUIT;
%end;
%end;

%else %do; 
PROC SQL;  
     Insert into log.log
     set date = "&sysdate"d, time = "&systime"t, user = "&sysuserid",
		 report = "* &Ucc - &yyyy * NO li22 CALCULATION before 2006!";		  
QUIT;
%end;

%mend;
