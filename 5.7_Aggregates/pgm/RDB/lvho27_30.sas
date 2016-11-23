%macro UPD_lvho27_30(yyyy,Ucc,Uccs,flag,notBDB);
/*Housing cost burden over 25 % 40% 50% 60% 75 % of disposable income by TENURE -  total population */
/*20141106MG to check if working datasets IDB is empty */


PROC DATASETS lib=work kill nolist;
QUIT;

%let cc=%lowcase(&Ucc);
%let yy=%substr(&yyyy,3,2);
%let EU=0;
%let DB100Missing=0;
%if &Uccs=0 %then %let Uccs=("&Ucc");
%else %let EU=1;

%let not60=0;
%let c_obs27=0;
%let c_obs28=0;
%let c_obs29=0;
%let c_obs30=0;

%let nobs=0;
%let Nm=0;

%if not (&UCC = DE and &year < 2010) %then %do; /* PP 06/12/12 DE now OK for years from 2010 on */

	%if &EU=0 %then %do;

	PROC FORMAT;
	VALUE f_sex (multilabel)
			1 = "M"
			2 = "F"
			1 - 2 = "T"
			; 

	VALUE f_indic_il (multilabel)
	          0 = "0"
			25 = "A25DI"
			30 = "A30DI"
			40 = "A40DI"
			50 = "A50DI"
			60 = "A60DI"
			75 = "A75DI"
			
			; 


	VALUE f_tenstatu (multilabel)
			1 = "OWN_NL"
			2 = "OWN_L"
			3 = "RENT_MKT"
			4 = "RENT_FR"
			
			;

		
	VALUE f_HHTYP (multilabel)
			1 - 8 = "HH_NDCH"
			1-4 =	 "A1" 
			6,7 = "A2"
			9 - 13 = "HH_DCH"
		
			;

	VALUE f_DEG_URB (multilabel)
			1 = "DEG1"
			2 = "DEG2"
			3 = "DEG3"
			;
	
	RUN;

	*calculate HCB (housing cost burden);
/*20141210MG  to check if  DB100 variable  is in D-PDB file:   */

data FDB100;set in.&infil.d;where DB020 in &Uccs;run;   /*20141106MG to check if working datasets IDB is empty */

Proc sql;                                   
Select distinct count(DB010) as N 
	into :nobs
	from  FDB100;
quit;
PROC MEANS DATA=FDB100 	NWAY 	N  	NMISS	;
	VAR DB100;
	CLASS DB020 ;
OUTPUT 	OUT=WORK.NUMMIS
		N()= 
		NMISS()=
	 / AUTONAME AUTOLABEL  WAYS INHERIT
	;
RUN;
Proc sql;                                                
Select distinct DB100_NMiss  as Nn  
	into :NM
	from  work.NUMMIS ;
quit;

%if &nobs=&Nm %then %let DB100Missing=1;


/* End step to check if  DB100 variable is in D-PDB file*/


	PROC SQL;
	 CREATE TABLE work.idb AS SELECT DISTINCT IDB.DB010,IDB.DB020, IDB.DB030, IDB.RB030, IDB.RB050a, IDB.HT1,
		 IDB.RB090,  IDB.TENSTA_2,IDB.HY20,   BDBh.HY070G, BDBh.HY070G_F, BDBh.HY070N,

          %if &DB100Missing=0 %then  %do ;
			  BDBd.DB100, 
		  %end;
		 BDBh.HH070,

		 (CASE WHEN BDBh.HY070G_F= -5 THEN BDBh.HY070N ELSE  BDBh.HY070G END) AS HY070,

		 (CASE WHEN (BDBh.HH070 is missing or CALCULATED HY070 is missing or IDB.HY20 is missing) THEN . 
			WHEN ((BDBh.HH070*12) - CALCULATED HY070) <= 0 THEN 0
			WHEN (IDB.HY20 - CALCULATED HY070)<=0 THEN 100
			WHEN (IDB.HY20 - CALCULATED HY070)<((BDBh.HH070*12) - CALCULATED HY070) THEN 100
			ELSE 100*(((BDBh.HH070*12) - CALCULATED HY070)/(IDB.HY20 - CALCULATED HY070)) END) AS HCB1

	 
	 
	 FROM IDB.IDB&yy AS IDB
		left join in.&infil.d as BDBd on (IDB.DB020 = BDBd.DB020 and IDB.DB030 = BDBd.DB030)
		left join in.&infil.h as BDBh on (IDB.DB020 = BDBh.HB020 and IDB.DB030 = BDBh.HB030)
		where   IDB.DB020 in &Uccs and ht1 between 1 and 13;
	QUIT;
/*Housing cost burden over 25 % 40% 50% 60% 75 % of disposable income by sex -  total population */
Proc sql;                           /*20141106MG to check if working datasets IDB is empty */
Select distinct count(DB010) as N 
	into :nobs
	from  work.idb;
quit;
	
%if &nobs > 0
	%then %do;

%let listtab=lvho28 lvho27 lvho29 lvho30;  
%let i=1; 
%let tab=%scan(&listtab,&i,%str( )); 

  %do  %while(&tab ne ); 

%macro compare(val,valx);

    %if (&DB100Missing=0 and &tab=lvho29) or &tab=lvho28 or &tab=lvho27 or &tab=lvho30 %then %do; 

	proc sql;
	CREATE TABLE work.idb_&val AS SELECT DISTINCT *,
	
			(CASE WHEN  HCB1 is missing then .
			WHEN  HCB1 > &val THEN &val
			ELSE 0 END) AS HCB
			FROM idb;
	quit;


	* calculate % missing values;
		* calculate % missing values;
	PROC SQL noprint;
	CREATE TABLE nfilled AS SELECT DISTINCT DB020, (N(RB030)) AS N1 FROM work.idb_&val WHERE HCB not is missing GROUP BY DB020;
	CREATE TABLE nmissing AS SELECT DISTINCT DB020, (N(RB030)) AS N_1 FROM work.idb_&val WHERE HCB is missing GROUP BY DB020;
	CREATE TABLE mHCB AS SELECT nfilled.DB020, (100/(N1+N_1)*N_1) AS mHCB FROM nfilled LEFT JOIN nmissing ON (nfilled.DB020 = nmissing.DB020);

	CREATE TABLE missunrel AS SELECT mHCB.DB020, 
					max(mHCB,0) AS pcmiss
		FROM mHCB;
	QUIT;
	* Housing cost overburden rate by new tenure status 
	* calc values, N and total weights;

	%if  &tab=lvho28 %then %do;

	PROC TABULATE data=work.idb_&val out=Ti_&val;
			FORMAT TENSTA_2  f_tenstatu.;
				FORMAT HCB  f_indic_il.;
			CLASS HCB /MLF;
			CLASS TENSTA_2 /MLF;	
		CLASS DB020;
		CLASS DB010;
		VAR RB050a;
		TABLE DB010 * DB020 * TENSTA_2, HCB * RB050a * (RowPctSum N Sum) /printmiss;
	RUN;
	* fill RDB variables;
	PROC SQL;
	CREATE TABLE work.old_flag AS
	SELECT 
	      time,
	      geo,
		  TENURE,
		  indic_il,
		  iflag
	FROM rdb.&tab
	WHERE  time = &yyyy ;

	CREATE TABLE work.lvho07 AS
	SELECT 
		Ti_&val..DB020 as geo FORMAT=$5. LENGTH=5,
		Ti_&val..DB010 as time,
		Ti_&val..TENSTA_2 as TENURE,
		Ti_&val..HCB as indic_il,
		"PC_POP" as unit,
		Ti_&val..RB050a_PctSum_0111 as ivalue,
		old_flag.iflag as iflag,
		(case when sum(Ti_&val..RB050a_N) < 20 or missunrel.pcmiss > 50 then 2
			  when sum(Ti_&val..RB050a_N) < 50 or missunrel.pcmiss > 20 then 1
			  else 0
		      end) as unrel,
		Ti_&val..RB050a_N as n,
		sum(Ti_&val..RB050a_N) as ntot,
		sum(Ti_&val..RB050a_Sum) as totwgh,
		"&sysdate" as lastup,
		"&sysuserid" as	lastuser 
	FROM Ti_&val LEFT JOIN missunrel ON (Ti_&val..DB020 = missunrel.DB020)
			LEFT JOIN work.old_flag ON (Ti_&val..DB020 = old_flag.geo) 
		    AND (Ti_&val..TENSTA_2 = old_flag.TENURE) 
			  AND (Ti_&val..HCB  = old_flag.indic_il)
 
			GROUP BY Ti_&val..DB020, Ti_&val..TENSTA_2;
		QUIT;
%end;
%if   &tab=lvho27 %then %do;
PROC TABULATE data=work.idb_&val out=Ti_&val;
		
			FORMAT RB090 f_sex.;
			FORMAT HCB  f_indic_il.;
			CLASS DB010;
			CLASS DB020;
			CLASS HCB /MLF;
	
			CLASS RB090 /MLF;
		
		VAR RB050a;
		TABLE DB010 * DB020  * RB090, HCB * RB050a * (RowPctSum N Sum) /printmiss;
	RUN;
	

	
	* fill RDB variables;
	PROC SQL;
	CREATE TABLE work.old_flag AS
	SELECT 
	      time,
	      geo,
		  sex,
		  indic_il,
	   	  iflag
	FROM rdb.&tab
	WHERE  time = &yyyy ;
	CREATE TABLE work.lvho07 AS
	SELECT 
		Ti_&val..DB020 as geo FORMAT=$5. LENGTH=5,
		Ti_&val..DB010 as time,
		Ti_&val..RB090 as sex,
		Ti_&val..HCB as indic_il,
		"PC_POP" as unit,
		Ti_&val..RB050a_PctSum_1101 as ivalue,
		old_flag.iflag as iflag,
		(case when sum(Ti_&val..RB050a_N) < 20 or missunrel.pcmiss > 50 then 2
			  when sum(Ti_&val..RB050a_N) < 50 or missunrel.pcmiss > 20 then 1
			  else 0
		      end) as unrel,
		Ti_&val..RB050a_N as n,
		sum(Ti_&val..RB050a_N) as ntot,
		sum(Ti_&val..RB050a_Sum) as totwgh,
		"&sysdate" as lastup,
		"&sysuserid" as	lastuser 
	FROM Ti_&val LEFT JOIN missunrel ON (Ti_&val..DB020 = missunrel.DB020)
			LEFT JOIN work.old_flag ON (Ti_&val..DB020 = old_flag.geo) 
		  AND (Ti_&val..RB090  = old_flag.sex) 
		    AND (Ti_&val..HCB  = old_flag.indic_il)
	GROUP BY Ti_&val..DB020, Ti_&val..RB090 ;
		QUIT;


%end;
%if   &tab=lvho30 %then %do;
	PROC TABULATE data=work.idb_&val out=Ti_&val;
			FORMAT HT1  f_HHTYP.;
			FORMAT HCB  f_indic_il.;
			CLASS HCB /MLF;
			CLASS HT1 /MLF;	
		CLASS DB020;
		CLASS DB010;
		VAR RB050a;
		TABLE DB010 * DB020 * HT1, HCB * RB050a * (RowPctSum N Sum) /printmiss;
	RUN;

	* fill RDB variables;
	PROC SQL;
	CREATE TABLE work.old_flag AS
	SELECT 
	      time,
	      geo,
		  HHTYP,
		  indic_il,
		  iflag
	FROM rdb.&tab
	WHERE  time = &yyyy ;

	CREATE TABLE work.lvho07 AS
	SELECT 
		Ti_&val..DB020 as geo FORMAT=$5. LENGTH=5,
		Ti_&val..DB010 as time,
		Ti_&val..HT1 as HHTYP,
	Ti_&val..HCB as indic_il,
		"PC_POP" as unit,
		/*Ti_&val..HCB,*/
		Ti_&val..RB050a_PctSum_0111 as ivalue,
		old_flag.iflag as iflag,
		(case when sum(Ti_&val..RB050a_N) < 20 or missunrel.pcmiss > 50 then 2
			  when sum(Ti_&val..RB050a_N) < 50 or missunrel.pcmiss > 20 then 1
			  else 0
		      end) as unrel,
		Ti_&val..RB050a_N as n,
		sum(Ti_&val..RB050a_N) as ntot,
		sum(Ti_&val..RB050a_Sum) as totwgh,
		"&sysdate" as lastup,
		"&sysuserid" as	lastuser 
	FROM Ti_&val LEFT JOIN missunrel ON (Ti_&val..DB020 = missunrel.DB020)
			LEFT JOIN work.old_flag ON (Ti_&val..DB020 = old_flag.geo) 
		    AND (Ti_&val..HT1 = old_flag.HHTYP) 
			 AND (Ti_&val..HCB  = old_flag.indic_il)
	GROUP BY Ti_&val..DB020, Ti_&val..HT1;
		QUIT;

%end;
%if   &tab=lvho29 %then %do;
PROC TABULATE data=work.idb_&val out=Ti_&val;
			FORMAT DB100  f_DEG_URB.;
			FORMAT HCB  f_indic_il.;
			CLASS HCB /MLF;
			CLASS DB100 /MLF;	
		CLASS DB020;
		CLASS DB010;
		VAR RB050a;
		TABLE DB010 * DB020 * DB100, HCB * RB050a * (RowPctSum N Sum) /printmiss;
	RUN;

	* fill RDB variables;
	PROC SQL;
	CREATE TABLE work.old_flag AS
	SELECT 
	      time,
	      geo,
		  DEG_URB,
		  indic_il,
		  iflag
	FROM rdb.&tab
	WHERE  time = &yyyy ;

	CREATE TABLE work.lvho07 AS
	SELECT 
		Ti_&val..DB020 as geo FORMAT=$5. LENGTH=5,
		Ti_&val..DB010 as time,
		Ti_&val..DB100 as DEG_URB,
		Ti_&val..HCB as indic_il,
		"PC_POP" as unit,
		Ti_&val..RB050a_PctSum_0111 as ivalue,
		old_flag.iflag as iflag,
		(case  when sum(Ti_&val..RB050a_N) < 20 or missunrel.pcmiss > 50 then 2
			  when sum(Ti_&val..RB050a_N) < 50 or missunrel.pcmiss > 20 then 1
			  else 0
		      end) as unrel,
		Ti_&val..RB050a_N as n,
		sum(Ti_&val..RB050a_N) as ntot,
		sum(Ti_&val..RB050a_Sum) as totwgh,
		"&sysdate" as lastup,
		"&sysuserid" as	lastuser 
	FROM Ti_&val LEFT JOIN missunrel ON (Ti_&val..DB020 = missunrel.DB020)
			LEFT JOIN work.old_flag ON (Ti_&val..DB020 = old_flag.geo) 
		    AND (Ti_&val..DB100 = old_flag.DEG_URB) AND (Ti_&val..HCB = old_flag.indic_il)
	GROUP BY Ti_&val..DB020, Ti_&val..DB100;
		QUIT;

%end;
 %if not %sysfunc(exist(&tab)) %then %do;
		 	data &tab; set lvho07(where=(indic_il = "&valx" ));run;
		 %end;
	%else %do;
		
		 data &tab;set &tab lvho07(where=(indic_il = "&valx" ));run;
		 %end;

%end;
%mend;
%compare(25,A25DI);
%compare(40,A40DI);
%compare(50,A50DI);
%compare(60,A60DI);
%compare(75,A75DI);
    %if (&DB100Missing=0 and &tab=lvho29) or &tab=lvho28 or &tab=lvho27 or &tab=lvho30 %then %do; 
	* Update RDB;
	DATA  rdb.&tab;
	set rdb.&tab(where=(not(time = &yyyy and geo in &Uccs)))
	    work.&tab; 
	RUN;
%end;




%put +UPDATED &tab;
    %let i=%eval(&i+1);                                  
	%let tab=%scan(&listtab,&i,%str( )); 
  	%end;  
%end;
%end;
	%if &EU %then %do;

	* EU aggregates;
    	%let tab=lvho28;
		%let grpdim=TENURE, indic_il,unit;
		%EUVALS(&Ucc,&Uccs);
        proc sql noprint;
			select count(*) into :c_obs28 from &tab
		quit;
		%let tab=lvho27;
		%let grpdim=sex, indic_il, unit;
		%EUVALS(&Ucc,&Uccs);
		 proc sql noprint;
			select count(*) into :c_obs27 from &tab
		quit;
		 %let tab=lvho29;
		%let grpdim=DEG_URB, indic_il,unit;
		%EUVALS(&Ucc,&Uccs);
        proc sql noprint;
			select count(*) into :c_obs28 from &tab
		quit;
		%let tab=lvho30;
		%let grpdim=HHTYP,indic_il, unit;
		%EUVALS(&Ucc,&Uccs);
		 proc sql noprint;
			select count(*) into :c_obs27 from &tab
		quit;

	%end;

	
	%if &c_obs27 > 0 %then %do;
	PROC SQL;  
     Insert into log.log
     set date = "&sysdate"d, time = "&systime"t, user = "&sysuserid",
		 report = "* &Ucc - &yyyy * lvho27  (re)calculated *";
	QUIT;
	%end;
	%if &c_obs28 > 0 %then %do;
	PROC SQL;  
     Insert into log.log
     set date = "&sysdate"d, time = "&systime"t, user = "&sysuserid",
		 report = "* &Ucc - &yyyy * lvho28  (re)calculated *";
	QUIT;
	%end;
	%if &c_obs29 > 0 %then %do;
	PROC SQL;  
     Insert into log.log
     set date = "&sysdate"d, time = "&systime"t, user = "&sysuserid",
		 report = "* &Ucc - &yyyy * lvho27  (re)calculated *";
	QUIT;
	%end;
	%if &c_obs30 > 0 %then %do;
	PROC SQL;  
     Insert into log.log
     set date = "&sysdate"d, time = "&systime"t, user = "&sysuserid",
		 report = "* &Ucc - &yyyy * lvho28  (re)calculated *";
	QUIT;
	%end;
		
%end;
%else %do;
	PROC SQL;  
	     Insert into log.log
	     set date = "&sysdate"d, time = "&systime"t, user = "&sysuserid",
		 report = "* &Ucc - &yyyy * NO lvho27_30 CALCULATION ALLOWED FOR *";		  
	QUIT;
%end;

%let not60=0;
%mend UPD_lvho27_30;
