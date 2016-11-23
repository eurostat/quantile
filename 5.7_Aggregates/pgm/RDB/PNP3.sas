*** Aggregate replacement ratio ***;

*** Aggregate replacement ratio ***;
/* 20111128 added condition for year < 2008 

  in order to select the working variables 
  if &yyyy <2009 ===>>>  PL070,PL072 
			else ===>>>  PL073,PL074,PL075,PL076 
	are selected	   20111128MG
	
*/
%macro UPD_pnp3(yyyy,Ucc,Uccs,flag)  ;

/*change_09*/

PROC DATASETS lib=work kill nolist;

QUIT;

%let tab=pnp3;

%let cc=%lowcase(&Ucc);

%let yy=%substr(&yyyy,3,2);

%let EU=0;

%if &Uccs=0 %then %let Uccs=("&Ucc");

%else %let EU=1; 

PROC FORMAT;

	VALUE f_sex (multilabel)

		1 = "M"

		2 = "F"

		1 - 2 = "T";

RUN;

PROC SQL noprint;

Create table work.idb as 

	select DB010, DB020, DB030, RB030, PB040, Age, RB090, INCWRK, INCPEN,PL085 ,
    %if &yyyy <2009 %then  %do;
		sum(PL070,PL072,0) as PL0701
   %end;
   %else %do;
		sum(PL073,PL074,PL075,PL076,0) as PL0701
   %end;
   	from idb.IDB&yy

	where age ge 0 and DB010 = &yyyy and DB020 in &Uccs;

Select distinct count(DB010) as N 

	into :nobs

	from  work.idb;

Create table work.pnp3 like rdb.pnp3; 

CREATE TABLE work.old_flag AS

SELECT 

      time,

      geo,

	  sex,

	  indic_il,

	  iflag

	  FROM rdb.&tab

WHERE  time = &yyyy and geo="&Ucc" ;

QUIT;

%if &nobs > 0

%then %do;

					%macro f_pnp3_0;

					PROC MEANS data=work.idb median sumwgt qmethod=os noprint;

					format RB090 f_sex3.; 

					class RB090 /MLF;

					var INCWRK;

					weight PB040;

					output out=wrk median()=medi sumwgt()=c_sumwgt;

					where PL0701 = 12 and AGE GE 50 and AGE LE 59;

					run;

					PROC MEANS data=work.idb median sumwgt qmethod=os noprint;

					format RB090 f_sex3.; 

					class RB090 /MLF;

					var INCPEN;

					weight PB040;

					output out=pen median()=medi sumwgt()=c_sumwgt;

					where PL085 = 12 and AGE GE 65 and AGE LE 74;

					run;

					PROC SQL;

					INSERT into &tab SELECT 

						"&Ucc" as geo,

						&yyyy as time,

						pen.RB090 as sex,

						"R_PN_WK" as indic_il,

						(pen.medi / wrk.medi) as ivalue,

						old_flag.iflag as iflag, 

						/*"&flag" as iflag, */

						(case when min(pen._freq_,wrk._freq_) < 20 then 2

							  when min(pen._freq_,wrk._freq_) < 50 then 1

							  else 0

						      end) as unrel,

						sum(pen._freq_,wrk._freq_) as ntot,

						sum(pen.c_sumwgt,wrk.c_sumwgt) as totwgh,

						"&sysdate" as lastup,

						"&sysuserid" as	lastuser 

					FROM pen join wrk on pen.RB090 = wrk.RB090

					LEFT JOIN work.old_flag ON ("&Ucc" = old_flag.geo) 

					AND (pen.RB090 = old_flag.sex)  AND ("R_PN_WK" = old_flag.indic_il) 

					WHERE pen._type_ = 1;

					QUIT;

					%mend f_pnp3_0;

					%macro f_pnp3_1;

					PROC SQL;

					Create table work.rdb as 

						select indic_il, sex, ivalue, totwgh, ntot, 

								(ivalue * totwgh) as wval

						from rdb.&tab

						where time = &yyyy and geo in &Uccs;quit;

				proc sql;

				INSERT INTO &tab SELECT 

						"&Ucc" as geo,

						&yyyy as time,

						sex,

						indic_il, 

						(sum(wval) / sum(totwgh)) as ivalue,

						 "" as iflag,   

						(case when sum(ntot) < 20 then 2

							  when sum(ntot) < 50 then 1

							  else 0

						      end) as unrel,

						sum(ntot) as ntot,

						sum(totwgh) as totwgh,

						"&sysdate" as lastup,

						"&sysuserid" as	lastuser 

					FROM work.rdb  				 

					group by rdb.indic_il, rdb.sex;

					QUIT;

/* to keep the iflag frol old_flag  */

data &tab(drop=iflag);set &tab;run;

data &tab; merge &tab old_flag;by geo time indic_il  sex;run;

data &tab ;

				format geo time  sex indic_il ivalue iflag unrel ntot  totwgh  lastup lastuser; 

				set &tab; run;

					%mend f_pnp3_1;

%f_pnp3_&EU;

* Update RDB;

DATA  rdb.pnp3;

set rdb.pnp3(where=(not(time = &yyyy and geo = "&Ucc")))

    work.pnp3; 

run;

PROC SQL;  

     Insert into log.log

     set date = "&sysdate"d, time = "&systime"t, user = "&sysuserid",

		 report = "* &Ucc - &yyyy * pnp3 (re)calculated *";		  

QUIT;

%end;

%else %do; 

PROC SQL;  

     Insert into log.log

     set date = "&sysdate"d, time = "&systime"t, user = "&sysuserid",

		 report = "* &Ucc - &yyyy * NO DATA !";		  

QUIT;

%end;

%mend UPD_pnp3;
