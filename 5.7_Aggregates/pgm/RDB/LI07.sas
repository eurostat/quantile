*** At-risk-poverty-rate by age and highest education level ***;
/* flags are taken from the existing data set  on 3/12/2010 */
/* 22/12/2010 modified to eliminate AGE variable from the old_flag dataset   */
/* consistent AGE format already existed with the changed format for the flags*/
/*20120601MG changed ISCED code */
/* 20120103MG Spletted in two programs one for At-risk-poverty-rate  and onother for the mean and median */
%macro UPD_li07(yyyy,Ucc,Uccs,flag) /*/store */;

PROC DATASETS lib=work kill nolist;
QUIT;
%let tab=LI07;
%let cc=%lowcase(&Ucc);
%let yy=%substr(&yyyy,3,2);
%let EU=0;
%if &Uccs=0 %then %let Uccs=("&Ucc");
%else %let EU=1; 

PROC FORMAT;
    VALUE f_age (multilabel)
		18 - HIGH = "Y_GE18"

		18 - 64 = "Y18-64"

		65 - HIGH = "Y_GE65"

		;

	VALUE f_sex (multilabel)
		1 = "M"
		2 = "F"
		1 - 2 = "T";

	VALUE f_educ 
		0 - 2 = "ED0-2"
		3 - 4 = "ED3_4"
		5 - 6 = "ED5_6";
RUN;

PROC SQL noprint;
Create table work.idb as 
	select DB010, DB020, DB030, RB030, PB040, ARPT60i, ARPT40i, ARPT50i, ARPT70i,
			ARPT60Mi, ARPT40Mi, ARPT50Mi, Age, RB090, PE40
	from idb.IDB&yy
	where age GE 18 and PE40 ge 0 and DB010 = &yyyy and DB020 in &Uccs;
Select distinct count(DB010) as N 
	into :nobs
	from  work.idb;
Create table work.li07 like rdb.li07; 
QUIT;

%if &nobs > 0
%then %do;
	PROC SQL;
	CREATE TABLE work.old_flag AS
	SELECT distinct
      time,
      geo,
	  sex,
	  isced97,
	  indic_il,
	  iflag
FROM rdb.&tab
WHERE  time = &yyyy and geo="&Ucc" 
group by time, geo ,sex,isced97, indic_il ;
quit;;	

%if &EU=0  %then %do;

				%macro f_li07(arpt,libel);

				PROC TABULATE data=work.idb out=Ti0;
					FORMAT AGE f_age15.;
					FORMAT PE40 f_educ.;
					FORMAT RB090 f_sex.;
					VAR PB040;
					CLASS AGE /MLF;
					CLASS RB090 /MLF;
					CLASS &arpt;
					CLASS PE40 /MLF;
					TABLE &arpt,  AGE * RB090 * PE40 * (PB040 * (ColPctSum  N)) /printmiss;
				RUN;
				PROC SQL;
					Create table Ti as
					select *,
						sum(PB040_N) as ntot
					from Ti0
					group by Age, PE40, RB090;
				QUIT;

				PROC TABULATE data=work.idb out=Tt;
					FORMAT AGE f_age9.;
					FORMAT PE40 f_educ.;
					FORMAT RB090 f_sex.;
					VAR PB040;
					CLASS AGE /MLF;
					CLASS RB090 /MLF;
					CLASS PE40 /MLF;
					TABLE PE40, Age * RB090 * (PB040 * (PctSum Sum));
				RUN;

				PROC TABULATE data=work.idb out=Tp;
					FORMAT AGE f_age9.;
					FORMAT PE40 f_educ.;
					FORMAT RB090 f_sex.;
					VAR PB040;
					CLASS AGE /MLF;
					CLASS RB090 /MLF;
					CLASS PE40 /MLF;
					TABLE PE40, Age * RB090 * (PB040 * (PctSum Sum));
					WHERE &arpt = 1;
				RUN;


		Proc sql;
		INSERT INTO li07 SELECT 
					"&Ucc" as geo,
					&yyyy as time,
					Ti.Age,
					Ti.RB090 as sex,
					Ti.PE40 as isced97,
					"&libel" as indic_il,
					"PC_POP" as unit,
					Ti.PB040_PctSum_1101 as ivalue,
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
				FROM Ti LEFT JOIN Tt ON (Ti.PE40 = Tt.PE40) AND (Ti.Age = Tt.Age) AND (Ti.RB090 = Tt.RB090)
					    LEFT JOIN Tp ON (Ti.PE40 = Tp.PE40) AND (Ti.Age = Tp.Age)  AND (Ti.RB090 = Tp.RB090)
					   	LEFT JOIN work.old_flag ON ("&Ucc" = old_flag.geo) 
					AND (Ti.RB090 = old_flag.sex)  AND (Ti.PE40 = old_flag.isced97) and ("&libel" = old_flag.indic_il) 
				WHERE &arpt=1;
				QUIT;

				%mend f_li07;

%f_li07(ARPT60i,LI_R_MD60);
%f_li07(ARPT40i,LI_R_MD40);
%f_li07(ARPT50i,LI_R_MD50);
%f_li07(ARPT70i,LI_R_MD70);
%f_li07(ARPT60Mi,LI_R_M60);
%f_li07(ARPT40Mi,LI_R_M40);
%f_li07(ARPT50Mi,LI_R_M50);

* Update RDB;   
DATA  rdb.&tab;
set rdb.&tab(where=(not(time = &yyyy and geo = "&Ucc")))
    work.&tab; 
run;  
%end;
* EU aggregates;

%if &EU %then %do;
%let tab=&tab;
	%let grpdim=age,sex,isced97,indic_il,unit;
	%EUVALS(&Ucc,&Uccs);
%end;

PROC SQL;  
     Insert into log.log
     set date = "&sysdate"d, time = "&systime"t, user = "&sysuserid",
		 report = "* &Ucc - &yyyy * LI07 (re)calculated *";		  
QUIT;

%end;
%else %do; 
PROC SQL;  
     Insert into log.log
     set date = "&sysdate"d, time = "&systime"t, user = "&sysuserid",
		 report = "* &Ucc - &yyyy * NO DATA !";		  
QUIT;
%end;

%mend UPD_li07;
