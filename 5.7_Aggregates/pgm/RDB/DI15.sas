*** Median income by age and gender and citizen ***;
%macro UPD_DI15(yyyy,Ucc,Uccs,flag) /store;
/*20130710MG CREATED from DI03 */
PROC DATASETS lib=work kill nolist;
QUIT;

%let tab=di15;
%let cc=%lowcase(&Ucc);
%let yy=%substr(&yyyy,3,2);
%let EU=0;
%if &Uccs=0 %then %let Uccs=("&Ucc");
%else %let EU=1; 

*** At-risk-poverty-rate by age and gender ***;
PROC FORMAT;
VALUE f_age (multilabel)
        18 - HIGH = "Y_GE18"

		18 - 64 = "Y18-64"
		20 - 64 = "Y20-64"

		65 - HIGH = "Y_GE65"

		18 - 59 = "Y18-59"

		60 - HIGH = "Y_GE60"

		18 - 54 = "Y18-54"

		25 - 59 = "Y25-59"

		25 - 54 = "Y25-54"
		20 - 64 = "Y20-64"
		55 - 64 = "Y55-64"

		55 - HIGH = "Y_GE55";
		;
VALUE f_CIT_SHIP (multilabel)
		1 = "NAT"
		3 = "EU27_FOR"
		2 = "NEU27_FOR"
		6 = "EU28_FOR"
		4 = "NEU28_FOR"
		2 - 6 = "FOR" ;
		
	VALUE f_sex (multilabel)
		1 = "M"
		2 = "F"
		1 - 2 = "T";
RUN;
PROC SQL noprint;
Create table work.idb as 
	select DB010, DB020, DB030, RB030, RB050a,  Age, RB090, EQ_INC20, rate, ppp,CIT_SHIP
		
	from idb.IDB&yy
	where age ge 18 and DB010 = &yyyy and DB020 in &Uccs;
	
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
	  age,
	  sex,
	  citizen,
	  indic_il,
	  unit,
	  iflag
	  FROM rdb.&tab
WHERE  time = &yyyy and geo="&Ucc"  
group by time, geo /*,age */, sex, citizen, unit ;

QUIT;

%if &EU =0 %then %do;
	PROC MEANS data=work.idb median sumwgt qmethod=os noprint;  
		FORMAT AGE f_age15.;
		FORMAT RB090 f_sex.;
		FORMAT CIT_SHIP f_cit_ship15.;
		CLASS AGE /MLF;
		CLASS RB090 /MLF;
		Class CIT_SHIP /MLF;
		var EQ_INC20;
		id DB010 DB020 rate ppp;
		weight RB050a;
		output out=work.mm mean()=MEANINC median()=MEDIANINC n=n sumwgt=totwgh;
	run;
/* PROCESS TO APPEND  MEANINC value after MEDIANINC  inserting the UNIT variable  */	
		data mm(drop=_freq_ _type_);set mm;where _type_=7;run;
	
/* rename n                */
	data mm    ;set mm; 
		ntot=n;
		run;
		
/* define the indic_il  for mean  and calculation of MEANINC for EUR and PPS   */

	data md (drop=MEDIANINC rate ppp rename=(MEANINC=ivalue));set mm;
	 	indic_il="MEI_E";
		UNIT="NAC";
	run;

	data mde (drop=MEDIANINC MEANINC rate ppp rename=(MEANINCe=ivalue) );set mm;
		indic_il="MEI_E";
		MEANINCe=MEANINC/rate;
		UNIT="EUR";
	run;
	data mde;format AGE RB090 DB010 DB020 ivalue;
						set mde;run;
						
	data mdp (drop=MEDIANINC MEANINC rate ppp rename=(MEANINCp=ivalue) );set mm;
		indic_il="MEI_E";
		MEANINCp=MEANINC/ppp;
		UNIT="PPS";
	run;
	/* format the mdp output in order to make the merge */
	
		data mdp;format AGE RB090 DB010 DB020 ivalue;
						set mdp;run;
						
/* define the indic_il   for median  and calculation of MEANINC for EUR and PPS  */

	data memd (drop=MEANINC rate ppp  rename=(MEDIANINC=ivalue)) ;set mm; 
		indic_il="MED_E";
		UNIT="NAC";
	run; 
	data memde (drop=MEANINC MEDIANINC rate ppp rename=(MEDIANINCe=ivalue) ) ;set mm; 
		indic_il="MED_E";
		MEDIANINCe=MEDIANINC/rate;
		UNIT="EUR";
	run; 
	data memde;format AGE RB090 DB010 DB020 ivalue;
						set memde;run;
	data memdp (drop=MEANINC MEDIANINC rate ppp rename=(MEDIANINCp=ivalue) ) ;set mm; 
		indic_il="MED_E";
		MEDIANINCp=MEDIANINC/ppp;
		UNIT="PPS";
	run; 
	
/* format the memdp output in order to make the merge */
		data memdp;format AGE RB090 DB010 DB020 ivalue;
						set memdp;run;
						
/* merge mean with median one below another*/
	data TotValue; 				
						set memde memdp memd mde mdp md; run;
												 
/* END APPEND PROCESS */  
	proc sql;
 	INSERT INTO &tab SELECT 
			"&Ucc" as geo,
			&yyyy as time,
			TotValue.age as age,
			TotValue.RB090  as sex,
			TotValue.CIT_SHIP as citizen,
			TotValue.indic_il as indic_il,
			TotValue.unit as unit,
			TotValue.ivalue as ivalue,
			old_flag.iflag as iflag, 
		 	(case when ntot < 20 then 2
				  when ntot < 50 then 1
				  else 0
			      end) as unrel,
			TotValue.n as n,
			TotValue.ntot as ntot,
			TotValue.totwgh as totwgh,
			"&sysdate" as lastup,
			"&sysuserid" as	lastuser 
		FROM TotValue LEFT JOIN work.old_flag ON ("&Ucc" = old_flag.geo) and (TotValue.age = old_flag.age)
		AND (TotValue.RB090 = old_flag.sex) and (TotValue.CIT_SHIP = old_flag.citizen) and (TotValue.indic_il = old_flag.indic_il) and  (TotValue.unit = old_flag.unit);

 quit; 
	
 
* Update RDB;  
DATA  rdb.&tab;
set rdb.&tab(where=(not(time = &yyyy and geo = "&Ucc")))
    work.&tab; 
run; 
%end;

* EU aggregates;
%if &EU %then %do;
	%let tab=&tab;
	%let grpdim= age,sex,citizen,indic_il,unit ;
	%EUVALS(&Ucc,&Uccs);
%end;

PROC SQL;  
     Insert into log.log
     set date = "&sysdate"d, time = "&systime"t, user = "&sysuserid",
		 report = "* &Ucc - &yyyy * DI15 (re)calculated *";		  
QUIT;

%end;
%else %do; 
PROC SQL;  
     Insert into log.log
     set date = "&sysdate"d, time = "&systime"t, user = "&sysuserid",
		 report = "* &Ucc - &yyyy * NO DATA !";		  
QUIT;
%end;

%mend UPD_DI15;
