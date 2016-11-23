*** At-risk-poverty-rate by most frequent activity and gender ***;
/* changed age froamt on 4/11/2010 */
/* flags are taken from the existing data set  on 2/12/2010 */
/* 22/12/2010 modified to eliminate AGE variable from the old_flag dataset  */
/* consistent AGE format already existed with the changed format for the flags*/
/* 20120111MG applid new ACTSTA definition */
/* 20120103MG Spletted in two programs one for At-risk-poverty-rate  and onother for the mean and median */
%macro UPD_li04(yyyy,Ucc,Uccs,flag) /store;
/*20110624BB change age format*/

PROC DATASETS lib=work kill nolist;
QUIT;
%let tab=LI04;
%let cc=%lowcase(&Ucc);
%let yy=%substr(&yyyy,3,2);
%let EU=0;
%if &Uccs=0 %then %let Uccs=("&Ucc");
%else %let EU=1; 

*** At-risk-poverty-rate by age and gender ***;
PROC FORMAT;
 /*20110627BB split EMP in  SAL and NSAL in ACTSTA*/
   /*20120404BB change format according to new ACTSTA categories*/
   VALUE f_act (multilabel)
		1 - 4 = "EMP" /* 1 filled only up to 2008 included, 2,3,4 filled only from 2009 no overlapping*/
		2 = "SAL"
		3 = "NSAL"  
		5 = "UNE"
		6 = "RET"
		7 = "INAC_OTH"
		5 - 8 = "NEMP"
		1 - 8 = "POP";

	VALUE f_sex (multilabel)
		1 = "M"
		2 = "F"
		1 - 2 = "T";

	VALUE f_age (multilabel)

		18 - HIGH = "Y_GE18"
		16 - HIGH = "Y_GE16"
		18 - 64 = "Y18-64"
		16 - 64 = "Y16-64"
		65 - HIGH = "Y_GE65"
		;
RUN;

PROC SQL noprint;
Create table work.idb as 
	select DB010, DB020, DB030, RB030,  PB040, ARPT60i, ARPT40i, ARPT50i, ARPT70i,
			ARPT60Mi, ARPT40Mi, ARPT50Mi, Age, RB090, ACTSTA
	from idb.IDB&yy
	where age ge 16 and PB040 > 0 and DB010 = &yyyy and DB020 in &Uccs;
Select distinct count(DB010) as N 
	into :nobs
	from  work.idb;
Create table work.li04 like rdb.li04; 
QUIT;

%if &nobs > 0
%then %do;
PROC SQL;
CREATE TABLE work.old_flag AS
SELECT distinct
      time,
      geo,
	  wstatus,
	  indic_il,
	  sex,
	  iflag
	  FROM rdb.&tab
WHERE  time = &yyyy  and geo="&Ucc"    
group by time, geo ,wstatus, indic_il,sex ;
quit;
%if &EU =0 %then %do;
				%macro f_li04(arpt,libel);
				PROC TABULATE data=work.idb out=Ti0;
					FORMAT ACTSTA f_act15.;
					FORMAT RB090 f_sex.;
					FORMAT AGE f_age15.;
					VAR PB040;
					CLASS ACTSTA /MLF;
					CLASS &arpt;
					CLASS RB090 /MLF;
					CLASS AGE /MLF;
					TABLE &arpt,  ACTSTA * RB090 * AGE * (PB040 * (ColPctSum  N)) /printmiss;
				RUN;
				PROC SQL;
					Create table Ti as
					select *,
						sum(PB040_N) as ntot
					from Ti0
					group by ACTSTA, RB090, AGE;
				QUIT;

				PROC TABULATE data=work.idb out=Tt;
					FORMAT ACTSTA f_act15.;
					FORMAT RB090 f_sex.;
					FORMAT AGE f_age15.;
					VAR PB040;
					CLASS ACTSTA /MLF;
					CLASS RB090 /MLF;
					CLASS AGE /MLF;
					TABLE RB090 * AGE, ACTSTA * (PB040 * (PctSum Sum));
				RUN;
				PROC TABULATE data=work.idb out=Tp;
					FORMAT ACTSTA f_act15.;
					FORMAT RB090 f_sex.;
					FORMAT AGE f_age15.;
					VAR PB040;
					CLASS ACTSTA /MLF;
					CLASS RB090 /MLF;
					CLASS AGE /MLF;
					TABLE RB090 * AGE, ACTSTA * (PB040 * (PctSum Sum));
					WHERE &arpt = 1;
				RUN;
				proc sql;				
				INSERT INTO li04 SELECT 
					"&Ucc" as geo,
					&yyyy as time,
					Ti.ACTSTA as wstatus,
					Ti.Age,
					Ti.RB090 as sex,
					"&libel" as indic_il,
					"PC_POP" as unit,
					Ti.PB040_PctSum_1011 as ivalue,
					old_flag.iflag as iflag, 
					(case when ntot < 20 then 2
						  when ntot < 50 then 1
						  else 0
					      end) as unrel,
					Ti.PB040_N as n,
					ntot,
					Tt.PB040_Sum as totwgh,
					"&sysdate" as lastup,
					"&sysuserid" as	lastuser 
				FROM Ti LEFT JOIN Tt ON (Ti.RB090 = Tt.RB090) AND (Ti.Age = Tt.Age) AND (Ti.ACTSTA = Tt.ACTSTA)  
					    LEFT JOIN Tp ON (Ti.RB090 = Tp.RB090) AND (Ti.Age = Tp.Age) AND (Ti.ACTSTA = Tp.ACTSTA)
				LEFT JOIN work.old_flag ON ("&Ucc" = old_flag.geo) AND (TI.ACTSTA=old_flag.wstatus)
				AND ("&libel" = old_flag.indic_il)	and (TI.RB090=old_flag.sex)  /*and (TI.Age=old_flag.Age) */
						
				WHERE &arpt=1;
				QUIT;

				%mend f_li04;

%f_li04(ARPT60i,LI_R_MD60);
%f_li04(ARPT40i,LI_R_MD40);
%f_li04(ARPT50i,LI_R_MD50);
%f_li04(ARPT70i,LI_R_MD70);
%f_li04(ARPT60Mi,LI_R_M60);
%f_li04(ARPT40Mi,LI_R_M40);
%f_li04(ARPT50Mi,LI_R_M50);
 

* Update RDB;   
DATA  rdb.&tab;
set rdb.&tab(where=(not(time = &yyyy and geo = "&Ucc")))
    work.&tab; 
run;  
 %end;
%if &EU %then %do;

	* EU aggregates;
	%let tab=&tab;
	%let grpdim=wstatus,age,sex,indic_il,unit;
	%EUVALS(&Ucc,&Uccs);
%end;

PROC SQL;  
     Insert into log.log
     set date = "&sysdate"d, time = "&systime"t, user = "&sysuserid",
		 report = "* &Ucc - &yyyy * &tab (re)calculated *";		  
QUIT;

%end;
%else %do; 
PROC SQL;  
     Insert into log.log
     set date = "&sysdate"d, time = "&systime"t, user = "&sysuserid",
		 report = "* &Ucc - &yyyy * NO DATA !";		  
QUIT;
%end;

%mend UPD_li04;
