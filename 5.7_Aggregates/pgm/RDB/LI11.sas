%macro UPD_li11(yyyy,Ucc,Uccs,flag) /store;  
/* flags are taken from the existing data set  on 3/12/2010 */
/* 22/12/2010 modified to eliminate AGE variable from the old_flag dataset   */
/* consistent AGE format already existed with the changed format for the flags*/
*** child age format added  25 October 2011 - 20111025MG***;
/* modified the  aggregates  calculation changed the  merge with left joint  MG 16/12/2011 */
%let tab=LI11;
PROC DATASETS lib=work kill nolist;
QUIT;
%let tab=li11;
%let cc=%lowcase(&Ucc);
%let yy=%substr(&yyyy,3,2);

%let EU=0;
%if &Uccs=0 %then %let Uccs=("&Ucc");
%else %let EU=1; 

PROC SQL noprint;

Create table work.idb as 
	select DB010, DB020, DB030, RB030, RB050a, ARPT60, ARPT40, ARPT50, ARPT70,
			ARPT60M, ARPT40M, ARPT50M, ARPT60i, ARPT40i, ARPT50i, ARPT70i,
			ARPT60Mi, ARPT40Mi, ARPT50Mi, Age, RB090, EQ_INC20 
	from idb.IDB&yy
	where age ge 0 and DB010 = &yyyy and DB020 in &Uccs;
Select distinct count(DB010) as N 
	into :nobs
	from  work.idb;
quit;
	%if &EU=0 %then %do;
	proc sql;
          Create table work.li11 like rdb.li11; 
          QUIT;
    %end;
%if &nobs > 0
%then %do;
				%macro gaps(age,sex,where);

				PROC MEANS data=work.idb median sumwgt qmethod=os noprint;  
				var EQ_INC20;
				id &arpt;
				weight RB050a;
				output out=work.med median()=c_median sumwgt()=c_sumwgt;
				where &where;
				run;
				PROC SQL;
				CREATE TABLE work.old_flag AS
				SELECT distinct
					time,
					geo,
					sex,
					indic_il,
					iflag
				FROM rdb.&tab
				WHERE  time = &yyyy and geo="&Ucc" and sex=(&sex) and indic_il ="&libel";
			quit;
data med_flag (drop=geo sex  time );
merge med old_flag;
run; 
				PROC SQL;
				INSERT INTO li11 SELECT 

					"&Ucc" as geo,
					&yyyy as time,
					(&age) as age, 
					(&sex) as sex,
					"&libel" as indic_il,
					((&arpt - c_median) / &arpt * 100) as ivalue,
					iflag, 
				/*"&flag" as iflag, */
					(case when _freq_ < 20 then 2
						  when _freq_ < 50 then 1
						  else 0
					      end) as unrel,
					_freq_ as ntot,
					c_sumwgt as totwgh,
					"&sysdate" as lastup,
					"&sysuserid" as	lastuser 

				FROM med_flag ;

				QUIT;

				%mend gaps;
				%macro f_li11_0(arpt,libel);

				%gaps("TOTAL","T",(&arpt.i=1));
			    %gaps("TOTAL","M",(&arpt.i=1 and RB090=1));
				%gaps("TOTAL","F", (&arpt.i=1 and RB090=2));
				
				%gaps("Y_LT16","T",(&arpt.i=1 and age<=15));
				
				%gaps("Y_GE16","T",(&arpt.i=1 and age>=16));
				%gaps("Y_GE16","M",(&arpt.i=1 and age>=16 and RB090=1));
				%gaps("Y_GE16","F",(&arpt.i=1 and age>=16 and RB090=2));
				
				%gaps("Y16-64","T",(&arpt.i=1 and 16<=age<=64));
				%gaps("Y16-64","M",(&arpt.i=1 and 16<=age<=64 and RB090=1));
				%gaps("Y16-64","F",(&arpt.i=1 and 16<=age<=64 and RB090=2));
				
				%gaps("Y_GE18","T",(&arpt.i=1 and age>=18));
				%gaps("Y_GE18","M",(&arpt.i=1 and age>=18 and RB090=1));
				%gaps("Y_GE18","F",(&arpt.i=1 and age>=18 and RB090=2));
				
				%gaps("Y18-64","T",(&arpt.i=1 and 18<=age<=64));
				%gaps("Y18-64","M",(&arpt.i=1 and 18<=age<=64 and RB090=1));
				%gaps("Y18-64","F",(&arpt.i=1 and 18<=age<=64 and RB090=2));
				
				%gaps("Y_GE65","T",(&arpt.i=1 and age>=65));
				%gaps("Y_GE65","M",(&arpt.i=1 and age>=65 and RB090=1));
				%gaps("Y_GE65","F",(&arpt.i=1 and age>=65 and RB090=2));
				
				%gaps("Y_GE75","T",(&arpt.i=1 and age>=75));
				%gaps("Y_GE75","M",(&arpt.i=1 and age>=75 and RB090=1));
				%gaps("Y_GE75","F",(&arpt.i=1 and age>=75 and RB090=2));
	
				%gaps("Y_LT6","T",(&arpt.i=1 and 0<=age<=5));
				%gaps("Y_LT6","M",(&arpt.i=1 and 0<=age<=5 and RB090=1));
				%gaps("Y_LT6","F",(&arpt.i=1 and 0<=age<=5 and RB090=2));
				
				%gaps("Y6-11","T",(&arpt.i=1 and 6<=age<=11));
				%gaps("Y6-11","M",(&arpt.i=1 and 6<=age<=11 and RB090=1));
				%gaps("Y6-11","F",(&arpt.i=1 and 6<=age<=11 and RB090=2));
				
				%gaps("Y12-17","T",(&arpt.i=1 and 12<=age<=17));
				%gaps("Y12-17","M",(&arpt.i=1 and 12<=age<=17 and RB090=1));
				%gaps("Y12-17","F",(&arpt.i=1 and 12<=age<=17  and RB090=2));
				
				%gaps("Y_LT18","T",(&arpt.i=1 and 0<=age<=17));
				%gaps("Y_LT18","M",(&arpt.i=1 and 0<=age<=17 and RB090=1));
				%gaps("Y_LT18","F",(&arpt.i=1 and 0<=age<=17  and RB090=2)); 
				%mend f_li11_0;				
				%macro f_li11_1(arpt,libel);
				PROC SQL;
				CREATE TABLE work.old_flag AS
				SELECT distinct
					time,
					geo,
					Age, 
					sex,
					indic_il,
					iflag
				FROM rdb.li11
				WHERE  time = &yyyy and geo="&Ucc"  and indic_il ="&libel";
				quit;
	
				PROC SQL;
				Create table work.rdb as 
					select age, sex,iflag, ivalue, totwgh, ntot, 
							(ivalue * totwgh) as wval
					from rdb.li11
					where indic_il = "&libel" and time = &yyyy and geo in &Uccs; 
					quit; 
					
			 	proc sql;  
				 create table work.rdb1 as select distinct  
				    "&Ucc" as geo,
					&yyyy as time,
					rdb.age,
					rdb.sex, 
					"&libel" as indic_il,
				  	(sum(wval) / sum(totwgh)) as ivalue,
					 old_flag.iflag as iflag,
				
					(case when sum(ntot) < 20 then 2
					  when sum(ntot) < 50 then 1
						  else 0
					      end) as unrel,
					sum(ntot) as ntot,
					sum(totwgh) as totwgh,
				    "&sysdate" as lastup,
					"&sysuserid" as	lastuser 
					from work.rdb
					LEFT JOIN work.old_flag ON ("&Ucc" = old_flag.geo) 
					AND (rdb.age = old_flag.age) AND (rdb.sex = old_flag.sex) and 
					("&libel" = old_flag.indic_il)
				     group by rdb.age, rdb.sex;
					quit;

 	proc append base=li11 data= rdb1 force;run;

				%mend f_li11_1;

%f_li11_&EU(ARPT60,LI_GAP_MD60);
%f_li11_&EU(ARPT40,LI_GAP_MD40);
%f_li11_&EU(ARPT50,LI_GAP_MD50);
%f_li11_&EU(ARPT70,LI_GAP_MD70);
%f_li11_&EU(ARPT60M,LI_GAP_M60);
%f_li11_&EU(ARPT40M,LI_GAP_M40);
%f_li11_&EU(ARPT50M,LI_GAP_M50); 

* Update RDB;
DATA  rdb.LI11;
set rdb.LI11(where=(not(time = &yyyy and geo = "&Ucc")))
    work.li11; 
run;

PROC SQL;  

     Insert into log.log

     set date = "&sysdate"d, time = "&systime"t, user = "&sysuserid",

		 report = "* &Ucc - &yyyy * LI11 (re)calculated *";		  

QUIT;
%end;
%else %do; 
PROC SQL;  
    Insert into log.log
     set date = "&sysdate"d, time = "&systime"t, user = "&sysuserid",
		 report = "* &Ucc - &yyyy * NO DATA !";		  
QUIT;
%end;
%mend UPD_li11;
