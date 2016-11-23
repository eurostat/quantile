*** At-risk-poverty-rate by tenure status ***;
/* flags are taken from the existing data set  on 3/12/2010 */
/* 22/12/2010 modified to eliminate AGE variable from the old_flag dataset   */
/* consistent AGE format already existed with the changed format for the flags*/
/*20120601MG changed ISCED code */
/* 20120103MG Spletted in two programs one for At-risk-poverty-rate  and onother for the mean and median */
%macro UPD_li08(yyyy,Ucc,Uccs,flag) /store;

PROC DATASETS lib=work kill nolist;
QUIT;
%let tab=LI08;
%let cc=%lowcase(&Ucc);
%let yy=%substr(&yyyy,3,2);
%let EU=0;
%if &Uccs=0 %then %let Uccs=("&Ucc");
%else %let EU=1; 


*** At-risk-poverty-rate by age and gender ***;
PROC FORMAT;
	VALUE ftensta(multilabel)
		1,2 = "TOTAL"
		1 = "OWN"
		2 = "RENT";

	VALUE f_sex (multilabel)
		1 = "M"
		2 = "F"
		1 - 2 = "T";

    VALUE f_age (multilabel)
		0 - 17 = "Y_LT18"

		18 - HIGH = "Y_GE18"

		18 - 64 = "Y18-64"

		65 - HIGH = "Y_GE65"

		60 - HIGH = "Y_GE60"

		75 - HIGH = "Y_GE75"

		0 - HIGH = "TOTAL"
		;

RUN;

PROC SQL noprint;
Create table work.idb as 
	select DB010, DB020, DB030, RB030,  RB050a, ARPT60i, ARPT40i, ARPT50i, ARPT70i,
			ARPT60Mi, ARPT40Mi, ARPT50Mi, Age, RB090, TENSTA  
	from idb.IDB&yy
	where AGE GE 0 and DB010 = &yyyy and DB020 in &Uccs;
Select distinct count(DB010) as N 
	into :nobs
	from  work.idb;
Create table work.&tab like rdb.&tab; 
QUIT;

%if &nobs > 0
%then %do;

proc sql;
	CREATE TABLE work.old_flag AS
SELECT distinct
      time,
      geo,
	  TENURE,
	  indic_il,
	  sex,
	  iflag
FROM rdb.&tab
WHERE  time = &yyyy and geo="&Ucc" 
group by time, geo ,tenure, indic_il,sex;
quit;
%if &EU=0 %then %do;
	
				%macro f_li08(arpt,libel);

				PROC TABULATE data=work.idb out=Ti0;
					FORMAT TENSTA ftensta15.;
					FORMAT RB090 f_sex.;
					FORMAT AGE f_age15.;
					VAR RB050a;
					CLASS TENSTA /MLF;
					CLASS &arpt;
					CLASS RB090 /MLF;
					CLASS AGE /MLF;
					TABLE &arpt,  TENSTA * RB090 * AGE * (RB050a * (ColPctSum  N)) /printmiss;
				RUN;
				PROC SQL;
					Create table Ti as
					select *,
						sum(RB050a_N) as ntot
					from Ti0
					group by TENSTA, RB090, AGE;
				QUIT;

				PROC TABULATE data=work.idb out=Tt;
					FORMAT TENSTA ftensta15.;
					FORMAT RB090 f_sex.;
					FORMAT AGE f_age15.;
					VAR RB050a;
					CLASS TENSTA /MLF;
					CLASS RB090 /MLF;
					CLASS AGE /MLF;
					TABLE RB090 * AGE, TENSTA * (RB050a * (PctSum Sum));
				RUN;

				PROC TABULATE data=work.idb out=Tp;
					FORMAT TENSTA ftensta15.;
					FORMAT RB090 f_sex.;
					FORMAT AGE f_age15.;
					VAR RB050a;
					CLASS TENSTA /MLF;
					CLASS RB090 /MLF;
					CLASS AGE /MLF;
					TABLE RB090 * AGE, TENSTA * (RB050a * (PctSum Sum));
					WHERE &arpt = 1;
				RUN;

				PROC SQL;
				INSERT INTO li08 SELECT 
					"&Ucc" as geo,
					&yyyy as time,
					Ti.TENSTA as TENURE,
					"&libel" as indic_il,
					Ti.RB090 as sex,
					Ti.Age,
					"PC_POP" as unit,
					Ti.RB050a_PctSum_1011 as ivalue,
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
				FROM Ti LEFT JOIN Tt ON (Ti.RB090 = Tt.RB090) AND (Ti.Age = Tt.Age) AND (Ti.TENSTA = Tt.TENSTA)  
					    LEFT JOIN Tp ON (Ti.RB090 = Tp.RB090) AND (Ti.Age = Tp.Age) AND (Ti.TENSTA = Tp.TENSTA)
						LEFT JOIN work.old_flag ON ("&Ucc" = old_flag.geo) AND (Ti.TENSTA = old_flag.TENURE)
						and ("&libel" = old_flag.indic_il) AND (Ti.RB090 = old_flag.sex)  
				WHERE &arpt=1;
				QUIT;
				%mend f_li08;

%f_li08(ARPT60i,LI_R_MD60);
%f_li08(ARPT40i,LI_R_MD40);
%f_li08(ARPT50i,LI_R_MD50);
%f_li08(ARPT70i,LI_R_MD70);
%f_li08(ARPT60Mi,LI_R_M60);
%f_li08(ARPT40Mi,LI_R_M40);
%f_li08(ARPT50Mi,LI_R_M50);

* Update RDB;   
DATA  rdb.&tab;
set rdb.&tab(where=(not(time = &yyyy and geo = "&Ucc")))
    work.&tab; 
run;  
%end;

 * EU aggregates;
%if &EU %then %do;
%let tab=&tab;
	%let grpdim=TENURE,indic_il,age,sex,unit;
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

%mend UPD_li08;
