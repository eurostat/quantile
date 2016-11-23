*** At-risk-poverty-rate by age and gender ***;
/* flags are taken from the existing data set  on 29/11/2010 */
%macro UPD_li02(yyyy,Ucc,Uccs,flag) /store;
/* 24/11/2010 change in calculation of aggregates 1 aggregate = 1 big country (as before)*/  
/* 22/12/2010 modified to eliminate AGE variable from the old_flag dataset   */
/* consistent AGE format already existed with the changed format for the flags*/
*** child age format added  25 October 2011 -  20111025MG ***;
/* 20120103MG Spletted in two programs one for At-risk-poverty-rate  and onother for the mean and median */
PROC DATASETS lib=work kill nolist;
QUIT;

%let tab=LI02;
%let cc=%lowcase(&Ucc);
%let yy=%substr(&yyyy,3,2);
%let EU=0;
%if &Uccs=0 %then %let Uccs=("&Ucc");
%else %let EU=1; 

*** At-risk-poverty-rate by age and gender ***;
PROC FORMAT;
    VALUE f_age (multilabel)
	/*  added */
		0 - 5 = "Y_LT6"
		6 - 11 = "Y6-11"
		12 - 17 = "Y12-17"	
	/* end */
		0 - 15 = "Y_LT16"
		0 - 17 = "Y_LT18"
		0 - 64 = "Y_LT65"
		16 - HIGH = "Y_GE16"
		16 - 64 = "Y16-64"
		16 - 24 = "Y16-24"
		18 - HIGH = "Y_GE18"
		18 - 64 = "Y18-64"
		18 - 24 = "Y18-24"
		25 - 49 = "Y25-49"
		25 - 54 = "Y25-54"
		50 - 64 = "Y50-64"
		55 - 64 = "Y55-64"
		65 - HIGH = "Y_GE65"
		0 - HIGH = "TOTAL"
		0 - 74 = "Y_LT75"
		75 - HIGH = "Y_GE75"
		0 - 59 = "Y_LT60"
		60 - HIGH = "Y_GE60"
		;

	VALUE f_sex (multilabel)
		1 = "M"
		2 = "F"
		1 - 2 = "T";
RUN;
PROC SQL noprint;
Create table work.idb as 
	select DB010, DB020, DB030, RB030, RB050a, ARPT60i, ARPT40i, ARPT50i, ARPT70i,
			ARPT60Mi, ARPT40Mi, ARPT50Mi, Age, RB090
	from idb.IDB&yy
	where age ge 0 and DB010 = &yyyy and DB020 in &Uccs;
Select distinct count(DB010) as N 
	into :nobs
	from  work.idb;
Create table work.li02 like rdb.li02; 
QUIT;

%if &nobs > 0
%then %do;
proc sql;
CREATE TABLE work.old_flag AS
SELECT distinct
      time,
      geo,
	  sex,
	  indic_il,
	  unit,
	  iflag
	  FROM rdb.&tab
WHERE  time = &yyyy and geo="&Ucc"  
group by time, geo , sex, indic_il, unit ;

QUIT;

			%macro f_li02(arpt,libel);

					PROC TABULATE data=work.idb out=Ti0;
						FORMAT AGE f_age15.;
						FORMAT RB090 f_sex.;
						VAR RB050a;
						CLASS AGE /MLF;
						CLASS &arpt;
						CLASS RB090 /MLF;
						TABLE &arpt,  AGE * RB090 * (RB050a * (ColPctSum Sum N)) /printmiss;
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
						WHERE &arpt = 1;
					RUN;

				%macro by_unit(unit,ival); 
				 	PROC SQL;
					INSERT INTO li02 SELECT 
						"&Ucc" as geo,
						&yyyy as time,
						Ti.Age,
						Ti.RB090 as sex,
						"&libel" as indic_il,
						"&unit" as unit ,
						Ti.&ival as ivalue,
						old_flag.iflag as iflag, 
						(case when ntot < 20 then 2
							  when ntot < 50 then 1
							  else 0
						      end) as unrel,
						Ti.RB050a_N as n,
						ntot,
						Tt.RB050a_Sum as totwgh,
					   "&sysdate" as lastup,
						"&sysuserid" as	lastuser 
					FROM Ti LEFT JOIN Tt ON (Ti.RB090 = Tt.RB090) AND (Ti.Age = Tt.Age) 
						    LEFT JOIN Tp ON (Ti.RB090 = Tp.RB090) AND (Ti.Age = Tp.Age)
							LEFT JOIN work.old_flag ON ("&Ucc" = old_flag.geo) 
					       AND (TI.RB090 = old_flag.sex)  AND ("&libel" = old_flag.indic_il) and ("&unit" = old_flag.unit)
					WHERE &arpt=1;
					QUIT;
										
				%mend by_unit;
					%by_unit(PC_POP,RB050a_PctSum_101);
					%by_unit(THS_PER,RB050a_Sum/1000);
			%mend f_li02;
%if &EU =0 %then %do;

%f_li02(ARPT60i,LI_R_MD60);
%f_li02(ARPT40i,LI_R_MD40);
%f_li02(ARPT50i,LI_R_MD50);
%f_li02(ARPT70i,LI_R_MD70);
%f_li02(ARPT60Mi,LI_R_M60);
%f_li02(ARPT40Mi,LI_R_M40);
%f_li02(ARPT50Mi,LI_R_M50);

* Update RDB;  
DATA  rdb.LI02;
set rdb.LI02(where=(not(time = &yyyy and geo = "&Ucc")))
    work.li02; 
run; 
%end;
%if &EU %then %do;

	* EU aggregates;

	%let tab=li02;
	%let grpdim=age,sex ,indic_il,unit;
	%EUVALS(&Ucc,&Uccs);
%end;
PROC SQL;  
     Insert into log.log
     set date = "&sysdate"d, time = "&systime"t, user = "&sysuserid",
		 report = "* &Ucc - &yyyy * LI02 (re)calculated *";		  
QUIT;

%end;
%else %do; 
PROC SQL;  
     Insert into log.log
     set date = "&sysdate"d, time = "&systime"t, user = "&sysuserid",
		 report = "* &Ucc - &yyyy * NO DATA !";		  
QUIT;
%end;

%mend UPD_li02;
