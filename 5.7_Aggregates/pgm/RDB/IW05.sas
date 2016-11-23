*** IN-WORK At-risk-poverty-rate by type of contract ***;
/*20110627BB change ACTSTA in IDB in order to add SAL and NSAL breakdowns
update format accordingly in indicators*/
/*20110713BG adding dimensions SEX*/
/* 20120120MG applyed new ACTSTA definition */
/* 20120120MG applyed mEUvals to calcultion aggregates */
/*20120404BB change values for ACTSTA according to new ACTSTA categories*/

%macro UPD_iw05(yyyy,Ucc,Uccs,flag) /store;

PROC DATASETS lib=work kill nolist;
QUIT;
%let tab=iw05;
%let cc=%lowcase(&Ucc);
%let yy=%substr(&yyyy,3,2);
%let EU=0;
%let euok=0;
%if &Uccs=0 %then %let Uccs=("&Ucc");
%else %let EU=1; 

PROC FORMAT;

	VALUE f_contr (multilabel)
		1 = "SAL_PERM"
		2 = "SAL_TEMP";

	VALUE f_sex (multilabel)
		1 = "M"
		2 = "F"
		1 - 2 = "T";

RUN;

PROC SQL noprint;
Create table work.idb as 
	select DB010, DB020, DB030, RB030, RES_WGT, RB090, ARPT60i, PL140, EQ_INC20, 
			EQ_INC20eur   
	from idb.IDB&yy
	where ACTSTA in(1,2,3,4) and RES_WGT > 0 and age ge 18 and 
		 PL140 in (1,2) and DB010 = &yyyy and DB020 in &Uccs;
Select distinct count(DB010) as N 
	into :nobs
	from  work.idb;
Create table work.iw05 like rdb.iw05; 
QUIT;

%if &nobs > 0
%then %do;
proc sql;
CREATE TABLE work.old_flag AS
SELECT distinct
      time,
      geo,
	  wstatus,
	  sex,
	  ivalue,
	  iflag
FROM rdb.&tab
WHERE  time = &yyyy and geo="&Ucc" ;	
quit;
%if &EU=0 %then %do;

	%let arpt=ARPT60i;
	%let libel=LI_R_MD60;

	PROC TABULATE data=work.idb out=Ti0;
		FORMAT PL140 f_contr.;
		Format RB090 f_sex.;
		VAR RES_WGT;
		CLASS &arpt;
		CLASS PL140 /MLF;
		CLASS RB090 /MLF;
		TABLE &arpt,  PL140 * RB090 * (RES_WGT * (ColPctSum  N)) /printmiss;
	RUN;
	PROC SQL;
		Create table Ti as
		select *,
			sum(RES_WGT_N) as ntot
		from Ti0
		group by PL140, RB090;
	QUIT;

	PROC TABULATE data=work.idb out=Tt;
		FORMAT PL140 f_contr.;
		Format RB090 f_sex.;
		VAR RES_WGT;
		CLASS PL140 /MLF;
		CLASS RB090 /MLF;
		TABLE PL140 * RB090, (RES_WGT * (PctSum Sum));
	RUN;

	PROC TABULATE data=work.idb out=Tp;
		FORMAT PL140 f_contr.;
		Format RB090 f_sex.;
		VAR RES_WGT;
		CLASS PL140 /MLF;
		CLASS RB090 /MLF;
		TABLE PL140 * RB090, (RES_WGT * (PctSum Sum));
		WHERE &arpt = 1;
	RUN;

	PROC SQL;
	INSERT INTO iw05 SELECT 
		"&Ucc" as geo,
		&yyyy as time,
		Ti.PL140 as wstatus,
		Ti.RB090 as sex,
		"PC_POP" as unit,
		Ti.RES_WGT_PctSum_011 as ivalue,
		old_flag.iflag as iflag,
		(case when ntot < 20 then 2
			  when ntot < 50 then 1
			  else 0
		      end) as unrel,
		Ti.RES_WGT_N as n,
		ntot,
		Tt.RES_WGT_PctSum_00 as totpop,
		Tp.RES_WGT_PctSum_00 as poorpop,
		Tt.RES_WGT_Sum as totwgh,
		Tp.RES_WGT_Sum as poorwgh,
		"&sysdate" as lastup,
		"&sysuserid" as	lastuser 
	FROM Ti LEFT JOIN Tt ON (Ti.PL140 = Tt.PL140) AND (Ti.RB090 = Tt.RB090)
		    LEFT JOIN Tp ON (Ti.PL140 = Tp.PL140) AND (Ti.RB090 = Tp.RB090)
			left JOIN work.old_flag ON ("&Ucc" = old_flag.geo) and (Ti.PL140 = old_flag.wstatus)
		    AND (Ti.RB090 = old_flag.sex)   	
	WHERE &arpt=1;
QUIT;

* Update RDB;
DATA  rdb.iw05;
set rdb.iw05(where=(not(time = &yyyy and geo = "&Ucc")))
    work.iw05; 
run;
%end; 
%if &EU %then %do;
	* EU aggregates;
	%let grpdim=wstatus,sex,unit;
	%EUVALS(&Ucc,&Uccs);
%end;

	%if &euok = 0 and &EU %then %do;
		PROC SQL;  
		Insert into log.log
		set date = "&sysdate"d, time = "&systime"t, user = "&sysuserid",
			report = "* &Ucc - &yyyy * NO enought countries available! ";		  
		QUIT;
		%end;
	%if &euok = 1 and &EU %then %do;
		PROC SQL;  
		Insert into log.log
		set date = "&sysdate"d, time = "&systime"t, user = "&sysuserid",
			report = "* &Ucc - &yyyy * iw05 (re)calculated *";		  
		QUIT;
	%end;
	%if &euok = 0 and &EU=0 %then %do;
		PROC SQL;  
		Insert into log.log
		set date = "&sysdate"d, time = "&systime"t, user = "&sysuserid",
			report = "* &Ucc - &yyyy * iw05 (re)calculated *";		  
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

%mend UPD_iw05;
