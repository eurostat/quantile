*** At-risk-poverty-rate by age and gender before social transfers and pension***;
/* flags are taken from the existing data set  on 3/12/2010 */
/* 22/12/2010 modified to eliminate AGE variable from the old_flag dataset   */
/* consistent AGE format already existed with the changed format for the flags*/
/* 16/03/2011  changed the aggregates calculation:  now is done by EUVALS - the program is splitted in two - LI09 and DI13 */

*** new age brackets added 18 - 24 , 25 - 54 , 55 - 64 , 0 - 64, 21 June 2012 - 20120621BG***;

%macro UPD_li09(yyyy,Ucc,Uccs,flag) /store;

PROC DATASETS lib=work kill nolist;
QUIT;
%let tab=LI09;
%let cc=%lowcase(&Ucc);
%let yy=%substr(&yyyy,3,2);
%let EU=0;
%if &Uccs=0 %then %let Uccs=("&Ucc");
%else %let EU=1; 

PROC FORMAT;
    VALUE f_age (multilabel)
		0 - 15 = "Y_LT16"

		0 - 17 = "Y_LT18"

		16 - 64 = "Y16-64"

		16 - HIGH = "Y_GE16"
		
		18 - 24 = "Y18-24"
		
		18 - 64 = "Y18-64"
		
		25 - 54 = "Y25-54"
		
		55 - 64 = "Y55-64"
		
		0 - 64 = "Y_LT65"

		18 - HIGH = "Y_GE18"

		65 - HIGH = "Y_GE65"
		
		0 - HIGH = "TOTAL"
		
		;


	VALUE f_sex (multilabel)
		1 = "M"
		2 = "F"
		1 - 2 = "T";
RUN;
PROC SQL noprint;
Create table work.idb as 
	select DB010, DB020, DB030, RB030, RB050a, Age, RB090, EQ_INC23,
		(case
	    when EQ_INC23 < ARPT60 then 1
		else 0
		end) as ARPT60i23, 
		(case
	    when EQ_INC23 < ARPT40 then 1
		else 0
		end) as ARPT40i23, 
		(case
	    when EQ_INC23 < ARPT50 then 1
		else 0
		end) as ARPT50i23, 
		(case
	    when EQ_INC23 < ARPT70 then 1
		else 0
		end) as ARPT70i23, 
		(case
	    when EQ_INC23 < ARPT60M then 1
		else 0
		end) as ARPT60Mi23, 
		(case
	    when EQ_INC23 < ARPT40M then 1
		else 0
		end) as ARPT40Mi23, 
		(case
	    when EQ_INC23 < ARPT50M then 1
		else 0
		end) as ARPT50Mi23, 
		EQ_INC23eur, rate, ppp    

	from idb.IDB&yy
	where age ge 0 and DB010 = &yyyy and DB020 in &Uccs;
Select distinct count(DB010) as N 
	into :nobs
	from  work.idb;
Create table work.li09 like rdb.li09; 
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
	  iflag
FROM rdb.&tab
WHERE  time = &yyyy and geo="&Ucc" 
group by time, geo ,sex, indic_il;	

quit;
%if &EU=0 %then %do;
				%macro f_li09(arpt,libel);

				PROC TABULATE data=work.idb out=Ti0;
					FORMAT AGE f_age15.;
					FORMAT RB090 f_sex.;
					VAR RB050a;
					CLASS AGE /MLF;
					CLASS &arpt;
					CLASS RB090 /MLF;
					TABLE &arpt,  AGE * RB090 * (RB050a * (ColPctSum  N)) /printmiss;
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

				PROC SQL;
				INSERT INTO li09 SELECT 
					"&Ucc" as geo,
					&yyyy as time,
					Ti.Age,
					Ti.RB090 as sex,
					"&libel" as indic_il,
					"PC_POP" as unit,
					Ti.RB050a_PctSum_101 as ivalue,
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
						and ("&libel" = old_flag.indic_il) AND (Ti.RB090 = old_flag.sex)  
						
				WHERE &arpt=1;
				QUIT;

				%mend f_li09;

%f_li09(ARPT60i23,LI_R_MD60BTP);
%f_li09(ARPT40i23,LI_R_MD40BTP);
%f_li09(ARPT50i23,LI_R_MD50BTP);
%f_li09(ARPT70i23,LI_R_MD70BTP);
%f_li09(ARPT60Mi23,LI_R_M60BTP);
%f_li09(ARPT40Mi23,LI_R_M40BTP);
%f_li09(ARPT50Mi23,LI_R_M50BTP);

* Update RDB;  
DATA  rdb.LI09;
set rdb.LI09(where=(not(time = &yyyy and geo = "&Ucc")))
    work.li09; 
run;  
 %end;

 * EU aggregates;
%if &EU %then %do;
%let tab=&tab;
	%let grpdim=age,sex,indic_il,unit;
	%EUVALS(&Ucc,&Uccs);
%end;
PROC SQL;  
     Insert into log.log
     set date = "&sysdate"d, time = "&systime"t, user = "&sysuserid",
		 report = "* &Ucc - &yyyy * LI09 (re)calculated *";		  
QUIT;

%end;
%else %do; 
PROC SQL;  
     Insert into log.log
     set date = "&sysdate"d, time = "&systime"t, user = "&sysuserid",
		 report = "* &Ucc - &yyyy * NO DATA !";		  
QUIT;
%end;

%mend UPD_li09;
