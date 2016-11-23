*** At-risk-poverty-rate by household type ***;
*** changed age format 4/11/2010 ****;
/* flags are taken from the existing data set  on 2/12/2010 */
/* 20120103MG Spletted in two programs one for At-risk-poverty-rate  and onother for the mean and median */
%macro UPD_li03(yyyy,Ucc,Uccs,flag) /store;

PROC DATASETS lib=work kill nolist;
QUIT;

%let tab=LI03;
%let cc=%lowcase(&Ucc);
%let yy=%substr(&yyyy,3,2);
%let EU=0;
%if &Uccs=0 %then %let Uccs=("&Ucc");
%else %let EU=1; 

PROC FORMAT;
     VALUE f_ht (multilabel max=45)
		5 - 8 = "HH_NDCH"
		5 =	 "A1" 
		6 =	 "A2_2LT65"
		7 =	 "A2_GE1_GE65"
		6,7 = "A2"
		8 =	 "A_GE3"
		6 - 8 = "A_GE2_NDCH"
		9 - 13 = "HH_DCH"
		9 =	 "A1_DCH"
		10 = "A2_1DCH"
		10 - 13 = "A_GE2_DCH"
		11 = "A2_2DCH"
		12 = "A2_GE3DCH"
		13 = "A_GE3_DCH"
		5 - 13 = "TOTAL";

	VALUE f_age
		LOW - 64 = "A1_LT65"
		65 - HIGH = "A1_GE65";

	VALUE f_sex
		1 = "A1M"
		2 = "A1F";

RUN;
PROC SQL noprint;
Create table work.idb as 
	select DB010, DB020, DB030, RB030, RB050a, ARPT60i, ARPT40i, ARPT50i, ARPT70i,
			ARPT60Mi, ARPT40Mi, ARPT50Mi, Age, RB090, HT
	from idb.IDB&yy
	where HT between 5 and 13 and DB010 = &yyyy and DB020 in &Uccs;

Select distinct count(DB010) as N 
	into :nobs
	from  work.idb;
Create table work.li03 like rdb.li03; 
QUIT;

%if &nobs > 0
%then %do;
PROC SQL;
	CREATE TABLE work.old_flag AS
SELECT 
      time,
      geo,
	  hhtyp,
	  indic_il,
	  iflag
	  FROM rdb.&tab
WHERE  time = &yyyy  and geo="&Ucc"  
group by time, geo ,hhtyp, indic_il ;
quit;

%if &EU=0 %then %do;

				%macro f_li03(arpt,libel);

				PROC TABULATE data=work.idb out=Ti0;
					FORMAT HT f_ht45.;
					VAR RB050a;
					CLASS HT /MLF;
					CLASS &arpt;
					TABLE &arpt, HT * (RB050a * (ColPctSum  N)) /printmiss;
				RUN;
				PROC SQL;
					Create table Ti as
					select *,
						sum(RB050a_N) as ntot
					from Ti0
					group by HT;
				QUIT;

				PROC TABULATE data=work.idb out=Tt;
					FORMAT HT f_ht45.;
					VAR RB050a;
					CLASS HT /MLF;
					TABLE HT, (RB050a * (PctSum Sum));
				RUN;

				PROC TABULATE data=work.idb out=Tp;
					FORMAT HT f_ht45.;
					VAR RB050a;
					CLASS HT /MLF;
					TABLE HT, (RB050a * (PctSum Sum));
					WHERE &arpt = 1;
				RUN;

					
				proc sql;
				INSERT INTO li03 SELECT 
					"&Ucc" as geo,
					&yyyy as time,
					Ti.HT as hhtyp,
					"&libel"	as indic_il,
					"PC_POP" as unit,
					Ti.RB050a_PctSum_10 as ivalue,
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
				FROM Ti LEFT JOIN Tt ON (Ti.HT = Tt.HT) 
					    LEFT JOIN Tp ON (Ti.HT = Tp.HT) 
					  
				LEFT JOIN work.old_flag ON ("&Ucc" = old_flag.geo) AND (Ti.HT = old_flag.hhtyp)
				AND ("&libel" = old_flag.indic_il)	
											
				WHERE &arpt=1;
				QUIT;

				* single by Age;
				PROC TABULATE data=work.idb out=Ti0;
					FORMAT AGE f_age15.;
					VAR RB050a;
					CLASS AGE /MLF;
					CLASS &arpt;
					TABLE &arpt,  AGE * (RB050a * (ColPctSum  N)) /printmiss;
					where HT = 5;
				RUN;
				PROC SQL;
					Create table Ti as
					select *,
						sum(RB050a_N) as ntot
					from Ti0
					group by Age;
				QUIT;

				PROC TABULATE data=work.idb out=Tt;
					FORMAT AGE f_age15.;
					VAR RB050a;
					CLASS HT;
					CLASS AGE /MLF;
					TABLE Age, HT * (RB050a * (PctSum Sum));
				RUN;

				PROC TABULATE data=work.idb out=Tp;
					FORMAT AGE f_age15.;
					VAR RB050a;
					CLASS HT;
					CLASS AGE /MLF;
					TABLE Age, HT * (RB050a * (PctSum Sum));
					WHERE &arpt = 1;
				RUN;

				PROC SQL;
				INSERT INTO li03 SELECT 
					"&Ucc" as geo,
					&yyyy as time,
					Ti.Age as hhtyp,
					"&libel"	as indic_il,
					"PC_POP" as unit,
					Ti.RB050a_PctSum_10 as ivalue,
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
				FROM Ti LEFT JOIN Tt ON (Ti.Age = Tt.Age and Tt.HT = 5) 
					    LEFT JOIN Tp ON (Ti.Age = Tp.Age and Tp.HT = 5)  
					LEFT JOIN work.old_flag ON ("&Ucc" = old_flag.geo) AND (Ti.Age = old_flag.hhtyp)
				AND ("&libel" = old_flag.indic_il)			
				WHERE &arpt=1;
				QUIT;

				* single by sex;
				PROC TABULATE data=work.idb out=Ti0;
					FORMAT RB090 f_sex.;
					VAR RB050a;
					CLASS RB090 /MLF;
					CLASS &arpt;
					TABLE &arpt, RB090 * (RB050a * (ColPctSum  N)) /printmiss;
					where HT = 5;
				RUN;
				PROC SQL;
					Create table Ti as
					select *,
						sum(RB050a_N) as ntot
					from Ti0
					group by RB090;
				QUIT;

				PROC TABULATE data=work.idb out=Tt;
					FORMAT RB090 f_sex.;
					VAR RB050a;
					CLASS HT;
					CLASS RB090 /MLF;
					TABLE RB090, HT * (RB050a * (PctSum Sum));
				RUN;

				PROC TABULATE data=work.idb out=Tp;
					FORMAT RB090 f_sex.;
					VAR RB050a;
					CLASS HT;
					CLASS RB090 /MLF;
					TABLE RB090, HT * (RB050a * (PctSum Sum));
					WHERE &arpt = 1;
				RUN;

				PROC SQL;
				INSERT INTO li03 SELECT 
					"&Ucc" as geo,
					&yyyy as time,
					Ti.RB090 as hhtyp,
					"&libel"	as indic_il,
					"PC_POP" as unit,
					Ti.RB050a_PctSum_10 as ivalue,
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
				FROM Ti LEFT JOIN Tt ON (Ti.RB090 = Tt.RB090 and Tt.HT = 5) 
					    LEFT JOIN Tp ON (Ti.RB090 = Tp.RB090 and Tp.HT = 5) 
				LEFT JOIN work.old_flag ON ("&Ucc" = old_flag.geo) AND (Ti.RB090 = old_flag.hhtyp)
				AND ("&libel" = old_flag.indic_il)				
				WHERE &arpt=1;
				QUIT;

				%mend f_li03;

%f_li03(ARPT60i,LI_R_MD60);
%f_li03(ARPT40i,LI_R_MD40);
%f_li03(ARPT50i,LI_R_MD50);
%f_li03(ARPT70i,LI_R_MD70);
%f_li03(ARPT60Mi,LI_R_M60);
%f_li03(ARPT40Mi,LI_R_M40);
%f_li03(ARPT50Mi,LI_R_M50);

* Update RDB;  

DATA  rdb.LI03;
set rdb.LI03(where=(not(time = &yyyy and geo = "&Ucc")))
    work.li03; 
run;  
%end;
%if &EU %then %do;

	* EU aggregates;

	%let tab=li03;
	%let grpdim=hhtyp,indic_il,unit;
	%EUVALS(&Ucc,&Uccs);
%end;

PROC SQL;  
     Insert into log.log
     set date = "&sysdate"d, time = "&systime"t, user = "&sysuserid",
		 report = "* &Ucc - &yyyy * LI03 (re)calculated *";		  
QUIT;

%end;
%else %do; 
PROC SQL;  
     Insert into log.log
     set date = "&sysdate"d, time = "&systime"t, user = "&sysuserid",
		 report = "* &Ucc - &yyyy * NO DATA !";		  
QUIT;
%end;

%mend UPD_li03;
