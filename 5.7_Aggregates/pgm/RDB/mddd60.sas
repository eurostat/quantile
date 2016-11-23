*** sev_dep by maximun level of education of mather or father ***;
/* flags are taken from the existing data set  on 03/12/2012 */
%macro UPD_mddd60(yyyy,Ucc,Uccs,flag);

PROC DATASETS lib=work kill nolist;
QUIT;
/*
libname in "&eusilc/BDB"; 
*/
%let tab=mddd60;
%let cc=%lowcase(&Ucc);
%let yy=%substr(&yyyy,3,2);

%let EU=0;
%if &Uccs=0 %then %let Uccs=("&Ucc");
%else %let EU=1; 

*** At-risk-poverty-rate by age and education level of the parente ***;
PROC FORMAT;
    VALUE f_age (multilabel)

		0 - 5 = "Y_LT6"
		6 - 11 = "Y6-11"
		12 - 17 = "Y12-17"	
	    0-17 = "Y_LT18";
			
	VALUE f_educ (multilabel)
		0 - 2 = "ED0-2"
		3 - 4 = "ED3_4"
		5 - 6 = "ED5_6"
		
		;
RUN;
PROC SQL noprint;
Create table work.idb as 
	select idb.DB010, idb.DB020, idb.DB030, idb.RB030, idb.RB050a, idb.sev_dep,  idb.Age, idb.HHISCED  
           
		      
	FROM idb.idb&yy as idb 
		   
	 where  idb.age lt 18 and  idb.hhisced between 0 and 6 and idb.DB010 = &yyyy and idb.DB020 in &Uccs;

	
Select distinct count(DB010) as N 
	into :nobs
	from  work.idb;
Create table work.&tab like rdb.&tab; 
QUIT;


* calculate % missing values;
PROC SQL noprint;

CREATE TABLE nfilled AS SELECT DISTINCT DB020, (N(RB030)) AS N1 FROM work.idb WHERE sev_dep not is missing GROUP BY DB020;
CREATE TABLE nmissing AS SELECT DISTINCT DB020, (N(RB030)) AS N_1 FROM work.idb WHERE sev_dep is missing GROUP BY DB020;
CREATE TABLE msev_dep AS SELECT nfilled.DB020, (100/(N1+N_1)*N_1) AS msev_dep FROM nfilled LEFT JOIN nmissing ON (nfilled.DB020 = nmissing.DB020);

CREATE TABLE nfilled AS SELECT DISTINCT DB020, (N(RB030)) AS N1 FROM work.idb  WHERE hhisced not is missing GROUP BY DB020;
CREATE TABLE nmissing AS SELECT DISTINCT DB020, (N(RB030)) AS N_1 FROM work.idb  WHERE hhisced is missing GROUP BY DB020;
CREATE TABLE mhhisced AS SELECT nfilled.DB020, (100/(N1+N_1)*N_1) AS mhhisced FROM nfilled LEFT JOIN nmissing ON (nfilled.DB020 = nmissing.DB020);

CREATE TABLE missunrel AS SELECT msev_dep.DB020, 
	max( msev_dep, mhhisced) AS pcmiss
	FROM msev_dep 
	LEFT JOIN mhhisced ON (msev_dep.DB020 = mhhisced.DB020);
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
group by time, geo , age,isced97 ;

QUIT;

%if &EU =0 %then %do;			
%let var=RB050a;
%LET VARi=hhisced;
	PROC TABULATE data=work.idb  out=Ti;
	FORMAT AGE  f_age.;
	FORMAT  &vari f_educ15.; 
	CLASS DB020;
	CLASS AGE /MLF;
	CLASS SEV_DEP ;
	CLASS &vari /MLF; ;
	VAR &var;
	TABLE DB020 * AGE *&vari, sev_dep * &var * (RowPctSum N Sum) /printmiss;
RUN;

	proc sql;		 
			CREATE TABLE work.&tab AS
SELECT 
	Ti.DB020 as geo FORMAT=$5. LENGTH=5,
	&yyyy as time,
	Ti.Age,
	ti.SEV_DEP as sev_dep,
	&vari as isced97,
	"PC_POP" as unit,
	Ti.&var._PctSum_1101 as ivalue,
	old_flag.iflag as iflag,

	(case when sum(Ti.&var._N) < 20 or missunrel.pcmiss > 50 then 2
		  when sum(Ti.&var._N) < 50 or missunrel.pcmiss > 20 then 1
		  else 0
	      end) as unrel,
	Ti.&var._N as n,
	sum(Ti.&var._N) as ntot,
	sum(Ti.&var._Sum) as totwgh,
	"&sysdate" as lastup,
	"&sysuserid" as	lastuser 
FROM Ti LEFT JOIN missunrel ON (Ti.DB020 = missunrel.DB020)
  left  JOIN work.old_flag ON (Ti.DB020 = old_flag.geo) 
	 AND (Ti.Age = old_flag.Age) 
	AND (Ti.&vari = old_flag.isced97) 
GROUP BY Ti.DB020,  ti.AGE, ti.&vari;
	QUIT;
	 			 								
* Update RDB;  
DATA  rdb.mddd60(drop= SEV_DEP);
set rdb.mddd60(where=(not(time = &yyyy and geo = "&Ucc" )))
    work.mddd60;
	where SEV_DEP=1;
RUN;
 
%end;
%if &EU %then %do;

	* EU aggregates;

	%let tab=mddd60;
	%let grpdim=age,isced97 ,unit;
	%EUVALS(&Ucc,&Uccs);
%end;
PROC SQL;  
     Insert into log.log
     set date = "&sysdate"d, time = "&systime"t, user = "&sysuserid",
		 report = "* &Ucc - &yyyy * mddd60 (re)calculated *";		  
QUIT;

%end;
%else %do; 
PROC SQL;  
     Insert into log.log
     set date = "&sysdate"d, time = "&systime"t, user = "&sysuserid",
		 report = "* &Ucc - &yyyy * NO DATA !";		  
QUIT;
%end;

%mend UPD_mddd60;
