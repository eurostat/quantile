*** share of people by degurba  having equivalised income of 1.3 times the median or MORE, having 1.4 times the median or more etc…
 ***;
%macro UPD_di23(yyyy,Ucc,Uccs,flag) /store;

PROC DATASETS lib=work kill nolist;
QUIT;

%let tab=di23;
%let cc=%lowcase(&Ucc);
%let yy=%substr(&yyyy,3,2);
%let EU=0;
%if &Uccs=0 %then %let Uccs=("&Ucc");
%else %let EU=1; 

*** At-risk-poverty-rate by age and gender ***;
PROC FORMAT;

	VALUE f_DEG_URB (multilabel)
			1 = "DEG1"
			2 = "DEG2"
			3 = "DEG3"
			1 - 3 = "TOTAL"
			;

		
	VALUE f_arpt (multilabel)
		0 = "Below"
		1 = "Above"
	;
RUN;
PROC SQL noprint;
Create table work.idb1 as 
	select idb.DB010, idb.DB020, idb.DB030, RB030, RB050a, Age, RB090,MEAN20, MEDIAN20,EQ_INC20,BDBd.DB100, 
	(MEDIAN20 * 1.3) as ARPT13, 

	(MEDIAN20 * 1.4) as ARPT14, 

	(MEDIAN20 * 1.5) as ARPT15, 

	(MEDIAN20 * 1.6) as ARPT16,

	(MEAN20 * 1.4) as ARPT14M, 

	(MEAN20 * 1.3) as ARPT13M, 

	(MEAN20 * 1.5) as ARPT15M 

	from idb.IDB&yy as idb
	left join in.&infil.d as BDBd on (IDB.DB020 = BDBd.DB020 and IDB.DB030 = BDBd.DB030)
	where BDBd.DB100 in(1,2,3)  and idb.DB010 = &yyyy and idb.DB020 in &Uccs;
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
Create table work.di23 like rdb.di23; 
QUIT;

%if &nobs > 0
%then %do;
proc sql;
CREATE TABLE work.old_flag AS
SELECT distinct
      time,
      geo,
	  deg_urb,
	  indic_il,
	  unit,
	  iflag
	  FROM rdb.&tab
WHERE  time = &yyyy and geo="&Ucc"  
group by time, geo , deg_urb, indic_il, unit ;

QUIT;
%let var=RB050a;
			%macro f_di23(arpt,libel);

					

* calc values, N and total weights;
PROC TABULATE data=work.idb out=Ti;
						FORMAT DB100  f_DEG_URB.;
						FORMAT &arpt f_arpt.;
						VAR &var;
						CLASS DB020;
						CLASS DB100 /MLF;
						CLASS &arpt /MLF;
	TABLE DB020 * DB100, &arpt  * &var * (RowPctSum N Sum) /printmiss;
RUN;

				%macro by_unit(unit,ival); 
				proc sql;
				 	CREATE TABLE work.TEMP AS
					SELECT 
						Ti.DB020 as geo FORMAT=$5. LENGTH=5,
	       				&yyyy as time,
						Ti.DB100 as deg_urb,
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
					       AND (TI.DB100 = old_flag.DEG_URB)  AND ("&libel" = old_flag.indic_il) and ("&unit" = old_flag.unit)
					GROUP BY Ti.DB020, TI.DB100;
        
					QUIT;
data TEMP(drop=&arpt);set TEMP (where=(&arpt = "Above"));run;
%if %sysfunc(exist(work.&tab)) %then %do;

data &tab;
	set &tab TEMP;run;
%end;
%else %do;
data &tab;set  TEMP;run;
%end;
			

	
				%mend by_unit;
					%by_unit(PC_POP,RB050a_PctSum_110);
					*%by_unit(THS_PER,RB050a_Sum/1000);
			%mend f_di23;
%if &EU =0 %then %do;

%f_di23(ARPT13i,LI_GE130MD);
%f_di23(ARPT14i,LI_GE140MD);
%f_di23(ARPT15i,LI_GE150MD);
%f_di23(ARPT16i,LI_GE160MD);
%f_di23(ARPT13Mi,LI_GE130M);
%f_di23(ARPT14Mi,LI_GE140M);
%f_di23(ARPT15Mi,LI_GE150M);

* Update RDB; 
 
DATA  rdb.&tab ;
set rdb.&tab(where=(not(time = &yyyy and geo = "&Ucc")))
    work.&tab ; 
run;   
%end;
%if &EU %then %do;

	* EU aggregates;

	%let tab=&tab;
	%let grpdim=deg_urb ,indic_il,unit;
	%EUVALS(&Ucc,&Uccs);
%end;
PROC SQL;  
     Insert into log.log
     set date = "&sysdate"d, time = "&systime"t, user = "&sysuserid",
		 report = "* &Ucc - &yyyy * di23 (re)calculated *";		  
QUIT;

%end;
%else %do; 
PROC SQL;  
     Insert into log.log
     set date = "&sysdate"d, time = "&systime"t, user = "&sysuserid",
		 report = "* &Ucc - &yyyy * NO DATA !";		  
QUIT;
%end;

%mend UPD_di23;
