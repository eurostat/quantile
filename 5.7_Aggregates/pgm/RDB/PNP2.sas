*** Relative median income ratio ***;

%macro UPD_pnp2(yyyy,Ucc,Uccs,flag) /* /store */;

/* flags are taken from the existing data set  on 29/11/2010 */

PROC DATASETS lib=work kill nolist;

QUIT;

%let tab=pnp2;

%let cc=%lowcase(&Ucc);

%let yy=%substr(&yyyy,3,2);

%let EU=0;

%if &Uccs=0 %then %let Uccs=("&Ucc");

%else %let EU=1; 

PROC FORMAT;

   VALUE f_age (multilabel)

		0 - 64 = "Y0_64"

		45 - 54 = "Y45_54"

		65 - HIGH = "Y_GE65"

		0 - 74 = "Y0_74"

		75 - HIGH = "Y_GE75"

		0 - 59 = "Y0_59"

		60 - HIGH = "Y_GE60";

	VALUE f_sex (multilabel)

		1 = "M"

		2 = "F"

		1 - 2 = "T";

RUN;

PROC SQL noprint;

Create table work.idb as 

	select DB010, DB020, DB030, RB030, RB050a, Age, RB090, EQ_INC20 

	from idb.IDB&yy

	where age ge 0 and DB010 = &yyyy and DB020 in &Uccs;

Select distinct count(DB010) as N 

	into :nobs

	from  work.idb;

Create table work.pnp2 like rdb.pnp2; 

QUIT;

%if &nobs > 0

%then %do;

PROC SQL;

CREATE TABLE work.old_flag AS

SELECT 

      time,

      geo,

	  sex,

	  indic_il,

	  iflag

FROM rdb.&tab

WHERE  time = &yyyy and geo="&Ucc" ;	

				%macro f_pnp2_0;

				PROC MEANS data=work.idb median sumwgt qmethod=os noprint;

				format AGE f_age15.; 

				format RB090 f_sex3.; 

				class AGE /MLF;

				class RB090 /MLF;

				var EQ_INC20;

				weight RB050a;

				output out=med median()=medi sumwgt()=c_sumwgt;

				run;

				%rel(Y_GE65,Y0_64,R_GE65_LT65);

				%rel(Y_GE65,Y45_54,R_GE65_45TO54);

				%rel(Y_GE75,Y0_74,R_GE75_LT75);

				%rel(Y_GE75,Y45_54,R_GE75_45TO54);

				%rel(Y_GE60,Y0_59,R_GE60_LT60);

				%rel(Y_GE60,Y45_54,R_GE60_45TO54);

				%mend f_pnp2_0;

				%macro f_pnp2_1;

				PROC SQL;

				Create table work.rdb as 

					select indic_il, sex, ivalue, totwgh, ntot,

							(ivalue * totwgh) as wval

					from rdb.pnp2

					where time = &yyyy and geo in &Uccs;

				INSERT INTO pnp2 SELECT 

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

				group by indic_il, sex;

				QUIT;

	proc sort data =&tab; by  geo time   sex indic_il;run;

	proc sort data =old_flag; by  geo time   sex indic_il;run;

/* to keep the iflag from old_flag  */

data &tab(drop=iflag);set &tab;run;

data &tab; merge &tab old_flag;by geo time  sex  indic_il;run;

data &tab ;

				format geo time sex indic_il ivalue iflag unrel ntot totwgh  lastup lastuser; 

				set &tab; run;

				%mend f_pnp2_1;

				%macro rel(Y1,Y2,R);

				proc sql;								

				INSERT into pnp2 SELECT 

					"&Ucc" as geo,

					&yyyy as time,

					f1.RB090 as sex,

					"&R" as indic_il,

					(f1.medi / f2.medi) as ivalue,

					old_flag.iflag as iflag, 

					/*"&flag" as iflag, */

					(case when f1._freq_ < 20 then 2

						  when f1._freq_ < 50 then 1

						  else 0

					      end) as unrel,

					f1._freq_ as ntot,

					f1.c_sumwgt as totwgh,

					"&sysdate" as lastup,

					"&sysuserid" as	lastuser 

				FROM med as f1 join med as f2 on f1.RB090 = f2.RB090

				LEFT JOIN work.old_flag ON ("&Ucc" = old_flag.geo) 

					AND (f1.RB090 = old_flag.sex) and ("&R" = old_flag.indic_il) 

				WHERE f1.AGE="&Y1" and f2.AGE="&Y2" and f1._type_ = 3;

				QUIT;

				%mend rel;

%f_pnp2_&EU;

* Update RDB;  

DATA  rdb.pnp2;

set rdb.pnp2(where=(not(time = &yyyy and geo = "&Ucc")))

    work.pnp2; 

run;  

PROC SQL;  

     Insert into log.log

     set date = "&sysdate"d, time = "&systime"t, user = "&sysuserid",

		 report = "* &Ucc - &yyyy * pnp2 (re)calculated *";		  

QUIT;

%end;

%else %do; 

PROC SQL;  

     Insert into log.log

     set date = "&sysdate"d, time = "&systime"t, user = "&sysuserid",

		 report = "* &Ucc - &yyyy * NO DATA !";		  

QUIT;

%end;

 /*

proc datasets library=work;

   delete old_flag;

run; */

%mend UPD_pnp2;
