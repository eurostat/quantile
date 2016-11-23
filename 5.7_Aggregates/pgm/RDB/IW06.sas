*** IN-WORK At-risk-poverty-rate by months worked ***;
/*20110627BB change ACTSTA in IDB in order to add SAL and NSAL breakdowns
update format accordingly in indicators*/
/* 20120111MG applid new ACTSTA definition */
/* 20120120MG applyed mEUvals to calcultion aggregates */
/*20120404BB change values for ACTSTA according to new ACTSTA categories*/
%macro UPD_iw06(yyyy,Ucc,Uccs,flag) /store;

PROC DATASETS lib=work kill nolist;
QUIT;
%let tab=iw06;
%let cc=%lowcase(&Ucc);
%let yy=%substr(&yyyy,3,2);
%let EU=0;
%let euok=0;
%if &Uccs=0 %then %let Uccs=("&Ucc");
%else %let EU=1; 

PROC FORMAT;

	VALUE f_wrk (multilabel)
		12 = "Y1"
		other = "Y_LT1";

RUN;
%if &yyyy <2009 %then %do;
PROC SQL noprint;
Create table work.idb as 
	select DB010, DB020, DB030, RB030, PB040, ARPT60i, EQ_INC20, 
			EQ_INC20eur, 
			sum(PL070,PL072,0) as WRK   
	from idb.IDB&yy
	where ACTSTA in(1,2,3,4) and PB040 > 0 and 
	 calculated WRK > 0 and DB010 = &yyyy and DB020 in &Uccs;
	 quit;
%end;
%else %do;
PROC SQL noprint;
Create table work.idb as 
	select DB010, DB020, DB030, RB030, PB040, ARPT60i, EQ_INC20, 
			EQ_INC20eur, 
			sum(PL073,PL074,PL075,PL076,0) as WRK
	from idb.IDB&yy
	where ACTSTA in(1,2,3,4) and PB040 > 0 and age ge 18 and 
	calculated WRK > 0 and DB010 = &yyyy and DB020 in &Uccs;
	quit;
%end;
	
proc sql;
Select distinct count(DB010) as N 
	into :nobs
	from  work.idb;
Create table work.iw06 like rdb.iw06; 
QUIT;

%if &nobs > 0
%then %do;
proc sql;
CREATE TABLE work.old_flag AS
SELECT distinct
      time,
      geo,
	  duration,
	  ivalue,
	  iflag
FROM rdb.&tab
WHERE  time = &yyyy and geo="&Ucc" ;	
quit;

%if &EU=0 %then %do;
	%let arpt=ARPT60i;
	%let libel=LI_R_MD60;

	PROC TABULATE data=work.idb out=Ti0;
		FORMAT wrk f_wrk.;
		VAR PB040;
		CLASS &arpt;
		CLASS wrk /MLF;
		TABLE &arpt,  wrk * (PB040 * (ColPctSum  N)) /printmiss;
	RUN;
	PROC SQL;
		Create table Ti as
		select *,
			sum(PB040_N) as ntot
		from Ti0
		group by wrk;
	QUIT;

	PROC TABULATE data=work.idb out=Tt;
		FORMAT wrk f_wrk.;
		VAR PB040;
		CLASS wrk /MLF;
		TABLE wrk, (PB040 * (PctSum Sum));
	RUN;

	PROC TABULATE data=work.idb out=Tp;
		FORMAT wrk f_wrk.;
		VAR PB040;
		CLASS wrk /MLF;
		TABLE wrk, (PB040 * (PctSum Sum));
		WHERE &arpt = 1;
	RUN;

	PROC SQL;
	INSERT INTO iw06 SELECT 
		"&Ucc" as geo,
		&yyyy as time,
		Ti.wrk as duration,
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
	FROM Ti LEFT JOIN Tt ON (Ti.wrk = Tt.wrk) 
		    LEFT JOIN Tp ON (Ti.wrk = Tp.wrk) 
			left JOIN work.old_flag ON ("&Ucc" = old_flag.geo) and (Tp.wrk= old_flag.duration)
	WHERE &arpt=1;
QUIT;



* Update RDB;
DATA  rdb.iw06;
set rdb.iw06(where=(not(time = &yyyy and geo = "&Ucc")))
    work.iw06; 
run;
%end; 
%if &EU %then %do;

	* EU aggregates;
	%let grpdim=duration,unit;
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
			report = "* &Ucc - &yyyy * iw06 (re)calculated *";		  
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
%mend UPD_iw06;
