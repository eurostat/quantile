*** share of people by age and sex, having equivalised income of 1.3 times the median or MORE, having 1.4 times the median or more etc…
 ***;
%macro UPD_di20(yyyy,Ucc,Uccs,flag) /store;

PROC DATASETS lib=work kill nolist;
QUIT;

%let tab=di20;
%let cc=%lowcase(&Ucc);
%let yy=%substr(&yyyy,3,2);
%let EU=0;
%if &Uccs=0 %then %let Uccs=("&Ucc");
%else %let EU=1; 

*** At-risk-poverty-rate by age and gender ***;
PROC FORMAT;
    VALUE f_age (multilabel)
		0 - 18 = "Y_LT18"
		18 - 64 = "Y18-64"
		65 - HIGH = "Y_GE65"
		0 - HIGH = "TOTAL"
		;

	VALUE f_sex (multilabel)
		1 = "M"
		2 = "F"
		1 - 2 = "T";
		
	VALUE f_arpt (multilabel)
		0 = "Below"
		1 = "Above"
	;
RUN;
PROC SQL noprint;
Create table work.idb1 as 
	select DB010, DB020, DB030, RB030, RB050a, Age, RB090,MEAN20, MEDIAN20,EQ_INC20,
	(MEDIAN20 * 1.3) as ARPT13, 

	(MEDIAN20 * 1.4) as ARPT14, 

	(MEDIAN20 * 1.5) as ARPT15, 

	(MEDIAN20 * 1.6) as ARPT16,

	(MEAN20 * 1.4) as ARPT14M, 

	(MEAN20 * 1.3) as ARPT13M, 

	(MEAN20 * 1.5) as ARPT15M 

	from idb.IDB&yy
	where age ge 0 and DB010 = &yyyy and DB020 in &Uccs;
	quit;

PROC SQL;
Create table idb as
select idb1.*,
       (case
	    when EQ_INC20 > ARPT13 then 1
		else 0
		end) as ARPT13i,
	   (case
	    when EQ_INC20 > ARPT14 then 1
		else 0
		end) as ARPT14i,
	   (case
	    when EQ_INC20 > ARPT15 then 1
		else 0
		end) as ARPT15i,
		(case
	    when EQ_INC20 > ARPT16 then 1
		else 0
		end) as ARPT16i,
       (case
	    when EQ_INC20 > ARPT15M then 1
    	else 0
		end) as ARPT15Mi,
	   (case
	    when EQ_INC20 > ARPT14M then 1
		else 0
		end) as ARPT14Mi,
	   (case
	    when EQ_INC20 > ARPT13M then 1
		else 0
		end) as ARPT13Mi
		
		from work.idb1 ;

QUIT;

	proc sql;
Select distinct count(DB010) as N 
	into :nobs
	from  work.idb;
Create table work.di20 like rdb.di20; 
QUIT;

%if &nobs > 0
%then %do;
proc sql;
CREATE TABLE work.old_flag AS
SELECT distinct
      time,
      geo,
	  age,
	  sex,
	  indic_il,
	  unit,
	  iflag
	  FROM rdb.&tab
WHERE  time = &yyyy and geo="&Ucc"  
group by time, geo , age, sex, indic_il, unit ;

QUIT;
%let var=RB050a;
			%macro f_di20(arpt,libel);

					

* calc values, N and total weights;
PROC TABULATE data=work.idb out=Ti;
		FORMAT AGE f_age15.;
						FORMAT RB090 f_sex.;
						FORMAT &arpt f_arpt.;
						VAR RB050a;
						CLASS DB020;
						CLASS AGE /MLF;
						CLASS RB090 /MLF;
						CLASS &arpt /MLF;
	TABLE DB020 * AGE * RB090, &arpt  * &var * (RowPctSum N Sum) /printmiss;
RUN;

				%macro by_unit(unit,ival); 
				proc sql;
				 	CREATE TABLE work.test AS
					SELECT 
						Ti.DB020 as geo FORMAT=$5. LENGTH=5,
	       				&yyyy as time,
						Ti.Age,
						Ti.RB090 as sex,
						"&libel" as indic_il,
						ti.&arpt as &arpt,
						"&unit" as unit ,
						Ti.&ival as ivalue,
						old_flag.iflag as iflag, 
						(case when sum(Ti.&var._N) < 20 then 2
							  when sum(Ti.&var._N) < 50 then 1
							  else 0
						      end) as unrel,
					Ti.&var._N as n,
					sum(Ti.&var._N) as ntot,
					sum(Ti.&var._Sum) as totwgh,
					   "&sysdate" as lastup,
						"&sysuserid" as	lastuser 
					FROM Ti LEFT JOIN work.old_flag ON ("&Ucc" = old_flag.geo) 
					       AND  (TI.age = old_flag.age)AND (TI.RB090 = old_flag.sex) and  ("&libel" = old_flag.indic_il) and ("&unit" = old_flag.unit)
					GROUP BY Ti.DB020, TI.Age, Ti.RB090;
        
					QUIT;
data test(drop=&arpt);set test (where=(&arpt = "Above"));run;
%if %sysfunc(exist(work.&tab)) %then %do;

data &tab;
	set &tab test;run;
%end;
%else %do;
data &tab;set  test;run;
%end;
			

	
				%mend by_unit;
					%by_unit(PC_POP,RB050a_PctSum_1110);
					%by_unit(THS_PER,RB050a_Sum/1000);
			%mend f_di20;
%if &EU =0 %then %do;

%f_di20(ARPT13i,LI_GE130MD);
%f_di20(ARPT14i,LI_GE140MD);
%f_di20(ARPT15i,LI_GE150MD);
%f_di20(ARPT16i,LI_GE160MD);
%f_di20(ARPT13Mi,LI_GE130M);
%f_di20(ARPT14Mi,LI_GE140M);
%f_di20(ARPT15Mi,LI_GE150M);

* Update RDB; 
 
DATA  rdb.&tab ;
set rdb.&tab(where=(not(time = &yyyy and geo = "&Ucc")))
    work.&tab ; 
run;   
%end;
%if &EU %then %do;

	* EU aggregates;

	%let tab=&tab;
	%let grpdim=age,sex ,indic_il,unit;
	%EUVALS(&Ucc,&Uccs);
%end;
PROC SQL;  
     Insert into log.log
     set date = "&sysdate"d, time = "&systime"t, user = "&sysuserid",
		 report = "* &Ucc - &yyyy * di20 (re)calculated *";		  
QUIT;

%end;
%else %do; 
PROC SQL;  
     Insert into log.log
     set date = "&sysdate"d, time = "&systime"t, user = "&sysuserid",
		 report = "* &Ucc - &yyyy * NO DATA !";		  
QUIT;
%end;

%mend UPD_di20;
