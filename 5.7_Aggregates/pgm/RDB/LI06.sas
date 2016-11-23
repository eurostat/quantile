*** At-risk-poverty-rate by work intensity of the household ***;
/* flags are taken from the existing data set  on 2/12/2010 */
/* 22/12/2010 modified to eliminate AGE variable from the old_flag dataset   */
/* consistent AGE format already existed with the changed format for the flags*/
/* 20122601MG intoduced new low working intensuty definition */
/* 20120103MG Spletted in two programs one for At-risk-poverty-rate  and onother for the mean and median */
%macro UPD_li06(yyyy,Ucc,Uccs,flag) /store; 

PROC DATASETS lib=work kill nolist;
QUIT;
%let tab=li06;
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
	  
	VALUE f_chld (multilabel)
		0 = "HH_NDCH"
		1-high = "HH_DCH"
		low - high = "TOTAL";
		
	VALUE f_sex (multilabel)
		1 = "M"
		2 = "F"
		1 - 2 = "T";

	VALUE f_age (multilabel)
		0 - 17 = "Y_LT18"
		0 - 59 = "Y_LT60"
		18 - 59 = "Y18-59"
		;
		

RUN;

PROC SQL noprint;
Create table work.idb as 
	select DB010, DB020, DB030, RB030,  RB050a, ARPT60i, ARPT40i, ARPT50i, ARPT70i,
			ARPT60Mi, ARPT40Mi, ARPT50Mi, Age, RB090,N_DCH as CHLD,WORK_INT
	from idb.IDB&yy
	where 0 <= age < 60 and DB010 = &yyyy and DB020 in &Uccs;
Select distinct count(DB010) as N 
	into :nobs
	from  work.idb;
Create table work.li06 like rdb.li06; 
QUIT;

%if &nobs > 0
%then %do;

%if &EU=0 %then %do;

		%macro f_li06(arpt,libel);
		PROC SQL;
	CREATE TABLE work.old_flag AS
	SELECT distinct
      time,
      geo,
	  indic_il,
	  sex,
	  hhtyp,
  	  workint,
	  iflag
	  FROM rdb.&tab
	WHERE  time = &yyyy   and geo="&Ucc"  and indic_il="&libel";
	quit;
		PROC TABULATE data=work.idb out=Ti0;
				FORMAT AGE f_age15.;
			FORMAT RB090 f_sex.;
			CLASS AGE /MLF;
			CLASS RB090 /MLF;
			FORMAT WORK_INT f_work_int15.;
			FORMAT CHLD  f_chld15.;
			VAR RB050a;
			CLASS WORK_INT /MLF;
			CLASS &arpt;
			CLASS CHLD /MLF;
			TABLE &arpt,  WORK_INT * CHLD * RB090 * AGE * (RB050a * (ColPctSum  N)) /printmiss;
		RUN;
		PROC SQL;
			Create table Ti as
			select *,
				sum(RB050a_N) as ntot
			from Ti0
			group by WORK_INT,  CHLD, RB090, AGE ;
		QUIT;

		PROC TABULATE data=work.idb out=Tt;
			FORMAT AGE f_age15.;
			FORMAT RB090 f_sex.;
			CLASS AGE /MLF;
			CLASS RB090 /MLF;
			FORMAT WORK_INT  f_work_int15.;
			FORMAT CHLD f_chld15.;
			VAR RB050a;
			CLASS WORK_INT  /MLF;
			CLASS CHLD /MLF;
			TABLE RB090 * AGE, CHLD * WORK_INT * (RB050a * (PctSum Sum));
		RUN;

		PROC TABULATE data=work.idb out=Tp;
			FORMAT AGE f_age15.;
			FORMAT RB090 f_sex.;
			CLASS AGE /MLF;
			CLASS RB090 /MLF;
			FORMAT WORK_INT f_work_int15.;
			FORMAT CHLD f_chld15.;
			VAR RB050a;
			CLASS WORK_INT /MLF;
			CLASS CHLD /MLF;
			TABLE RB090 * AGE, CHLD * WORK_INT * (RB050a * (PctSum Sum));
			WHERE &arpt = 1;
		RUN;


 	proc sql;
		INSERT INTO &tab SELECT 
			"&Ucc" as geo,
			&yyyy as time,
			"&libel" as indic_il,
			Ti.RB090 as sex,
			Ti.Age,
			Ti.CHLD as hhtyp,
			Ti.WORK_INT as workint,
			"PC_POP" as unit,
			Ti.RB050a_PctSum_11101 as ivalue,
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
		FROM Ti LEFT JOIN Tt ON (Ti.RB090 = Tt.RB090) AND (Ti.Age = Tt.Age) AND (Ti.CHLD = Tt.CHLD) AND (Ti.WORK_INT = Tt.WORK_INT) 
			    LEFT JOIN Tp ON (Ti.RB090 = Tp.RB090) AND (Ti.Age = Tp.Age) AND (Ti.CHLD = Tp.CHLD) AND (Ti.WORK_INT = Tp.WORK_INT)
	 	 
		LEFT JOIN work.old_flag ON ("&Ucc" = old_flag.geo)  AND (Ti.RB090 = old_flag.sex)
		AND (Ti.CHLD = old_flag.hhtyp) AND (Ti.WORK_INT = old_flag.workint)	
		WHERE &arpt=1 ;
		QUIT;

		%mend f_li06;

%f_li06(ARPT60i,LI_R_MD60);
%f_li06(ARPT40i,LI_R_MD40);
%f_li06(ARPT50i,LI_R_MD50);
%f_li06(ARPT70i,LI_R_MD70);
%f_li06(ARPT60Mi,LI_R_M60);
%f_li06(ARPT40Mi,LI_R_M40);
%f_li06(ARPT50Mi,LI_R_M50);  
 
* Update RDB;  

data &tab;set &tab; if workint ='other' then delete; run;
DATA  rdb.&tab;
set rdb.&tab(where=(not(time = &yyyy and geo = "&Ucc")))
    work.&tab; 
run;  
  %end;
%if &EU %then %do;
	* EU aggregates;
	%let tab=&tab;
	%let grpdim=indic_il,age,sex,hhtyp,workint,unit;
	%EUVALS(&Ucc,&Uccs);
%end;
PROC SQL;  
     Insert into log.log
     set date = "&sysdate"d, time = "&systime"t, user = "&sysuserid",
		 report = "* &Ucc - &yyyy * LI06 (re)calculated *";		  
QUIT;

%end;
%else %do; 
PROC SQL;  
     Insert into log.log
     set date = "&sysdate"d, time = "&systime"t, user = "&sysuserid",
		 report = "* &Ucc - &yyyy * NO DATA !";		  
QUIT;
%end;

%mend UPD_li06;
