*** IN-WORK At-risk-poverty-rate by age and highest education level ***;
/*20110627BB change ACTSTA in IDB in order to add SAL and NSAL breakdowns
update format accordingly in indicators*/
/*20120601MG changed ISCED code and applied new ACTSTA definition*/
/* 20120120MG applyed mEUvals to calcultion aggregates */
/*20120404BB change values for ACTSTA according to new ACTSTA categories*/
/*20121002MG added EU condition  */

%macro UPD_iw04(yyyy,Ucc,Uccs,flag) /store;

PROC DATASETS lib=work kill nolist;
QUIT;
%let tab=iw04;
%let cc=%lowcase(&Ucc);
%let yy=%substr(&yyyy,3,2);
%let EU=0;
%if &Uccs=0 %then %let Uccs=("&Ucc");
%else %let EU=1; 

PROC FORMAT;
	VALUE f_educ 
		0 - 2 = "ED0-2"
		3 - 4 = "ED3_4"
		5 - 6 = "ED5_6";
RUN;

PROC SQL noprint;
Create table work.idb as 
	select DB010, DB020, DB030, RB030, PB040, ARPT60i, PE40, EQ_INC20, 
			EQ_INC20eur   
	from idb.IDB&yy
	where ACTSTA in(1,2,3,4) and PB040 > 0 and 
		age GE 18 and PE40 ge 0 and DB010 = &yyyy and DB020 in &Uccs;
Select distinct count(DB010) as N 
	into :nobs
	from  work.idb;
Create table work.iw04 like rdb.iw04; 
QUIT;

%if &nobs > 0
%then %do;
proc sql;
CREATE TABLE work.old_flag AS
SELECT distinct
      time,
      geo,
	  isced97,
	  ivalue,
	  iflag
FROM rdb.&tab
WHERE  time = &yyyy and geo="&Ucc" ;	
quit;

%if &EU=0 %then %do;

	%let arpt=ARPT60i;
	%let libel=LI_R_MD60;

	PROC TABULATE data=work.idb out=Ti0;
		FORMAT PE40 f_educ.;
		VAR PB040;
		CLASS &arpt;
		CLASS PE40 /MLF;
		TABLE &arpt,  PE40 * (PB040 * (ColPctSum  N)) /printmiss;
	RUN;
	PROC SQL;
		Create table Ti as
		select *,
			sum(PB040_N) as ntot
		from Ti0
		group by PE40;
	QUIT;

	PROC TABULATE data=work.idb out=Tt;
		FORMAT PE40 f_educ.;
		VAR PB040;
		CLASS PE40 /MLF;
		TABLE PE40, (PB040 * (PctSum Sum));
	RUN;

	PROC TABULATE data=work.idb out=Tp;
		FORMAT PE40 f_educ.;
		VAR PB040;
		CLASS PE40 /MLF;
		TABLE PE40, (PB040 * (PctSum Sum));
		WHERE &arpt = 1;
	RUN;

	PROC SQL;
	INSERT INTO iw04 SELECT 
		"&Ucc" as geo,
		&yyyy as time,
		Ti.PE40 as isced97,
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
	FROM Ti LEFT JOIN Tt ON (Ti.PE40 = Tt.PE40) 
		    LEFT JOIN Tp ON (Ti.PE40 = Tp.PE40) 
			left JOIN work.old_flag ON ("&Ucc" = old_flag.geo) and (Ti.PE40 = old_flag.isced97)
		   	WHERE &arpt=1;
	QUIT;



* Update RDB;
DATA  rdb.iw04;
set rdb.iw04(where=(not(time = &yyyy and geo = "&Ucc")))
    work.iw04; 
run;
%end; 
%if &EU %then %do;

	* EU aggregates;

	%let grpdim=isced97,unit;
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
			report = "* &Ucc - &yyyy * iw04 (re)calculated *";		  
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

%mend UPD_iw04;
