/*****************************************************/
/* Distribution of income by different income groups */
/* created on 3/03/2011                              */
/*****************************************************/
/*20120220MG changed the calcultaion for Agggregates */
%macro UPD_di02(yyyy,Ucc,Uccs,flag) /store; 

PROC DATASETS lib=work kill nolist;
QUIT;
%let tab=DI02;
%let cc=%lowcase(&Ucc);
%let yy=%substr(&yyyy,3,2);
%let EU=0;
%if &Uccs=0 %then %let Uccs=("&Ucc");
%else %let EU=1; 

%macro f_di02(arpt,inc);
/**************************************************************************************/
/* formatting the incgrp it has been in this way because the arpt variable is numeric */
/* and it must be formatting as character                                             */
/* var1 define the CURRENCY                                                            */
/* var5 define the part of INCGRP                                                     */
/**************************************************************************************/

 	%let var1=%substr(&inc,9,3);
    %if &var1=ppp %then %let  var1=PPS;
 	 %else %if &var1=eur %then %let var1=EUR;
     		%else %let var1=NAC;
    %let var2=%substr(&arpt,7,1);
	%if &var2=i %then %let var4=MD;
	    %else %let var4=M;
	%let var3=%substr(&arpt,5,2);
	%let var5=&var4&var3;
 
 	PROC SQL;
	CREATE TABLE work.old_flag AS
    SELECT distinct
     geo,
     time,
	 incgrp,
	 indic_il,
	 CURRENCY,
	 iflag
	 FROM rdb.&tab
   WHERE  time = &yyyy and geo="&Ucc" ;
   quit;
		
   proc sort data=work.idb;by DB010 DB020 &arpt;run;
   PROC MEANS data=work.idb median sumwgt qmethod=os noprint;  
		var &inc;
		by DB010 DB020 &arpt;
		weight RB050a;
		output out=work.mm mean()=MEANINC  median()=MEDIANINC  n=n sumwgt=totwgh;
	run;
	data mm(drop=_freq_ _type_);set mm; run;
/* define the INCGRP                 */
	data mm  (drop= &arpt)  ;set mm; 
	 	if &arpt=1 then incgrp="B_&var5";
		else incgrp="A_&var5"; 
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
    by DB010 DB020 indic_il ;												
 	run;	
	 
	proc sql;
	INSERT INTO &tab SELECT 
			"&Ucc" as geo,
			&yyyy as time,
			memd.incgrp as incgrp,
			memd.indic_il as indic_il,
			"&var1" as CURRENCY,
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
		FROM memd LEFT JOIN work.old_flag ON ("&Ucc" = old_flag.geo) and (memd.incgrp = old_flag.incgrp)
		AND (memd.indic_il = old_flag.indic_il) and ("&var1" = old_flag.CURRENCY) ;

    quit; 
	 
%mend f_di02;

/* start program */

%if &EU=0 %then %do;
PROC SQL noprint;
Create table work.idb as 
	select DB010, DB020, DB030, RB030,  RB050a, ARPT60i, ARPT40i, ARPT50i, ARPT70i,
			ARPT60Mi, ARPT40Mi, ARPT50Mi, EQ_INC20, EQ_INC20eur, EQ_INC20ppp    
	from idb.IDB&yy
	where  DB010 = &yyyy and DB020 in &Uccs;
Select distinct count(DB010) as N 
	into :nobs
	from  work.idb;
Create table work.DI02 like rdb.DI02; 
QUIT;

%if &nobs > 0
%then %do;


/* define  ARPT INCOME list in order to have a loop                     */
 %let listpi=ARPT60i ARPT40i ARPT50i ARPT70i ARPT60Mi ARPT40Mi ARPT50Mi ;
 %let listin=EQ_INC20eur  EQ_INC20 EQ_INC20ppp ;
 %let i=1;  
  
 %let arpt=%scan(&listpi,&i,%str( ));   
 /*%let arptfr=%scan(&listin,&i,%str( ));  */
 %do  %while(&arpt ne );  
	%let j=1;
	%let inc =%scan(&listin,&j,%str( ));  
	%do  %while(&inc ne );  
 		%f_di02(&arpt,&inc);
		%let j=%eval(&j+1);                                  
		%let inc=%scan(&listin,&j,%str( )); 

	%end;  
	%let i=%eval(&i+1);                                  
	%let arpt=%scan(&listpi,&i,%str( ));   
 /*%let arptfr=%scan(&listfr,&i,%str( ));   */  
%end; 

* Update RDB; 

DATA  rdb.&tab;
set rdb.&tab(where=(not(time = &yyyy and geo = "&Ucc")))
    work.&tab; 
run;  

PROC SQL;  
     Insert into log.log
     set date = "&sysdate"d, time = "&systime"t, user = "&sysuserid",
		 report = "* &Ucc - &yyyy * DI02 (re)calculated *";		  
QUIT;

%end;
%else %do; 

PROC SQL;  
     Insert into log.log
     set date = "&sysdate"d, time = "&systime"t, user = "&sysuserid",
		 report = "* &Ucc - &yyyy * NO DATA !";		  
QUIT;
%end;
%end;
/* test for aggregates  */
%if &EU %then %do;

* EU aggregates;

	%let tab=di02;
	%let grpdim= incgrp,indic_il,currency,unit ;
	%EUVALS(&Ucc,&Uccs);
	
	PROC SQL;  
     Insert into log.log
     set date = "&sysdate"d, time = "&systime"t, user = "&sysuserid",
		 report = "* &Ucc - &yyyy * DI02 (re)calculated *";		  
	QUIT;
%end;

%mend UPD_DI02;
