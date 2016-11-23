*** S80/S20 income quintile share ratio ***;
/****************************************************************************/
/*  Modifications                                                           */
/*                                                                          */
/* on 3/12/2010                                                             */
/* flags are taken from the existing data set                               */
/* on 22/12/2010                                                            */
/* modified to eliminate AGE variable from the old_flag dataset             */
/* consistent AGE format already existed with the changed format for flags  */
/* on 28/02/2011    														*/
/* changed the aggregates calculation to avoid the duplication records  	*/
/* folowing the keeping old flags											*/
/****************************************************************************/
%macro UPD_di11(yyyy,Ucc,Uccs,flag) /store;
%let tab=DI11;
PROC DATASETS lib=work  nolist;
QUIT;

%let cc=%lowcase(&Ucc);
%let yy=%substr(&yyyy,3,2);
%let EU=0;
%if &Uccs=0 %then %let Uccs=("&Ucc");
%else %let EU=1; 

PROC SQL noprint;
Create table work.idb as 
	select DB010, DB020, DB030, RB030, RB050a, QITILE, Age, RB090, EQ_INC20 
	from idb.IDB&yy
	where age ge 0 and DB010 = &yyyy and DB020 in &Uccs;
Select distinct count(DB010) as N 
	into :nobs
	from  work.idb;quit;
	
%if &EU=0 %then %do;
	proc sql; Create table work.di11 like rdb.di11; 
    QUIT;
%end;

%if &nobs > 0
%then %do;
PROC SQL;
				CREATE TABLE work.old_flag AS
				SELECT distinct
					time,
					geo,
					Age,
					sex,
					indic_il,  
					iflag
				FROM rdb.di11
				WHERE  time = &yyyy and geo = "&Ucc" and indic_il ="S80_S20";
		quit;

	%if &EU %then %do;
 			PROC SQL;
				Create table work.rdb as 
				select age, sex, ivalue, totwgh, ntot20, ntot80,
					(ivalue * totwgh) as wval
				from rdb.di11
				where time = &yyyy and geo in &Uccs;
			quit;
	
			proc sql;
			create table work.di11 as select 
			"&Ucc" as geo,
			&yyyy as time,
			age, sex, 
		    "S80_S20" as indic_il, 
			(sum(wval) / sum(totwgh)) as ivalue,
			(case when min(sum(ntot20),sum(ntot80)) < 20 then 2
				  when min(sum(ntot20),sum(ntot80)) < 50 then 1
				  else 0
			      end) as unrel,
			sum(ntot20) as ntot20,
			sum(ntot80) as ntot80,
			sum(totwgh) as totwgh,
			"&sysdate" as lastup,
			"&sysuserid" as	lastuser 
			from work.rdb
				group by rdb.age, rdb.sex;
			quit;
											
/* merge the output dataset plus old_flag; */
			
				data di11; merge di11(in=a)  old_flag (in=b) ;
				by age sex ;
				if a;
				run;
			
/* format the output dataset; */
				data di11;
				format geo time age sex indic_il ivalue iflag unrel ntot20 ntot80 totwgh  lastup lastuser; 
				set di11; run;

/*
		INSERT INTO di11 SELECT 
			"&Ucc" as geo,
			&yyyy as time,
			 age, 
			 sex,
			"S80_S20" as indic_il,
			(sum(wval) / sum(totwgh)) as ivalue,
			iflag,
			(case when min(sum(ntot20),sum(ntot80)) < 20 then 2
				  when min(sum(ntot20),sum(ntot80)) < 50 then 1
				  else 0
			      end) as unrel,
			sum(ntot20) as ntot20,
			sum(ntot80) as ntot80,
			sum(totwgh) as totwgh,
			"&sysdate" as lastup,
			"&sysuserid" as	lastuser 
		FROM work.rdb
		group by age, sex;
		QUIT;*/
		%end; 

	%else %do;
						%macro s20s80(age,sex,where);
						* Quintiles;
						proc univariate data=work.idb noprint;
						     var EQ_INC20;
							 by DB010 DB020;
							 weight RB050a; 
						     output out=work.outw pctlpre=P_ pctlpts=20 to 100 by 20;
						where &where;
						run; 

						PROC SQL;
						Create table work.idb1 as
						select idb.*,
							   (CASE 
						   		WHEN EQ_INC20 < OUTW.P_20 THEN 1 
						   		WHEN EQ_INC20 < OUTW.P_40 THEN 2 
						   		WHEN EQ_INC20 < OUTW.P_60 THEN 3 
						   		WHEN EQ_INC20 < OUTW.P_80 THEN 4 
						   		ELSE  5 
								END ) AS QITILES
						from work.idb inner join work.outw on idb.DB020 = outw.DB020
						where &where;
						QUIT;
					

						PROC SQL;
						Create table work.tmp0 as
						select distinct sum(RB050a) as totwgh
						from  work.idb1;


						Create table work.tmp1 as
						select distinct sum(RB050a * EQ_INC20) as s20, count(db010) as ntot20
						from  work.idb1
						where QITILES=1;


						Create table work.tmp2 as
						select distinct sum(RB050a * EQ_INC20) as s80, count(db010) as ntot80
						from  work.idb1
						where QITILES=5;
						QUIT;
					
						proc sql;
						create table old_flag1 as select distinct iflag from old_flag
						where sex=&sex and age=&age;
						run;
						/* to check if old_flag1 is empty  */
						proc sql;
							Select distinct count(iflag) as N 
							into :nobs
							from  old_flag1;
						quit;
					
						%if &nobs = 0 %then %do;
							data old_flag1;  iflag=" "; run;
						%end;
						
                        /* end check */
				
						PROC SQL;
						INSERT INTO di11 SELECT 
							"&Ucc" as geo,
							&yyyy as time,
							(&age) as age, 
							(&sex) as sex,
							"S80_S20" as indic_il,
							(S80 / S20) as ivalue,
							old_flag1.iflag, 
							(case when min(ntot20,ntot80) < 20 then 2
								  when min(ntot20,ntot80) < 50 then 1
								  else 0
							      end) as unrel,
							ntot20,
							ntot80,
							totwgh,
							"&sysdate" as lastup,
							"&sysuserid" as	lastuser 
						FROM work.tmp0, work.tmp1, work.tmp2, work.old_flag1;
						QUIT;
						%mend s20s80;
						
		%s20s80("TOTAL","T",(1));
		
		%s20s80("TOTAL","M",(RB090=1));

		%s20s80("TOTAL","F", (RB090=2));

		%s20s80("Y_LT65","T",(age<=64));

		%s20s80("Y_LT65","M",(age<=64 and RB090=1));

		%s20s80("Y_LT65","F",(age<=64 and RB090=2));

		%s20s80("Y_GE65","T",(age>=65));

		%s20s80("Y_GE65","M",(age>=65 and RB090=1));

		%s20s80("Y_GE65","F",(age>=65 and RB090=2));
	%end;
 
	* Update RDB;  
	DATA  rdb.DI11;
	set rdb.DI11(where=(not(time = &yyyy and geo = "&Ucc")))
	    work.di11; 
	run;  
 
PROC SQL;  
     Insert into log.log
     set date = "&sysdate"d, time = "&systime"t, user = "&sysuserid",
		 report = "* &Ucc - &yyyy * DI11 (re)calculated *";		  
QUIT;

%end;
%else %do; 
PROC SQL;  
     Insert into log.log
     set date = "&sysdate"d, time = "&systime"t, user = "&sysuserid",
		 report = "* &Ucc - &yyyy * NO DATA !";		  
QUIT;
%end;
%mend UPD_di11;
