*** At-risk-poverty-rate by maximun level of education of mather or father ***;
/* flags are taken from the existing data set  on 31/10/2012 */
%macro UPD_li60(yyyy,Ucc,Uccs,flag) /store;

PROC DATASETS lib=work kill nolist;
QUIT;
/*
libname in "&eusilc/BDB"; 
*/
%let tab=LI60;
%let cc=%lowcase(&Ucc);
%let yy=%substr(&yyyy,3,2);
%let EU=0;
%if &Uccs=0 %then %let Uccs=("&Ucc");
%else %let EU=1; 

*** At-risk-poverty-rate by age and gender ***;
PROC FORMAT;
    VALUE f_age (multilabel)

		0 - 5 = "Y_LT6"
		6 - 11 = "Y6-11"
		12 - 17 = "Y12-17"	
	    0-17="Y_LT18"
		
		;

	VALUE f_educ (multilabel)
		0 - 2 = "ED0-2"
		3 - 4 = "ED3_4"
		5 - 6 = "ED5_6"
	
		;
RUN;
PROC SQL noprint;
Create table work.idb as 
	select idb.DB010, idb.DB020, idb.DB030, idb.RB030, idb.AGE, idb.RB050a, idb.ARPT60i, idb.HHISCED 
         
	FROM idb.idb&yy as idb 
		 where  idb.age lt 18 and idb.hhisced between 0 and 6 and idb.DB010 = &yyyy and idb.DB020 in &Uccs;

	
Select distinct count(DB010) as N 
	into :nobs
	from  work.idb;
*Create table work.li60 like rdb.li60; 
QUIT;
		
	* calculate % missing values;
PROC SQL noprint;

CREATE TABLE nfilled AS SELECT DISTINCT DB020, (N(RB030)) AS N1 FROM work.idb WHERE ARPT60i not is missing GROUP BY DB020;
CREATE TABLE nmissing AS SELECT DISTINCT DB020, (N(RB030)) AS N_1 FROM work.idb WHERE ARPT60i is missing GROUP BY DB020;
CREATE TABLE mARPT60i AS SELECT nfilled.DB020, (100/(N1+N_1)*N_1) AS mARPT60i FROM nfilled LEFT JOIN nmissing ON (nfilled.DB020 = nmissing.DB020);

CREATE TABLE nfilled AS SELECT DISTINCT DB020, (N(RB030)) AS N1 FROM work.idb WHERE hhisced not is missing GROUP BY DB020;
CREATE TABLE nmissing AS SELECT DISTINCT DB020, (N(RB030)) AS N_1 FROM work.idb WHERE hhisced is missing GROUP BY DB020;
CREATE TABLE mhhisced AS SELECT nfilled.DB020, (100/(N1+N_1)*N_1) AS mhhisced FROM nfilled LEFT JOIN nmissing ON (nfilled.DB020 = nmissing.DB020);

CREATE TABLE missunrel AS SELECT mARPT60i.DB020, 
	max( mARPT60i, mhhisced) AS pcmiss
	FROM mARPT60i 
	LEFT JOIN mhhisced ON (mARPT60i.DB020 = mhhisced.DB020);
QUIT;		
		
		
%if &nobs > 0
%then %do;
proc sql;
CREATE TABLE work.old_flag AS
SELECT distinct
      time,
      geo,
	  age,
	  isced97,
	  iflag
	  FROM rdb.&tab
WHERE  time = &yyyy and geo="&Ucc"  
group by time, geo , age, isced97 ;

QUIT;

	PROC TABULATE data=work.idb out=Ti;
	FORMAT AGE f_age15.;
	FORMAT hhisced f_educ.;
	VAR RB050a;
	CLASS AGE /MLF;
	CLASS hhisced /MLF;
	CLASS ARPT60i;
	TABLE  AGE * hhisced, ARPT60i *(RB050a * (RowPctSum Sum N)) /printmiss;
	RUN;



				%macro by_unit(unit,ival); 
				 	PROC SQL;
					Create Table work.li60 as SELECT 
						"&Ucc" as geo,
						&yyyy as time,
						Ti.Age,
						Ti.hhisced as isced97,
						Ti.ARPT60i as arpt60i,
						"&unit" as unit ,
						Ti.&ival as ivalue,
						old_flag.iflag as iflag, 
						(case when sum(Ti.RB050a_N) < 20 or missunrel.pcmiss > 50 then 2
						when sum(Ti.RB050a_N) < 50 or missunrel.pcmiss > 20 then 1
						else 0
						end) as unrel,
						Ti.RB050a_N as n,
						sum(Ti.RB050a_N) as ntot,
						sum(Ti.RB050a_Sum) as totwgh,
					    "&sysdate" as lastup,
						"&sysuserid" as	lastuser 
					FROM Ti LEFT JOIN missunrel ON ("&Ucc" = missunrel.DB020)
							LEFT JOIN work.old_flag ON ("&Ucc" = old_flag.geo) 
					       AND (TI.hhisced = old_flag.isced97)  AND (Ti.Age  = old_flag.age)
						GROUP BY  ti.age, ti.hhisced
						order by  ti.age, ti.hhisced
					;
					QUIT;
										
				%mend by_unit;
					%by_unit(PC_POP,RB050a_PctSum_110);
					
			
%if &EU =0 %then %do;

 

* Update RDB; 
DATA  rdb.LI60 (drop=arpt60i);
set rdb.LI60(where=(not(time = &yyyy and geo = "&Ucc")))
    work.li60;
	where ARPT60i=1; 
run; 
%end;
%if &EU %then %do;

	* EU aggregates;

	%let tab=li60;
	%let grpdim=age,isced97 ,unit;
	%EUVALS(&Ucc,&Uccs);
%end;
PROC SQL;  
     Insert into log.log
     set date = "&sysdate"d, time = "&systime"t, user = "&sysuserid",
		 report = "* &Ucc - &yyyy * LI60 (re)calculated *";		  
QUIT;

%end;
%else %do; 
PROC SQL;  
     Insert into log.log
     set date = "&sysdate"d, time = "&systime"t, user = "&sysuserid",
		 report = "* &Ucc - &yyyy * NO DATA !";		  
QUIT;
%end;

%mend UPD_li60;
