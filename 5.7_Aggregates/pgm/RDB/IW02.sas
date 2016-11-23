*** IN-WORK At-risk-poverty-rate by household type ***;
/*20110627BB change ACTSTA in IDB in order to add SAL and NSAL breakdowns
update format accordingly in indicators*/
/* 20120120MG applyed new ACTSTA definition */
/* 20120120MG applyed mEUvals to calcultion aggregates */
/*20120404BB change values for ACTSTA according to new ACTSTA categories*/
%macro UPD_iw02(yyyy,Ucc,Uccs,flag) /store;

PROC DATASETS lib=work kill nolist;
QUIT;
	%let tab=iw02;
%let cc=%lowcase(&Ucc);
%let yy=%substr(&yyyy,3,2);
%let EU=0;
%if &Uccs=0 %then %let Uccs=("&Ucc");
%else %let EU=1; 

PROC FORMAT;
     VALUE f_ht (multilabel max=45)
		5 - 8 = "HH_NDCH"
		5 =	 "A1" 
		6 - 8 =	 "A_GE2_NDCH"
		9 - 13 = "HH_DCH"
		9 =	 "A1_DCH"
		10 - 13 = "A_GE2_DCH";
RUN;
PROC SQL noprint;
Create table work.idb as 
	select DB010, DB020, DB030, RB030, PB040, ARPT60i, HT, EQ_INC20, 
			EQ_INC20eur   
	from idb.IDB&yy
	where ACTSTA in(1,2,3,4) and PB040 > 0 and age ge 18 and 
			HT between 5 and 13 and DB010 = &yyyy and DB020 in &Uccs;

Select distinct count(DB010) as N 
	into :nobs
	from  work.idb;
Create table work.iw02 like rdb.iw02; 
QUIT;

%if &nobs > 0
%then %do;


proc sql;
CREATE TABLE work.old_flag AS
SELECT distinct
      time,
      geo,
	  hhtyp,
	  ivalue,
	  iflag
FROM rdb.&tab
WHERE  time = &yyyy and geo="&Ucc" ;	
quit;

%if &EU=0 %then %do;

	%let arpt=ARPT60i;
	%let libel=LI_R_MD60;

	PROC TABULATE data=work.idb out=Ti0;
		FORMAT HT f_ht45.;
		VAR PB040;
		CLASS HT /MLF;
		CLASS &arpt;
		TABLE &arpt, HT * (PB040 * (ColPctSum  N)) /printmiss;
	RUN;
	PROC SQL;
		Create table Ti as
		select *,
			sum(PB040_N) as ntot
		from Ti0
		group by HT;
	QUIT;

	PROC TABULATE data=work.idb out=Tt;
		FORMAT HT f_ht45.;
		VAR PB040;
		CLASS HT /MLF;
		TABLE HT, (PB040 * (PctSum Sum));
	RUN;

	PROC TABULATE data=work.idb out=Tp;
		FORMAT HT f_ht45.;
		VAR PB040;
		CLASS HT /MLF;
		TABLE HT, (PB040 * (PctSum Sum));
		WHERE &arpt = 1;
	RUN;

	PROC SQL;
	INSERT INTO iw02 SELECT 
		"&Ucc" as geo,
		&yyyy as time,
		Ti.HT as hhtyp,
		"PC_POP" as unit,
		Ti.PB040_PctSum_10 as ivalue,
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
	FROM Ti LEFT JOIN Tt ON (Ti.HT = Tt.HT) 
		    LEFT JOIN Tp ON (Ti.HT = Tp.HT) 
			left JOIN work.old_flag ON ("&Ucc" = old_flag.geo) and (Ti.HT = old_flag.hhtyp)
		  	WHERE &arpt=1;
	QUIT;


 
* Update RDB;
DATA  rdb.IW02;
set rdb.IW02(where=(not(time = &yyyy and geo = "&Ucc")))
    work.iw02; 
run; 
%end; 
%if &EU %then %do;
	* EU aggregates;

	%let tab=iw02;
	%let grpdim=hhtyp,unit;
	%EUVALS(&Ucc,&Uccs);
%end;

	%if &euok = 0 and &EU %then %do;
		PROC SQL;  
		Insert into log.log
		set date = "&sysdate"d, time = "&systime"t, user = "&sysuserid",
			report = "* &Ucc - &yyyy * NO enought countries available! ! ";		  
		QUIT;
		%end;
		%else %do;
		PROC SQL;  
		Insert into log.log
		set date = "&sysdate"d, time = "&systime"t, user = "&sysuserid",
			report = "* &Ucc - &yyyy * iw02 (re)calculated *";		  
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

%mend UPD_iw02;
