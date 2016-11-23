%macro UPD_lvho05q_06q(yyyy,Ucc,Uccs,flag,notBDB);
/*Overcrowding rate by quantile */
/*Overcrowding rate by quantile excluding single persons*/
/* created on 20/04/2013 */

PROC DATASETS lib=work kill nolist;
QUIT;

%let cc=%lowcase(&Ucc);
%let yy=%substr(&yyyy,3,2);
%let EU=0;
%let not60=0; 
%if &Uccs=0 %then %let Uccs=("&Ucc");
%else %let EU=1;

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


PROC FORMAT;
	value f_quantile (multilabel)
	    1="QUINTILE1" 
   		2= "QUINTILE2"
   		3= "QUINTILE3" 		
  		4="QUINTILE4" 
   		5="QUINTILE5"  
		1-5="TOTAL  ";
RUN;

%macro without_single (tabname);
%let not60=0;/* allows calculation of aggregates if less than 70% of pop*/
PROC SQL noprint;
Create table work.idb as 
	select distinct IDB.DB010, IDB.DB020, IDB.DB030,  IDB.RB030, IDB.RB050a,IDB.OVERCROWDED, IDB.qitile,IDB.HT1
	from idb.IDB&yy as IDB 	where  IDB.DB020 in &Uccs;

* calculate % missing values;
PROC SQL noprint;
CREATE TABLE nfilled AS SELECT DISTINCT DB020, (N(RB030)) AS N1 FROM work.idb WHERE OVERCROWDED not is missing GROUP BY DB020;
CREATE TABLE nmissing AS SELECT DISTINCT DB020, (N(RB030)) AS N_1 FROM work.idb WHERE OVERCROWDED is missing GROUP BY DB020;
CREATE TABLE mOVERCROWDED AS SELECT nfilled.DB020, (100/(N1+N_1)*N_1) AS mOVERCROWDED FROM nfilled LEFT JOIN nmissing ON (nfilled.DB020 = nmissing.DB020);

CREATE TABLE missunrel AS SELECT mOVERCROWDED.DB020, 
				max(mOVERCROWDED,0) AS pcmiss
	FROM mOVERCROWDED;
QUIT;

* &tabname.a Overcrowding rate by age gender and income group
* calc values, N and total weights;
%if &tabname=lvho05 %then %do;
%let tab=&tabname.q;
	DATA WORK.idb1;
	set work.idb;
RUN;
%end;
%else %if &tabname=lvho06 %then %do;
	%let tab=&tabname.q;
	DATA WORK.idb1;
	set work.idb;
	where HT1  not in (1,2,3,4); 
	RUN;
%end;

proc sql;
Select distinct count(DB010) as N 
	into :nobs
	from  work.idb1;
QUIT;

%if &nobs > 0
%then %do;

PROC TABULATE data=work.idb1 out=Ti;
		FORMAT qitile f_quantile.;
		
		CLASS DB010;
		CLASS DB020;
		CLASS OVERCROWDED;
		CLASS qitile /MLF;
		
		
	VAR RB050a;
	TABLE DB010 * DB020 * qitile, OVERCROWDED * RB050a * (RowPctSum N Sum) /printmiss;
RUN;

* fill RDB variables;
PROC SQL;
CREATE TABLE work.old_flag AS
SELECT 
      time,
      geo,
	  quantile,
   	  iflag
FROM rdb.&tab
WHERE  time = &yyyy ;

CREATE TABLE work.&tab AS
SELECT 
	Ti.DB020 as geo FORMAT=$5. LENGTH=5,
	Ti.DB010 as time,
	Ti.qitile as quantile,
	ti.OVERCROWDED,
	"PC_POP" as unit,
	Ti.RB050a_PctSum_1101 as ivalue, 
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
FROM Ti LEFT JOIN missunrel ON (Ti.DB020 = missunrel.DB020)
		LEFT JOIN work.old_flag ON (Ti.DB020 = old_flag.geo) 
	AND (Ti.qitile = old_flag.quantile) 
		
GROUP BY Ti.DB020, Ti.qitile;
	QUIT;

* Update RDB;
DATA  rdb.&tab(drop=OVERCROWDED);
set rdb.&tab(where=(not(time = &yyyy and geo in &Uccs)))
work.&tab(where=(OVERCROWDED = 1)) ; 
RUN;
%end;

%else %do; 
PROC SQL;  
     Insert into log.log
     set date = "&sysdate"d, time = "&systime"t, user = "&sysuserid",
		 report = "* &Ucc - &yyyy * NO DATA !";		  
QUIT;
%end;
%mend without_single;

%without_single(lvho05);
%without_single(lvho06);

%end;


* EU aggregates;
%if &EU %then
	%do;
		%let tab=lvho05q;
		%let grpdim=quantile, unit;

		%EUVALS(&Ucc,&Uccs);

		%if &euok = 0 and &EU %then
			%do;

				PROC SQL;
					Insert into log.log
						set date = "&sysdate"d, time = "&systime"t, user = "&sysuserid",
							report = "* &Ucc - &yyyy * NO enought countries available! ";
				QUIT;

			%end;
		%else
			%do;

				PROC SQL;
					Insert into log.log
						set date = "&sysdate"d, time = "&systime"t, user = "&sysuserid",
							report = "* &Ucc - &yyyy * lvho05q (re)calculated *";
				QUIT;

			%end;

		%let tab=lvho06q;
		%let grpdim=quantile, unit;

		%EUVALS(&Ucc,&Uccs);

		%if &euok = 0 and &EU %then
			%do;

				PROC SQL;
					Insert into log.log
						set date = "&sysdate"d, time = "&systime"t, user = "&sysuserid",
							report = "* &Ucc - &yyyy * NO enought countries available! ";
				QUIT;

			%end;
		%else
			%do;

				PROC SQL;
					Insert into log.log
						set date = "&sysdate"d, time = "&systime"t, user = "&sysuserid",
							report = "* &Ucc - &yyyy * lvho06q (re)calculated *";
				QUIT;

			%end;
	%end;


%let not60=0;
%mend UPD_lvho05q_06q;
