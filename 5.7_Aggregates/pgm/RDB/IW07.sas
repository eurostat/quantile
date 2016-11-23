*** IN-WORK At-risk-poverty-rate by by hours worked ***;
/*20110627BB change ACTSTA in IDB in order to add SAL and NSAL breakdowns
update format accordingly in indicators*/
/* 20120111MG applid new ACTSTA definition */
/* 20120120MG applyed mEUvals to calcultion aggregates */
/*20120404BB change values for ACTSTA according to new ACTSTA categories*/
%macro UPD_iw07(yyyy,Ucc,Uccs,flag) /store;
/*change_09*/

PROC DATASETS lib=work kill nolist;
QUIT;
%let tab=iw07;
%let cc=%lowcase(&Ucc);
%let yy=%substr(&yyyy,3,2);
%let EU=0;
%let euok=0;
%if &Uccs=0 %then %let Uccs=("&Ucc");
%else %let EU=1; 

PROC FORMAT;
	VALUE f_hrs (multilabel)
		1 = "FT"
		2 = "PT";
RUN;

PROC SQL noprint;
Create table work.idb as 
	select DB010, DB020, DB030, RB030, PB040, ARPT60i, PL31, EQ_INC20, 
			EQ_INC20eur   
	from idb.IDB&yy
	where ACTSTA in(1,2,3,4) and PB040 > 0 and age ge 18 and 
		 PL31 in (1,2) and DB010 = &yyyy and DB020 in &Uccs;
Select distinct count(DB010) as N 
	into :nobs
	from  work.idb;
Create table work.iw07 like rdb.iw07; 
QUIT;

%if &nobs > 0

%then %do;
%if &EU=0 %then %do;
	%let arpt=ARPT60i;
	%let libel=LI_R_MD60;

	PROC TABULATE data=work.idb out=Ti0;
		FORMAT PL31 f_hrs.;
		VAR PB040;
		CLASS &arpt;
		CLASS PL31 /MLF;
		TABLE &arpt,  PL31 * (PB040 * (ColPctSum  N)) /printmiss;
	RUN;

	PROC SQL;
		Create table Ti as
		select *,
			sum(PB040_N) as ntot
		from Ti0
		group by PL31;
	QUIT;

	PROC TABULATE data=work.idb out=Tt;
		FORMAT PL31 f_hrs.;
		VAR PB040;
		CLASS PL31 /MLF;
		TABLE PL31, (PB040 * (PctSum Sum));
	RUN;

	PROC TABULATE data=work.idb out=Tp;
		FORMAT PL31 f_hrs.;
		VAR PB040;
		CLASS PL31 /MLF;
		TABLE PL31, (PB040 * (PctSum Sum));
		WHERE &arpt = 1;
	RUN;

	PROC SQL;
CREATE TABLE work.old_flag AS
SELECT 
      time,
      geo,
	  worktime,
	  iflag
FROM rdb.iw07
WHERE  time = &yyyy   and geo ="&Ucc";

	INSERT INTO iw07 SELECT 
		"&Ucc" as geo,
		&yyyy as time,
		Ti.PL31 as worktime,
		"PC_POP" as unit,
		Ti.PB040_PctSum_01 as ivalue,
		old_flag.iflag as iflag,
		(case when ntot < 20 then 2
			  when ntot < 50 then 1
			  else 0
		      end) as unrel,
		Ti.PB040_N as n,
		ntot,
		Tt.PB040_PctSum_0 as totpop,
		Tp.PB040_PctSum_0 as poorpop,
		Tt.PB040_Sum as totwgh,
		Tp.PB040_Sum as poorwgh,
		"&sysdate" as lastup,
		"&sysuserid" as	lastuser 
	FROM Ti LEFT JOIN Tt ON (Ti.PL31 = Tt.PL31) 
		    LEFT JOIN Tp ON (Ti.PL31 = Tp.PL31) 
			left JOIN work.old_flag ON  (Tp.PL31 = old_flag.worktime)  
	WHERE &arpt=1;
	QUIT;

* Update RDB;

DATA  rdb.iw07;
set rdb.iw07(where=(not(time = &yyyy and geo = "&Ucc")))
    work.iw07; 
run;
%end; 
%if &EU %then %do;
 
	* EU aggregates;

	%let grpdim=worktime,unit;
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
			report = "* &Ucc - &yyyy * iw07 (re)calculated *";		  
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

%mend UPD_iw07;
