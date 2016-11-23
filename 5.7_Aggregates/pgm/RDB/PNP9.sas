*** At-risk-poverty-rate by household type ***;
/* changed age format  */
/* flags are taken from the existing data set  on 25/11/2010 */
/* 22/12/2010 modified to eliminate AGE variable from the old_flag dataset   */
/* consistent AGE format already existed with the changed format for the flags*/
*** only single HH ***;
*** gender differences (M-F) ***;


%macro UPD_pnp9(yyyy,Ucc,Uccs,flag) /* /store */ ;

PROC DATASETS lib=work kill nolist;
QUIT;
%let tab=pnp9;

%let cc=%lowcase(&Ucc);
%let yy=%substr(&yyyy,3,2);
%let EU=0;
%if &Uccs=0 %then %let Uccs=("&Ucc");
%else %let EU=1; 

PROC FORMAT;
	VALUE f_sex (multilabel)
		1 = "M"
		2 = "F"
		1 - 2 = "T";

	VALUE f_age (multilabel)
		0 - 64 = "Y_LT65"

		65 - HIGH = "Y_GE65";


RUN;

*** total ***;
PROC SQL noprint;
Create table work.idb as 
	select DB010, DB020, DB030, RB030,  PB040, Age, RB090, HT, ARPT60i
	from idb.IDB&yy
	where age ge 16 and PB040 > 0 and DB010 = &yyyy and DB020 in &Uccs;
Select distinct count(DB010) as N 
	into :nobs
	from  work.idb;
Create table work.pnp9 like rdb.pnp9; 

CREATE TABLE work.old_flag AS
SELECT distinct
      time,
      geo,
	  hhtyp,
	 /* age, */
      sex,
	  iflag
FROM rdb.&tab
WHERE  time = &yyyy and geo="&Ucc";
QUIT;

%if &nobs > 0
%then %do;
					%macro f_pnp9(hhtyp)  ;
					PROC TABULATE data=work.idb out=Ti0;
						FORMAT RB090 f_sex.;
						FORMAT AGE f_age15.;
						VAR PB040;
						CLASS ARPT60i;
						CLASS RB090 /MLF;
						CLASS AGE /MLF;
						TABLE ARPT60i,  RB090 * AGE * (PB040 * (ColPctSum  N)) /printmiss;
					RUN;
					PROC SQL;
						Create table Ti as
						select *,
							sum(PB040_N) as ntot
						from Ti0
						group by RB090, AGE;
					QUIT;

					PROC TABULATE data=work.idb out=Tt;
						FORMAT RB090 f_sex.;
						FORMAT AGE f_age15.;
						VAR PB040;
						CLASS RB090 /MLF;
						CLASS AGE /MLF;
						TABLE  AGE, RB090 * (PB040 * (RowPctSum Sum));
					RUN;

					proc sql;
					INSERT INTO pnp9 SELECT 
						"&Ucc" as geo,
						&yyyy as time,
						"&hhtyp" as hhtyp,
						Ti.RB090 as sex,
						Ti.Age,
						Ti.PB040_PctSum_011 as ivalue,
						old_flag.iflag as iflag, 
						/*"&flag" as iflag, */
						(case when ntot < 20 then 2
							  when ntot < 50 then 1
							  else 0
						      end) as unrel,
						Ti.PB040_N as n,
						ntot,
						Tt.PB040_PctSum_01 as totpop,
						Tt.PB040_Sum as totwgh,
						"&sysdate" as lastup,
						"&sysuserid" as	lastuser 
					FROM Ti LEFT JOIN Tt ON (Ti.RB090 = Tt.RB090) AND (Ti.Age = Tt.Age)  
					LEFT JOIN work.old_flag ON ("&Ucc" = old_flag.geo) 
					AND ("&hhtyp" = old_flag.hhtyp) AND (Ti.RB090 = old_flag.sex)
	                /* AND (Ti.age = old_flag.age) */
     
					WHERE ARPT60i=1;
					QUIT;
					%mend f_pnp9;
%f_pnp9(TOTAL);

%end;
%else %do; 
PROC SQL;  
     Insert into log.log
     set date = "&sysdate"d, time = "&systime"t, user = "&sysuserid",
		 report = "* &Ucc - &yyyy * NO DATA(TOTAL) !";		  
QUIT;
%end;

*** single ***;
PROC SQL noprint;
Create table work.idb as 
	select DB010, DB020, DB030, RB030,  PB040, Age, RB090, HT, ARPT60i
	from idb.IDB&yy
	where HT=5 and age ge 16 and PB040 > 0 and DB010 = &yyyy and DB020 in &Uccs;
Select distinct count(DB010) as N 
	into :nobs
	from  work.idb;
QUIT;

%if &nobs > 0
%then %do;

%f_pnp9(A1);

%end;
%else %do; 
PROC SQL;  
     Insert into log.log
     set date = "&sysdate"d, time = "&systime"t, user = "&sysuserid",
		 report = "* &Ucc - &yyyy * NO DATA(A1) !";		  
QUIT;
%end;



*genderdiff;
PROC SQL;
Create table work.M as select * FROM work.pnp9 WHERE sex = "M";
Create table work.F as select * FROM work.pnp9 WHERE sex = "F";
INSERT into pnp9 SELECT 
	"&Ucc" as geo,
	&yyyy as time,
	M.hhtyp as hhtyp,
	"DIFF" as sex,
	M.age as age,
	(M.ivalue - F.ivalue) as ivalue,
	old_flag.iflag as iflag, 
						/*"&flag" as iflag, */
	(case when min(M.ntot,F.ntot) < 20 then 2
		  when min(M.ntot,F.ntot) < 50 then 1
		  else 0
	      end) as unrel,
	(F.n + M.n) as n,
	(F.ntot + M.ntot) as ntot,
	(F.totpop + M.totpop) as totpop,
	(F.totwgh + M.totwgh) as totwgh,
	"&sysdate" as lastup,
	"&sysuserid" as	lastuser 
FROM work.M join work.F on M.age = F.age and M.hhtyp = F.hhtyp 
     LEFT JOIN work.old_flag ON ("&Ucc" = old_flag.geo) 
					AND (M.hhtyp  = old_flag.hhtyp) AND ("DIFF" = old_flag.sex)
	               /* AND (M.age = old_flag.age) */ ;
QUIT; 

* Update RDB;  
DATA  rdb.pnp9;
set rdb.pnp9(where=(not(time = &yyyy and geo = "&Ucc")))
    work.pnp9; 
run;  
 

PROC SQL;  
     Insert into log.log
     set date = "&sysdate"d, time = "&systime"t, user = "&sysuserid",
		 report = "* &Ucc - &yyyy * pnp9 (re)calculated *";		  
QUIT;

%mend UPD_pnp9;
