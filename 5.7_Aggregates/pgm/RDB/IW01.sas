
*** IN-WORK At-risk-poverty-rate by age and gender ***;

%macro UPD_iw01(yyyy,Ucc,Uccs,flag) /store;
/* flags are taken from the existing data set  on 7/12/2010 */
/* 22/12/2010 modified to eliminate AGE variable from the old_flag dataset   */
/* consistent AGE format already existed with the changed format for the flags*/
/* 20120111MG applyed new ACTSTA definition */
/* 20120120MG applyed mEUvals to calcultion aggregates */
PROC DATASETS lib=work kill nolist;
QUIT;
%let tab=IW01;
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
		65 - HIGH = "Y_GE65"
		18 - 24 = "Y18-24"
		25 - 54 = "Y25-54"
		55 - 64 = "Y55-64";

	VALUE f_sex (multilabel)
		1 = "M"
		2 = "F"
		1 - 2 = "T";

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
			Age, RB090, EQ_INC20, EQ_INC20eur, ACTSTA  
	from idb.IDB&yy
      where ACTSTA in(1,2,3,4) and PB040 > 0 and 
			age ge 18 and DB010 = &yyyy and DB020 in &Uccs;
Select distinct count(DB010) as N 
	into :nobs
	from  work.idb;
Create table work.iw01 like rdb.iw01; 
QUIT;

%if &nobs > 0
%then %do;

%if &EU=0 %then %do;

	%let arpt=ARPT60i;
	%let libel=LI_R_MD60;
	PROC TABULATE data=work.idb out=Ti0;
		FORMAT AGE f_age15.;
		FORMAT RB090 f_sex.;
		FORMAT ACTSTA f_act15.;
		VAR PB040;
		CLASS AGE /MLF;
		CLASS &arpt;
		CLASS RB090 /MLF;
		CLASS ACTSTA /MLF;
		TABLE &arpt,  AGE * RB090 * ACTSTA * (PB040 * (ColPctSum  N)) /printmiss;
	RUN;
	PROC SQL;
		Create table Ti as
		select *,
			sum(PB040_N) as ntot
		from Ti0
		group by Age, RB090, ACTSTA;
	QUIT;

	PROC TABULATE data=work.idb out=Tt;
		FORMAT AGE f_age9.;
		FORMAT RB090 f_sex.;
		FORMAT ACTSTA f_act15.;
		VAR PB040;
		CLASS AGE /MLF;
		CLASS RB090 /MLF;
		CLASS ACTSTA /MLF;
		TABLE RB090 * ACTSTA, Age * (PB040 * (PctSum Sum));
	RUN;

	PROC TABULATE data=work.idb out=Tp;
		FORMAT AGE f_age9.;
		FORMAT RB090 f_sex.;
		FORMAT ACTSTA f_act15.;
		VAR PB040;
		CLASS AGE /MLF;
		CLASS RB090 /MLF;
		CLASS ACTSTA /MLF;
		TABLE RB090 * ACTSTA, Age * (PB040 * (PctSum Sum));
		WHERE &arpt = 1;
	RUN;

	PROC SQL;
	CREATE TABLE work.old_flag AS
SELECT distinct
      time,
      geo,
	  sex,
	  wstatus,
	  iflag
FROM rdb.&tab
WHERE  time = &yyyy  and geo ="&Ucc";
	INSERT INTO iw01 SELECT 
		"&Ucc" as geo,
		&yyyy as time,
		Ti.Age,
		Ti.RB090 as sex,
		Ti.ACTSTA as wstatus,
		"PC_POP" as unit,
		Ti.PB040_PctSum_1011 as ivalue,
		old_flag.iflag as iflag, 
        
		(case when ntot < 20 then 2
			  when ntot < 50 then 1
			  else 0
		      end) as unrel,
		Ti.PB040_N as n,
		ntot,
		Tt.PB040_PctSum_000 as totpop,
		Tp.PB040_PctSum_000 as poorpop,
		Tt.PB040_Sum as totwgh,
		Tp.PB040_Sum as poorwgh,
		"&sysdate" as lastup,
		"&sysuserid" as	lastuser 
	FROM Ti LEFT JOIN Tt ON (Ti.RB090 = Tt.RB090) AND (Ti.Age = Tt.Age) AND (Ti.ACTSTA = Tt.ACTSTA)
		    LEFT JOIN Tp ON (Ti.RB090 = Tp.RB090) AND (Ti.Age = Tp.Age) AND (Ti.ACTSTA = Tp.ACTSTA)
			left JOIN work.old_flag ON (Ti.RB090  = old_flag.sex) AND (Ti.ACTSTA = old_flag.wstatus) 
	WHERE &arpt=1;
	QUIT;


* Update RDB;   
 
DATA  rdb.IW01;
set rdb.IW01(where=(not(time = &yyyy and geo = "&Ucc")))
    work.iw01; 
run; 
%end; 
%if &EU %then %do;
 
	* EU aggregates;
	
	%let grpdim=age,sex ,wstatus,unit;
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
			report = "* &Ucc - &yyyy * iw01 (re)calculated *";		  
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

%mend UPD_iw01;
