%macro UPD_li48(yyyy,Ucc,Uccs,flag) /store;
/* At-risk-of-poverty rate after deducting housing costs by degree of urbanisation */
/* Dimensions: GEO, TIME, DEG_URB */
/* created on 01/02/2012  Marina GRILLO  */
PROC DATASETS lib=work kill nolist;
QUIT;

%let cc=%lowcase(&Ucc);
%let yy=%substr(&yyyy,3,2);
%let tab=LI48;
 
%let EU=0;
%let var1=ARPT60ihc;
%if &Uccs=0 %then %let Uccs=("&Ucc");
%else %let EU=1;

Proc format;

VALUE poverty (multilabel)
		1 = "Poor"
	    0 = "Non Poor"
    other = ".";

VALUE f_urb (multilabel)
		1 = "DEG1"
		2 = "DEG2"
		3 = "DEG3"
		1-3 = "TOTAL"
		;
run;

* input datasets;
/*
%if &notBDB %then %do;
	libname in "&eusilc/&cc/c&yy"; 
	%let infil=c&cc&yy;
	%end;
%else %do;
	libname in "&eusilc/BDB"; 
	%let infil=BDB_c&yy;
	%end;
*/

%let not60=0;

%if &EU=0 %then %do;


    PROC SQL;
	CREATE TABLE  work.idb as
		select distinct a.DB010,a.DB020,a.RB030,a.DB030,a.RB050a,a.ARPT60ihc,a.EQ_INC20hc,
		d.DB100
	
		from idb.idb&yy  as a 
		
		LEFT JOIN in.&infil.d as d  ON (a.DB030 = d.DB030)and (a.DB010 = d.DB010)and (a.DB020 = d.DB020)
		where  a.DB010 = &year and a.DB020 in &Uccs  and d.DB100 ^= . and a.ARPT60ihc ^= .
	  ;
	quit; 



/* calculation LI48 indicators */ 
 
Proc sql;
Select distinct count(DB010) as N 
	into :nobs
	from  work.idb;
quit;
	
%if &nobs > 0
	%then %do;
**** MISSINGS *;
Proc sql;
CREATE TABLE nfilled AS SELECT DISTINCT DB020, (N(RB030)) AS N1 FROM work.idb WHERE arpt60ihc not is missing GROUP BY DB020;
CREATE TABLE nmissing AS SELECT DISTINCT DB020, (N(RB030)) AS N_1 FROM work.idb WHERE arpt60ihc is missing GROUP BY DB020;
CREATE TABLE marpt60ihc AS SELECT nfilled.DB020, (100/(N1+N_1)*N_1) AS marpt60ihc FROM nfilled LEFT JOIN nmissing ON (nfilled.DB020 = nmissing.DB020);

CREATE TABLE missunrel AS SELECT marpt60ihc.DB020, 
	 mARPT60ihc AS pcmiss
	FROM mARPT60ihc ;
quit;

PROC SQL;
CREATE TABLE work.old_flag AS SELECT
	geo,
	time, 
	DEG_URB,
	unit,
	ivalue,
	iflag
FROM rdb.&tab
WHERE geo in &Uccs  and time = &yyyy;
quit;

				PROC TABULATE data=work.idb out=Ti;
					FORMAT ARPT60ihc poverty.;
					FORMAT DB100 f_urb.;
					VAR RB050a;
					Class DB020;
					CLASS ARPT60ihc /MLF;
				    CLASS DB100 /MLF ;
					TABLE DB020*DB100, ARPT60ihc* (RB050a * (rowPctSum Sum N));
				RUN;

				PROC SQL; 
				create table &tab as SELECT 
					"&Ucc" as geo,
					&yyyy as time,
					ti.ARPT60ihc,
					Ti.DB100 as DEG_URB,
					"PC_POP" as unit,
					Ti.RB050a_PctSum_101 as ivalue,
						old_flag.iflag as iflag,
					(case when sum(Ti.RB050a_N) < 20 or missunrel.pcmiss > 50 then 2
		 			 when sum(Ti.RB050a_N) < 50 or missunrel.pcmiss > 20 then 1
		 			 else 0
	     			 end) as unrel,
					Ti.RB050a_N as n,
					sum(Ti.RB050a_N) as ntot,
					sum(Ti.RB050a_Sum) as totwgh, 
					"&sysdate" as lastup ,
					"&sysuserid" as	lastuser 
					FROM Ti  LEFT JOIN missunrel ON (Ti.DB020 = missunrel.DB020) 
					LEFT JOIN work.old_flag ON (Ti.DB020=old_flag.geo) AND (Ti.DB100=old_flag.DEG_URB)
					GROUP BY Ti.DB020, TI.DB100;
				QUIT; 
		 
* Update RDB;  
	%let tab=LI48;
	
	DATA  rdb.&tab(DROP=ARPT60ihc);
		set rdb.&tab(where=(not(time = &yyyy and geo = "&Ucc")))
		work.&tab(where=(ARPT60ihc="Poor")); 
	run;  
	
 	%end;
%end;

%if &EU %then %do;

* EU aggregates;

%let tab=LI48;
%let grpdim=DEG_URB,unit;
%EUVALS(&Ucc,&Uccs);

%end;

PROC SQL;  
     Insert into log.log
     set date = "&sysdate"d, time = "&systime"t, user = "&sysuserid",
		 report = "* &Ucc - &yyyy * LI48 (re)calculated *";		  
QUIT; 


%mend UPD_LI48;
