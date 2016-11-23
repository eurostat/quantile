%macro UPD_lvho50(yyyy,Ucc,Uccs,flag,notBDB);
/****************************************************************************************************************/
/* Share of people living in under-occupied dwellings                                                           */
/*                                                                                                              */
/*    =1 if HH030 > 2+sum of room needed                                                                        */
/*    =0 if HH030 <= 2+ sum of room needed                                                                      */
/*    =. if HH030=.                                                                                             */ 
/* version 30/11/2013                                                                                           */ 
/****************************************************************************************************************/
/*20141106MG to check if working datasets IDB is empty */
PROC DATASETS lib=work kill nolist;
QUIT;

%let cc=%lowcase(&Ucc);
%let yy=%substr(&yyyy,3,2);
%let EU=0;
%let tabname=lvho50;

/* to check if the  result is fine */
%let c_obsa=0;
%let c_obsb=0;
%let c_obsc=0;
%let c_obsd=0;
%let nobs=0;
%let nobsx=0;
%let DB100Missing=0;


%if &Uccs=0 %then %let Uccs=("&Ucc");
%else %let EU=1;
 

%let var=UNDERCROWDED;
PROC FORMAT;
VALUE f_age (multilabel)
		0 - 17 = "Y_LT18"
		18 - 64 = "Y18-64"
		65 - HIGH = "Y_GE65"
		0 - HIGH = "TOTAL"
		;
		

VALUE f_sex (multilabel)
		1 = "M"
		2 = "F"
		1 - 2 = "T"
		;
VALUE ftensta(multilabel)
		1,2 = "TOTAL"
		1 = "OWN"
		2 = "RENT";
		
VALUE f_ht (multilabel)
        1 - 8 = "HH_NDCH"
		9 - 13 = "HH_DCH"
		9 =	 "A1_DCH"
		10 = "A2_1DCH"
		11 = "A2_2DCH"
		12 = "A2_GE3DCH"
		13 = "A_GE3_DCH"
		10 - 13 ="A_GE2_DCH"
		1 - 13 = "TOTAL";	
value f_quantile (multilabel)
	    1="QUINTILE1" 
   		2= "QUINTILE2"
   		3= "QUINTILE3" 		
  		4="QUINTILE4" 
   		5="QUINTILE5"  
		1-5="TOTAL  ";	
		
VALUE f_urb (multilabel)
		1 = "DEG1"
		2 = "DEG2"
		3 = "DEG3"
		
		;		
VALUE f_incgrp (multilabel)
		0,1 = "TOTAL"
		0 = "A_MD60"
		1 = "B_MD60"
		;
run;
%let not60=0;

%if &EU=0 %then %do;
	/*20141210MG  to check if  DB100 variable  is in D-PDB file:   */

data FDB100;set in.&infil.d;where DB020 in &Uccs;run;   /*20141106MG to check if working datasets IDB is empty */

Proc sql;                                   
Select distinct count(DB010) as N 
	into :nobs
	from  FDB100;
quit;

PROC MEANS DATA=FDB100 	NWAY 	N  	NMISS	;
	VAR DB100;
	CLASS DB020 ;
OUTPUT 	OUT=WORK.NUMMIS
		N()= 
		NMISS()=
	 / AUTONAME AUTOLABEL  WAYS INHERIT
	;
RUN;
Proc sql;                                                
Select distinct DB100_NMiss  as Nn  
	into :NM
	from  work.NUMMIS ;
quit;

%if &nobs=&Nm %then %let DB100Missing=1;


/* End step to check if  DB100 variable is in D-PDB file*/


/*characterize people*/
 PROC SQL;
 CREATE TABLE work.temp1 AS SELECT IDB.DB010, IDB.DB020,IDB.DB030, IDB.RB030,IDB.RB050a, IDB.AGE, IDB.RB090,IDB.HT1,IDB.TENSTA,d.DB100,
	 r.RB240_F, h.HH030, h.HH030_F,	IDB.ARPT60i,IDB.qitile,
      %if &DB100Missing=0 %then  %do ;
			  d.DB100, 
		  %end;


	 (CASE WHEN r.RB240_F=1 AND IDB.AGE >= 18 THEN 1 ELSE 0 END) as ADULT_PARTNER,
(CASE WHEN r.RB240_F ne 1 AND IDB.AGE >= 18 THEN 1 ELSE 0 END) as ADULT_SINGLE,
(CASE WHEN IDB.AGE <=11 THEN 1 ELSE 0 END) as CHILD_LESS_12,
(CASE WHEN IDB.AGE >= 12 AND IDB.AGE <= 17 AND IDB.RB090=1 THEN 1 ELSE 0 END) as TEENAGE_MALE,
(CASE WHEN IDB.AGE >= 12 AND IDB.AGE <= 17 AND IDB.RB090=2 THEN 1 ELSE 0 END) as TEENAGE_FEMALE
 FROM idb.idb&yy  AS IDB 
 left join in.&infil.r as r on (idb.DB010 = r.RB010) and (idb.DB020 = r.rB020) and (idb.RB030 = r.rB030)
 left join in.&infil.h as h on (idb.DB010 = h.HB010) and (idb.DB020 = h.HB020) and (idb.DB030 = h.HB030)
 left join in.&infil.d as d on (IDB.DB020 = d.DB020 and IDB.DB030 = d.DB030)
		%if &DB100Missing=0 %then %do;
		where d.DB100 in (1,2,3) and IDB.HT1 between 1 and 13 and IDB.DB020 in &Uccs;;
		%end;
		%else  %do;
		where  IDB.HT1 between 1 and 13 and IDB.DB020 in &Uccs;;
		%end;
 QUIT;
 
/* calculate UNDERCROWDED variable */

PROC SQL;
        
         CREATE TABLE WORK.idb AS SELECT DISTINCT temp1.DB010,temp1.DB020, temp1.RB050a,temp1.DB030,temp1.RB030,temp1.rb090,temp1.age,temp1.arpt60i,
		 temp1.HT1,temp1.TENSTA,temp1.DB100,temp1.qitile,
       
       	 (CEIL(SUM(temp1.ADULT_PARTNER)/2)) AS COUPLE_ROOM,
       
        	 (SUM(temp1.ADULT_SINGLE)) AS SUM_OF_ADULT_SINGLE,
       
       	 (CEIL(SUM(temp1.CHILD_LESS_12)/2))  AS CHILD_ROOM,
        
        	 (CEIL(SUM(temp1.TEENAGE_MALE)/2)) AS TEEN_MALE_ROOM,
        
        	 (CEIL(SUM(temp1.TEENAGE_FEMALE) / 2)) AS TEEN_FEMALE_ROOM,
        
        	 (CASE WHEN  HH030 >
       
        		(2 + CALCULATED COUPLE_ROOM +  CALCULATED SUM_OF_ADULT_SINGLE +  CALCULATED
        
         CHILD_ROOM +  CALCULATED TEEN_MALE_ROOM +  CALCULATED TEEN_FEMALE_ROOM)
        
        		 THEN 1 ELSE 0 END ) AS UNDERCROWDED,
        
       		  "&sysdate" as LASTADD
        
        		
        
         FROM WORK.temp1 AS temp1
        
        
        
         WHERE temp1.HH030 >0
        
         GROUP BY temp1.DB020, temp1.DB030;      
QUIT;	

* calculate % missing values;
PROC SQL noprint;
CREATE TABLE nfilled AS SELECT DISTINCT DB020, (N(RB030)) AS N1 FROM work.idb WHERE UNDERCROWDED not is missing GROUP BY DB020;
CREATE TABLE nmissing AS SELECT DISTINCT DB020, (N(RB030)) AS N_1 FROM work.idb WHERE UNDERCROWDED is missing GROUP BY DB020;
CREATE TABLE mUNDERCROWDED AS SELECT nfilled.DB020, (100/(N1+N_1)*N_1) AS mUNDERCROWDED FROM nfilled LEFT JOIN nmissing ON (nfilled.DB020 = nmissing.DB020);

CREATE TABLE missunrel AS SELECT mUNDERCROWDED.DB020, 
				max(mUNDERCROWDED,0) AS pcmiss
	FROM mUNDERCROWDED;
QUIT;




/* Share of people living in under-occupied dwellings by age, sex and poverty status - Total population */
%let tab=&tabname.a;
PROC TABULATE data=work.idb out=Ti;
		FORMAT AGE f_age15.;
		FORMAT RB090 f_sex.;
		FORMAT ARPT60i  f_incgrp15.;
		CLASS DB010;
		CLASS DB020;
		CLASS UNDERCROWDED;
		CLASS AGE /MLF;
		CLASS RB090 /MLF;
		CLASS ARPT60i /MLF;
		
	VAR RB050a;
	TABLE DB010 * DB020 * AGE * RB090 * ARPT60i, UNDERCROWDED * RB050a * (RowPctSum N Sum) /printmiss;
RUN;

* fill RDB variables;
PROC SQL;
CREATE TABLE work.old_flag AS
SELECT 
      time,
      geo,
	  age,
	  sex,
	  incgrp,
   	  iflag
FROM rdb.&tab
WHERE  time = &yyyy ;

CREATE TABLE work.&tab AS
SELECT 
	Ti.DB020 as geo FORMAT=$5. LENGTH=5,
	Ti.DB010 as time,
	Ti.Age,
	Ti.RB090 as sex,
	ti.ARPT60i as incgrp,
	"PC_POP" as unit,
	ti.UNDERCROWDED,
	Ti.RB050a_PctSum_110111 as ivalue, 
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
	    AND (Ti.age = old_flag.age) AND (Ti.RB090  = old_flag.sex) 
	    AND (Ti.ARPT60i  = old_flag.incgrp)
GROUP BY Ti.DB020, ti.AGE, ti.RB090, Ti.ARPT60i;

	QUIT;

* Update RDB;
DATA  rdb.&tab(drop=UNDERCROWDED);
set rdb.&tab(where=(not(time = &yyyy and geo in &Uccs)))
work.&tab(where=(UNDERCROWDED = 1)) ; 
RUN;
%put +UPDATED &tab;

/* Share of people living in under-occupied dwellings by age, sex and poverty status - Total population */
%let tab=&tabname.b;
PROC TABULATE data=work.idb out=Ti;
		FORMAT qitile f_quantile.;
		FORMAT HT1 f_ht.;
		CLASS DB010;
		CLASS DB020;
		CLASS UNDERCROWDED;
		CLASS qitile /MLF;
		CLASS HT1 /MLF;
	 	
	VAR RB050a;
	TABLE DB010 * DB020 * qitile * ht1 , UNDERCROWDED * RB050a * (RowPctSum N Sum) /printmiss;
RUN;

* fill RDB variables;
PROC SQL;
CREATE TABLE work.old_flag AS
SELECT 
      time,
      geo,
	  quantile,
	  hhtyp,
	  iflag
FROM rdb.&tab
WHERE  time = &yyyy ;

CREATE TABLE work.&tab AS
SELECT 
	Ti.DB020 as geo FORMAT=$5. LENGTH=5,
	Ti.DB010 as time,
	Ti.qitile as quantile,
	Ti.HT1 as HHTYP,
	"PC_POP" as unit,
	ti.UNDERCROWDED,
	Ti.RB050a_PctSum_11011 as ivalue, 
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
	    AND (Ti.qitile  = old_flag.quantile) 
	    AND (Ti.ht1  = old_flag.hhtyp)
GROUP BY Ti.DB020, ti.qitile, ti.ht1;

	QUIT;

* Update RDB;
DATA  rdb.&tab(drop=UNDERCROWDED);
set rdb.&tab(where=(not(time = &yyyy and geo in &Uccs)))
work.&tab(where=(UNDERCROWDED = 1)) ; 
RUN;
%put +UPDATED &tab;

/* Share of people living in under-occupied dwellings by tenure status - Total population */
%let tab=&tabname.c;
PROC TABULATE data=work.idb out=Ti;
		FORMAT tensta ftensta.;
		CLASS DB010;
		CLASS DB020;
		CLASS UNDERCROWDED;
		CLASS tensta /MLF;
	VAR RB050a;
	TABLE DB010 * DB020 * tensta , UNDERCROWDED * RB050a * (RowPctSum N Sum) /printmiss;
RUN;

* fill RDB variables;
PROC SQL;
CREATE TABLE work.old_flag AS
SELECT 
      time,
      geo,
	  tenure,
	  iflag
FROM rdb.&tab
WHERE  time = &yyyy ;

CREATE TABLE work.&tab AS
SELECT 
	Ti.DB020 as geo FORMAT=$5. LENGTH=5,
	Ti.DB010 as time,
	Ti.tensta as tenure,
	"PC_POP" as unit,
	ti.UNDERCROWDED,
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
	    AND (Ti.tensta  = old_flag.tenure) 
	GROUP BY Ti.DB020, ti.tensta;

	QUIT;

* Update RDB;
DATA  rdb.&tab(drop=UNDERCROWDED);
set rdb.&tab(where=(not(time = &yyyy and geo in &Uccs)))
work.&tab(where=(UNDERCROWDED = 1)) ; 
RUN;
%put +UPDATED &tab;


/* Share of people living in under-occupied dwellings by degree of urbanisation - Total population */
%let tab=&tabname.d;

%if &DB100Missing=0	%then %do; /* 20141106MG  NO DB100 missing  */

PROC TABULATE data=work.idb out=Ti;
		FORMAT DB100 f_urb.;
		CLASS DB010;
		CLASS DB020;
		CLASS UNDERCROWDED;
		CLASS DB100 /MLF;
	VAR RB050a;
	TABLE DB010 * DB020 * DB100 , UNDERCROWDED * RB050a * (RowPctSum N Sum) /printmiss;
RUN;

* fill RDB variables;
PROC SQL;
CREATE TABLE work.old_flag AS
SELECT 
      time,
      geo,
	  deg_urb,
	  iflag
FROM rdb.&tab
WHERE  time = &yyyy ;

CREATE TABLE work.&tab AS
SELECT 
	Ti.DB020 as geo FORMAT=$5. LENGTH=5,
	Ti.DB010 as time,
    ti.db100 as deg_urb,
	"PC_POP" as unit,
	ti.UNDERCROWDED,
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
	    AND (Ti.db100  = old_flag.deg_urb) 
	GROUP BY Ti.DB020, ti.db100;

	QUIT;

* Update RDB;
DATA  rdb.&tab(drop=UNDERCROWDED);
set rdb.&tab(where=(not(time = &yyyy and geo in &Uccs)))
work.&tab(where=(UNDERCROWDED = 1)) ; 
RUN;
%put +UPDATED &tab;

%end;
%end;
* EU aggregates;

%if &EU %then %do;

%let tab=&tabname.a;
%let grpdim=age, sex, incgrp, unit;
%EUVALS(&Ucc,&Uccs);

%let tab=&tabname.b;
%let grpdim=quantile, hhtyp, unit;
%EUVALS(&Ucc,&Uccs);

%let tab=&tabname.c;
%let grpdim=tenure, unit;
%EUVALS(&Ucc,&Uccs);

%let tab=&tabname.d;
%let grpdim=deg_urb, unit;
%EUVALS(&Ucc,&Uccs);
%end;

%if &nobs >0 %then %do;
	proc sql noprint;
			select count(*) into :c_obsa from lvho50a;
	quit;
 	proc sql noprint;
			select count(*) into :c_obsb from lvho50b;
	quit;
	proc sql noprint;
			select count(*) into :c_obsc from lvho50c;
	quit;
	%if   %sysfunc(exist(lvho50d)) %then %do;
	proc sql noprint;
			select count(*) into :c_obsd from lvho50d;
	quit;
	%end;
%end; 

%if &c_obsa > 0 %then %do;
PROC SQL;  
     Insert into log.log
     set date = "&sysdate"d, time = "&systime"t, user = "&sysuserid",
		 report = "* &Ucc - &yyyy * lvho50a  (re)calculated *";
	QUIT;
%end;
%if &c_obsb > 0 %then %do;
	PROC SQL;  
     Insert into log.log
     set date = "&sysdate"d, time = "&systime"t, user = "&sysuserid",
		 report = "* &Ucc - &yyyy * lvho50b  (re)calculated *";
	QUIT;
	%end;
%if &c_obsc > 0 %then %do;
	PROC SQL;  
     Insert into log.log
     set date = "&sysdate"d, time = "&systime"t, user = "&sysuserid",
		 report = "* &Ucc - &yyyy * lvho50c (re)calculated *";
	QUIT;
%end;
%if &c_obsd > 0 %then %do;
	PROC SQL;  
     Insert into log.log
     set date = "&sysdate"d, time = "&systime"t, user = "&sysuserid",
		 report = "* &Ucc - &yyyy * lvho50d (re)calculated *";
	QUIT;
%end;

%let not60=0;
%mend UPD_lvho50;
