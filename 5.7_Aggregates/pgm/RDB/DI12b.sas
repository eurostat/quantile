/*** Gini coefficiant by EQ_INC23                                                   *****/
/*  from DI12b before social transfers and pension                                    on 18/12/2013   */
/*    before social transfers (pensions included in social transfers)  /so pensions also excluded from the income */
/* follow the 5 STEPs for calculation                                       */

%macro UPD_di12b(yyyy,Ucc,Uccs,flag) /store;

PROC DATASETS lib=work kill nolist;
QUIT;
%let tab=di12b;
%let cc=%lowcase(&Ucc);
%let yy=%substr(&yyyy,3,2);
%let EU=0;
%if &Uccs=0 %then %let Uccs=("&Ucc");
%else %let EU=1; 

PROC SQL noprint;
Create table work.idb as 
	select DB010, DB020, DB030, RB030, RB050a, EQ_INC23,
		sum(RB050a) as totwgh, count(RB030) as ntot 
	from idb.IDB&yy
	where DB010 = &yyyy and DB020 in &Uccs;
Select distinct count(DB010) as N 
	into :nobs
	from  work.idb;quit;
	
%if &EU=0 %then %do;
	proc sql; Create table work.di12b like rdb.di12b; 
    QUIT;
%end;


%if &nobs > 0
%then %do;
	%if &EU %then %do;
	PROC SQL;
		CREATE TABLE work.old_flag AS
				SELECT 
					time,
					geo,
					indic_il,
					iflag
				FROM rdb.&tab
				WHERE  time = &yyyy and geo="&Ucc"  ;quit;
				
		PROC SQL;
		Create table work.rdb as 
			select ivalue, totwgh, ntot,
					(ivalue * totwgh) as wval
			from rdb.di12b
			where time = &yyyy and geo in &Uccs;quit;
            proc sql;  
					create table work.&tab as select
 					"&Ucc" as geo,
					&yyyy as time,
					"GINI_HND" as indic_il,
					(sum(wval) / sum(totwgh)) as ivalue,
					sum(ntot) as ntot,
					sum(totwgh) as totwgh,
					(case when sum(ntot) < 20 then 2
						  when sum(ntot) < 50 then 1
						  else 0
					      end) as unrel,
				    "&sysdate" as lastup,
					"&sysuserid" as	lastuser 
					from work.rdb;
					quit;

/* merge the output dataset plus old_flag; */
			
				data &tab; merge &tab (in=a)  old_flag (in=b) ;
				by time  indic_il ;
				if a;
				run;
     	
/* format the output dataset; */
				data &tab;
				format geo   time  indic_il ivalue iflag unrel ntot totwgh  lastup lastuser; 
				set &tab; run;			
			

	%end;
	%else %do;
		PROC SORT data=work.idb;
		by EQ_INC23;
		RUN;
		DATA work.gini;
		set work.idb end=last;
		    retain swt swtvar swt2var swtvarcw ss 0;
		    ss + 1;
		    swt + RB050a;
		    swtvar + RB050a * EQ_INC23;
		    swt2var + RB050a * RB050a * EQ_INC23;
		    swtvarcw + swt * RB050a * EQ_INC23;
		    if last then
		       do;
		       gini  = 100 * (( 2 * swtvarcw - swt2var ) / ( swt * swtvar ) - 1);
		       output;
		       end;
		  RUN;

		PROC SQL;
		CREATE TABLE work.old_flag AS
				SELECT 
					time,
					geo,
					indic_il,
					iflag
				FROM rdb.&tab
				WHERE  time = &yyyy and geo="&Ucc"  ;quit;
				
		/* to check if old_flag1 is empty  */
						proc sql noprint;
							Select distinct count(iflag) as N 
							into :nobs
							from  old_flag;
						quit;
					
						%if &nobs = 0 %then %do;
							data old_flag;  iflag=" "; run;
						%end;
						
        /* end check */
		proc sql noprint;
		INSERT INTO di12b SELECT 
			"&Ucc" as geo,
			&yyyy as time,
			"GINI_HND" as indic_il,
			gini as ivalue,
			old_flag.iflag as iflag, 
			(case when ntot < 20 then 2
				  when ntot < 50 then 1
				  else 0
			      end) as unrel,
			ntot,
			totwgh,
			"&sysdate" as lastup,
			"&sysuserid" as	lastuser 
		FROM work.gini,old_flag
		;
		QUIT;
	
	%end;

* Update RDB;  
DATA  rdb.di12b;
set rdb.di12b(where=(not(time = &yyyy and geo = "&Ucc")))
    work.di12b; 
run;  

PROC SQL;  
     Insert into log.log
     set date = "&sysdate"d, time = "&systime"t, user = "&sysuserid",
		 report = "* &Ucc - &yyyy * di12b (re)calculated *";		  
QUIT;

%end;
%else %do; 
PROC SQL;  
     Insert into log.log
     set date = "&sysdate"d, time = "&systime"t, user = "&sysuserid",
		 report = "* &Ucc - &yyyy * NO DATA !";		  
QUIT;
%end;

%mend UPD_di12b;
