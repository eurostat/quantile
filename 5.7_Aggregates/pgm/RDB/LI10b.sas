*** At-risk-poverty-rate by household type before social transfers excluding pensions***;

%macro UPD_li10b(yyyy,Ucc,Uccs,flag) /store;

PROC DATASETS lib=work kill nolist;
QUIT;

%let tab=LI10b;
%let cc=%lowcase(&Ucc);
%let yy=%substr(&yyyy,3,2);
%let EU=0;
%if &Uccs=0 %then %let Uccs=("&Ucc");
%else %let EU=1; 


PROC FORMAT;
    VALUE f_ht (multilabel)

		1 - 8 = "HH_NDCH"
		1-5 =	 "A1" 
		1,2 = "A1_LT65"
		3,4 = "A1_GE65"
		1,3 = "A1M"
		2,4 = "A1F"
		6,7 = "A2"
		6 =	 "A2_2LT65"
		7 =	 "A2_GE1_GE65"
		8 =	 "A_GE3"
		6 - 8 = "A_GE2_NDCH"
     	9 - 13 = "HH_DCH"
		9 =	 "A1_DCH"
		10 = "A2_1DCH"
		11 = "A2_2DCH"
		12 = "A2_GE3DCH"
		13 = "A_GE3_DCH"
		10 - 13 ="A_GE2_DCH"
		1 - 13 = "TOTAL";
RUN;
PROC SQL noprint;
Create table work.idb as 
	select DB010, DB020, DB030, RB030, RB050a,HT1, EQ_INC22,
		(case
	    when EQ_INC22 < ARPT60 then 1
		else 0
		end) as ARPT60i22  
	
	from idb.IDB&yy
	where age ge 0 and DB010 = &yyyy and DB020 in &Uccs and  HT1 between 1 and 13;
Select distinct count(DB010) as N 
	into :nobs
	from  work.idb;
Create table work.&tab like rdb.&tab; 
QUIT;

%if &nobs > 0
%then %do;
proc sql;
CREATE TABLE work.old_flag AS
SELECT distinct
      time,
      geo,
	   hhtyp,
	  iflag
FROM rdb.&tab
WHERE  time = &yyyy and geo="&Ucc" 
group by time, geo ,hhtyp;		
quit;
%if &EU=0 %then %do;
	

	PROC TABULATE data=work.idb out=Ti;
	FORMAT ht1 f_ht.;
	VAR RB050a;
	CLASS HT1 /MLF;
	CLASS ARPT60i22;
	CLASS DB020;
	TABLE  DB020*HT1, ARPT60i22 *(RB050a * (RowPctSum Sum N)) /printmiss;
	RUN;

				PROC SQL;
				Create Table &tab as SELECT 
					Ti.DB020 as geo FORMAT=$5. LENGTH=5,
					&yyyy as time,
					Ti.HT1 as hhtyp,
					Ti.ARPT60i22 as ARPT60i22,
					"PC_POP" as unit,
					Ti.RB050a_PctSum_101 as ivalue,
					old_flag.iflag as iflag,
				
					(case when Ti.RB050a_N < 20 then 2
						  when Ti.RB050a_N < 50 then 1
						  else 0
					      end) as unrel,
					Ti.RB050a_N as n,
					sum(Ti.RB050a_N) as ntot,
					sum(Ti.RB050a_Sum) as totwgh,
					"&sysdate" as lastup,
					"&sysuserid" as	lastuser 
				FROM Ti 
					LEFT JOIN work.old_flag ON ("&Ucc" = old_flag.geo) 
						 AND (Ti.HT1 = old_flag.hhtyp)  
			GROUP BY Ti.DB020, ti.HT1
			ORDER BY Ti.DB020, ti.HT1;
				QUIT;

* Update RDB;  
DATA  rdb.&tab(drop=ARPT60i22);
set rdb.&tab(where=(not(time = &yyyy and geo = "&Ucc")))
    work.&tab; 
		WHERE ARPT60i22=1;
run;  
%end;
%end;
 * EU aggregates;
%if &EU %then %do;
%let tab=&tab;
	%let grpdim=hhtyp,unit;
	%EUVALS(&Ucc,&Uccs);
%end;


%if &euok = 0 and &EU %then %do;
		PROC SQL;  
		Insert into log.log
		set date = "&sysdate"d, time = "&systime"t, user = "&sysuserid",
			report = "* &Ucc - &yyyy * NO enought countries available! ";		  
		QUIT;
%end;
%if &euok = 1 and &EU %then %do;
		PROC SQL;  
		Insert into log.log
		set date = "&sysdate"d, time = "&systime"t, user = "&sysuserid",
			report = "* &Ucc - &yyyy * &tab  (re)calculated *";		  
		QUIT;
%end;
%if &euok = 0 and &EU=0 and &nobs > 0 %then %do;
		PROC SQL;  
		Insert into log.log
		set date = "&sysdate"d, time = "&systime"t, user = "&sysuserid",
			report = "* &Ucc - &yyyy * &tab (re)calculated *";		  
		QUIT;
%end;
%if &euok = 0 and &EU=0  and &nobs = 0 %then %do;
PROC SQL;  
     Insert into log.log
     set date = "&sysdate"d, time = "&systime"t, user = "&sysuserid",
		 report = "* &Ucc - &yyyy * NO DATA !";		  
QUIT;
%end;
%mend UPD_li10b;
