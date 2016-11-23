*** IN-WORK At-risk-poverty-rate by work intensity of the household ***;
/*20110627BB change ACTSTA in IDB in order to add SAL and NSAL breakdowns
update format accordingly in indicators*/
/* 20120120MG applied new ACTSTA definition */
/* 20120120MG applied mEUvals to calcultion aggregates */
/* 20122601MG intoduced new low working intensuty definition */
/*20120404BB change values for ACTSTA according to new ACTSTA categories*/
%macro UPD_iw03(yyyy,Ucc,Uccs,flag) /store;

PROC DATASETS lib=work kill nolist;
QUIT;
%let tab=iw03;
%let cc=%lowcase(&Ucc);
%let yy=%substr(&yyyy,3,2);
%let EU=0;
%if &Uccs=0 %then %let Uccs=("&Ucc");
%else %let EU=1; 

PROC FORMAT;
   VALUE f_work_int (multilabel )
	  0 - 0.2 ="VLOW"
	  0.2 < - 1 ="NVLOW" 
      0.2 < - < 0.45 ="LOW"  
      0.45 - 0.55="MED"                   
      0.55 <- 0.85="HIGH" 
      0.85 <-  1="VHIGH"  
      99="other";


	VALUE f_chld(multilabel)
		0 = "HH_NDCH"
		1-high = "HH_DCH"
		low - high = "TOTAL";

RUN;

PROC SQL noprint;
Create table work.idb as 
	select DB010, DB020, DB030, RB030,  PB040, ARPT60i,  N_DCH as CHLD, WORK_INT, EQ_INC20, 
			EQ_INC20eur   
	from idb.IDB&yy
	where 18 <= age <= 59 and ACTSTA in(1,2,3,4) and PB040 > 0 and 
			 DB010 = &yyyy and DB020 in &Uccs;
Select distinct count(DB010) as N 
	into :nobs
	from  work.idb;
Create table work.iw03 like rdb.iw03; 
QUIT;

%if &nobs > 0
%then %do;
proc sql;
CREATE TABLE work.old_flag AS
SELECT distinct
      time,
      geo,
	  hhtyp,
	  workint,
	  ivalue,
	  iflag
FROM rdb.&tab
WHERE  time = &yyyy and geo="&Ucc" ;	
quit;

%if &EU=0 %then %do;
	%let arpt=ARPT60i;
	%let libel=LI_R_MD60;

	PROC TABULATE data=work.idb out=Ti0;
		FORMAT WORK_INT f_work_int15.;
		FORMAT CHLD f_chld15.;
		VAR PB040;
		CLASS WORK_INT /MLF;
		CLASS &arpt;
		CLASS CHLD /MLF;
		TABLE &arpt,  WORK_INT  *  CHLD *(PB040 * (ColPctSum  N)) /printmiss;
	RUN;
	PROC SQL;
		Create table Ti as
		select *,
			sum(PB040_N) as ntot
		from Ti0
		group by WORK_INT, CHLD;
	QUIT;

	PROC TABULATE data=work.idb out=Tt;
		FORMAT WORK_INT f_work_int15.;
	FORMAT CHLD f_chld15.;
		VAR PB040;
		CLASS WORK_INT /MLF;
	CLASS CHLD /MLF;
		TABLE  CHLD *WORK_INT, (PB040 * (PctSum Sum));
	RUN;

	PROC TABULATE data=work.idb out=Tp;
		FORMAT WORK_INT f_work_int15.;
		FORMAT CHLD f_chld15.;
		VAR PB040;
		CLASS WORK_INT /MLF;
	CLASS CHLD /MLF;
		TABLE CHLD* WORK_INT, (PB040 * (PctSum Sum));
		WHERE &arpt = 1;
	RUN;

	PROC SQL;
	INSERT INTO iw03 SELECT 
		"&Ucc" as geo,
		&yyyy as time,
		Ti.CHLD as hhtyp,
		Ti.WORK_INT as workint,
		"PC_POP" as unit,
		Ti.PB040_PctSum_101 as ivalue,
		old_flag.iflag as iflag,
		(case when ntot < 20 then 2
			  when ntot < 50 then 1
			  else 0
		      end) as unrel,
		Ti.PB040_N as n,
		ntot,
		Tt.PB040_PctSum_00 as totpop,
		Tp.PB040_PctSum_00 as poorpop,
		Tt.PB040_Sum as totwgh,
		Tp.PB040_Sum as poorwgh,
		"&sysdate" as lastup,
		"&sysuserid" as	lastuser 
	FROM Ti LEFT JOIN Tt ON  (Ti.WORK_INT = Tt.WORK_INT) AND (Ti.CHLD = Tt.CHLD)
		    LEFT JOIN Tp ON   (Ti.WORK_INT = Tp.WORK_INT) AND (Ti.CHLD = Tp.CHLD)
			left JOIN work.old_flag ON ("&Ucc" = old_flag.geo) and (Ti.chld = old_flag.hhtyp)
		    AND (Ti.WORK_INT = old_flag.workint)  
	WHERE &arpt=1;
 
* Update RDB;
data iw03;set iw03; if workint  in ('other','VLOW') then delete; run;
DATA  rdb.iw03;
set rdb.iw03(where=(not(time = &yyyy and geo = "&Ucc")))
    work.iw03; 
run;
%end; 
%if &EU %then %do;

	* EU aggregates;

	%let grpdim=hhtyp,workint,unit;
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
			report = "* &Ucc - &yyyy * iw03 (re)calculated *";		  
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

%mend UPD_iw03;
