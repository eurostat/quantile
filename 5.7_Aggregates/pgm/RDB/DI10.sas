*** Mean and median income by ability to make ends meet  ***;
/*20120119MG  */
/* MG added the EU condition 02/10/2012 */
%macro UPD_DI10(yyyy,Ucc,Uccs,flag) /store;

PROC DATASETS lib=work kill nolist;
QUIT;
%let tab=DI10;
%let lEQ_INC20 = equivalised income in NA;
%let lEQ_INC20eur = equivalised income in EUROS;
%let lEQ_INC20ppp = equivalised income in PPP;
%let cc=%lowcase(&Ucc);
%let yy=%substr(&yyyy,3,2);
%let EU=0;
/*
libname in "&eusilc/BDB"; 
	%let infil=BDB_c&yy;
*/
%if &Uccs=0 %then %let Uccs=("&Ucc");
%else %let EU=1; 


*** ability to make ends meet ***;
PROC FORMAT;
	VALUE f_HS (multilabel)

		1 = "EM_GD"
		2 = "EM_D"
		3 = "EM_SD"
		4 = "EM_FE"
		5 = "EM_E"
		6 = "EM_VE"
		1,2,3="EM_GSD"
		4,5,6="EM_FVE"
		. ="other"
		;
RUN;

PROC SQL noprint;
CREATE TABLE work.idb AS SELECT
	 DB010,
	 DB020 AS COUNTRY,
	 RB030,
	 RB050a,
	 h.HS120,
	 EQ_INC20eur,
	 EQ_INC20ppp,
	 EQ_INC20
	from idb.IDB&yy as idb
	LEFT JOIN  in.&infil.h  as h  ON (idb.db020 = h.HB020 and  idb.DB030 = h.hB030 )
	where DB010 = &year and DB020 in &Uccs and h.HS120 ^= .;
Select distinct count(DB010) as N 
	into :nobs
	from  work.idb;
Create table work.DI10 like rdb.DI10; 
QUIT;
%if &nobs > 0
%then %do;
proc sql;
CREATE TABLE work.old_flag AS
SELECT distinct
      time,
      geo,
	  indic_il,
	  subjnmon,
	  currency,
	  ivalue,
	  iflag
FROM rdb.&tab
WHERE  time = &yyyy and geo="&Ucc" ;	
quit;

%macro Calc_Country(currency,label,RB050a,Ucc);
 
   proc sort data=work.idb;by DB010 country HS120;run;
   PROC MEANS data=work.idb median sumwgt qmethod=os noprint;  
  
		FORMAT HS120 f_hs10.;
		CLASS HS120 /MLF;
		var &label;
		by DB010 country ;
		weight RB050a;
		output out=work.mm mean()=MEANINC  median()=MEDIANINC  n=n sumwgt=totwgh;
	run;
	data mm;set mm;if _type_=0 then delete;run;
	data mm(drop=_freq_ _type_);set mm; run;
/* rename n                */
	data mm    ;set mm; 
		ntot=n;
		run;
/* define the indic_il  for mean     */
	data md (drop=MEDIANINC  rename=(MEANINC=ivalue));set mm;
	 	indic_il="MEI_E";
	run;

/* define the indic_il   for median  */
	data memd (drop=MEANINC  rename=(MEDIANINC=ivalue)) ;set mm; 
		indic_il="MED_E";
		run; 
/* merge mean with median one below another*/
	data memd; merge memd (in=a) 				
							 md (in=b);				
    by DB010 country indic_il ;												
 	run;	
	proc sql;
 	INSERT INTO &tab SELECT 
			"&Ucc" as geo,
			&yyyy as time,
			memd.indic_il as indic_il,
			memd.HS120 as subjnmon,
			"&currency" as currency,
			"PC_POP" as unit,
			memd.ivalue as ivalue,
			old_flag.iflag as iflag, 
		 	(case when ntot < 20 then 2
				  when ntot < 50 then 1
				  else 0
			      end) as unrel,
			memd.n as n,
			memd.ntot as ntot,
			memd.totwgh as totwgh,
			"&sysdate" as lastup,
			"&sysuserid" as	lastuser 
		FROM memd LEFT JOIN work.old_flag ON ("&Ucc" = old_flag.geo) and (memd.HS120 = old_flag.subjnmon)
		AND (memd.indic_il = old_flag.indic_il) and ("&currency" = old_flag.currency) ;

 quit; 
		
%mend Calc_country;

%if &EU=0 %then %do;
		%Calc_Country (EUR,EQ_INC20eur, RB050a, &Ucc); 
		%Calc_Country (PPS,EQ_INC20ppp, RB050a, &Ucc); 
		%Calc_Country (NAC,EQ_INC20,RB050a, &Ucc); 
	
 
* Update RDB;   
DATA  rdb.DI10;
set rdb.DI10(where=(not(time = &yyyy and geo = "&Ucc")))
    work.DI10; 
run; 
%end; 

%if &EU %then %do;

* EU aggregates;

	%let tab=di10;
	%let grpdim= indic_il,subjnmon,currency,unit ;
	%EUVALS(&Ucc,&Uccs);
%end;
%put &eouk;
	%if &euok = 0 and &EU %then %do;
		PROC SQL;  
		Insert into log.log
		set date = "&sysdate"d, time = "&systime"t, user = "&sysuserid",
			report = "* &Ucc - &yyyy * enought countries available ! ";		  
		QUIT;
		%end;
		%else %do;
		PROC SQL;  
		Insert into log.log
		set date = "&sysdate"d, time = "&systime"t, user = "&sysuserid",
			report = "* &Ucc - &yyyy * DI10 (re)calculated *";		  
		QUIT;
	%end;
%end;

%else %do; 
PROC SQL;  
     Insert into log.log
     set date = "&sysdate"d, time = "&systime"t, user = "&sysuserid",
		 report = "* &Ucc - &yyyy * NO DATA !";		  
QUIT;
%end;

%mend UPD_DI10;
