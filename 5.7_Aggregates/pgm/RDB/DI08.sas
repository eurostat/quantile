*** Mean and median income by education level  ***;

/*20122802MG CREATED from LI07 TO MAKE THE AGGREGATES CALCULATIONS */
%macro UPD_DI08(yyyy,Ucc,Uccs,flag) /store;

PROC DATASETS lib=work kill nolist;
QUIT;
%let tab=di08;
%let cc=%lowcase(&Ucc);
%let yy=%substr(&yyyy,3,2);
%let EU=0;
%if &Uccs=0 %then %let Uccs=("&Ucc");
%else %let EU=1; 

PROC FORMAT;
    VALUE f_age (multilabel)
		18 - HIGH = "Y_GE18"

		18 - 64 = "Y18-64"

		65 - HIGH = "Y_GE65"

		;

	VALUE f_sex (multilabel)
		1 = "M"
		2 = "F"
		1 - 2 = "T";

	VALUE f_educ 
		0 - 2 = "ED0-2"
		3 - 4 = "ED3_4"
		5 - 6 = "ED5_6";
RUN;

PROC SQL noprint;
Create table work.idb as 
	select DB010, DB020, DB030, RB030, PB040,  Age, RB090, PE40, EQ_INC20, 
		rate, ppp    
	from idb.IDB&yy
	where age GE 18 and PE40 ge 0 and DB010 = &yyyy and DB020 in &Uccs;
Select distinct count(DB010) as N 
	into :nobs
	from  work.idb;
Create table work.&tab like rdb.&tab; 
QUIT;

%if &nobs > 0
%then %do;
PROC SQL;
CREATE TABLE work.old_flag AS
SELECT distinct
      time,
      geo,
 	  sex,
	  isced97,
	  indic_il,
	  iflag
FROM rdb.&tab
WHERE  time = &yyyy and geo="&Ucc" ;
quit;
%if &EU=0 %then %do;
	
	PROC MEANS data=work.idb median sumwgt qmethod=os noprint;  
		FORMAT AGE f_age9.;
		FORMAT PE40 f_educ.;
		FORMAT RB090 f_sex.;
		CLASS AGE /MLF;
		CLASS RB090 /MLF;
		CLASS PE40 /MLF;
    	var EQ_INC20;
		id DB010 DB020 rate ppp;
		weight PB040;
		output out=work.mm1 mean()=MEANINC median()=MEDIANINC n=n sumwgt=totwgh;;
	run;

/* PROCESS TO APPEND  MEANINC value after MEDIANINC  inserting the UNIT variable  */
	data mm1;set mm1; where _type_ = 7 ;ntot=n; run;
	
	data mm1(drop= _FREQ_  _TYPE_);set mm1;run;
	data md (drop=MEDIANINC rate ppp rename=(MEANINC=ivalue));set mm1;
	 	indic_il="MEI_E";
		UNIT="NAC";
	run;
	data md;format DB010 DB020 CHLD WORK_INT age RB090 INDIC_IL UNIT;
						set md;run;
						
	data mde (drop=MEDIANINC MEANINC rate ppp rename=(MEANINCe=ivalue) );set mm1;
		indic_il="MEI_E";
		MEANINCe=MEANINC/rate;
		UNIT="EUR";
	run;
	data mde;format DB010 DB020 CHLD WORK_INT age RB090 INDIC_IL UNIT;
						set mde;run;
						
	data mdp (drop=MEDIANINC MEANINC rate ppp rename=(MEANINCp=ivalue) );set mm1;
		indic_il="MEI_E";
		MEANINCp=MEANINC/ppp;
		UNIT="PPS";
	run;
	/* format the mdp output in order to make the merge */
	
	data mdp;format DB010 DB020 CHLD WORK_INT age RB090 INDIC_IL UNIT;
						set mdp;run;
						
/* define the indic_il   for median  and calculation of MEANINC for EUR and PPS  */

	data memd (drop=MEANINC rate ppp  rename=(MEDIANINC=ivalue)) ;set mm1; 
		indic_il="MED_E";
		UNIT="NAC";
	run; 

	data memd;format DB010 DB020 CHLD WORK_INT age RB090 INDIC_IL UNIT;
		set memd;run;

	data memde (drop=MEANINC MEDIANINC rate ppp rename=(MEDIANINCe=ivalue) ) ;set mm1; 
		indic_il="MED_E";
		MEDIANINCe=MEDIANINC/rate;
		UNIT="EUR";
	run; 
	data memde;format DB010 DB020 CHLD WORK_INT age RB090 INDIC_IL UNIT;
	set memde;run;

	data memdp (drop=MEANINC MEDIANINC rate ppp rename=(MEDIANINCp=ivalue) ) ;set mm1; 
		indic_il="MED_E";
		MEDIANINCp=MEDIANINC/ppp;
		UNIT="PPS";
	run; 
	data memdp;format DB010 DB020 CHLD WORK_INT age RB090 INDIC_IL UNIT;
	set memdp;run;
						
/* merge mean with median one after the other*/
	data TotValue; 				
						set memde memdp memd mde mdp md; run;
						
/* END APPEND PROCESS */

	Proc sql;
	INSERT INTO &tab SELECT 
					"&Ucc" as geo,
					&yyyy as time,
					TotValue.Age,
					TotValue.RB090 as sex,
					TotValue.PE40 as isced97,
					TotValue.indic_il as indic_il,
					TotValue.unit as unit,
					TotValue.ivalue as ivalue,
					old_flag.iflag as iflag, 
					(case when ntot < 20 then 2
						  when ntot < 50 then 1
						  else 0
					      end) as unrel,
					TotValue.n as n,
					ntot,
					totwgh,
					"&sysdate" as lastup,
					"&sysuserid" as	lastuser 
				FROM TotValue 	LEFT JOIN work.old_flag ON ("&Ucc" = old_flag.geo) 
					AND (TotValue.RB090 = old_flag.sex)  AND (TotValue.PE40 = old_flag.isced97) and (TotValue.indic_il = old_flag.indic_il); 
				QUIT;


* Update RDB;   
DATA  rdb.&tab;
set rdb.&tab(where=(not(time = &yyyy and geo = "&Ucc")))
    work.&tab; 
run;  
%end;
%if &EU %then %do;
* EU aggregates;
	%let tab=&tab;
	%let grpdim=age,sex,isced97,indic_il,unit;
	%EUVALS(&Ucc,&Uccs);
%end;
 
PROC SQL;  
     Insert into log.log
     set date = "&sysdate"d, time = "&systime"t, user = "&sysuserid",
		 report = "* &Ucc - &yyyy * &tab (re)calculated *";		  
QUIT;

%end;
%else %do; 
PROC SQL;  
     Insert into log.log
     set date = "&sysdate"d, time = "&systime"t, user = "&sysuserid",
		 report = "* &Ucc - &yyyy * NO DATA !";		  
QUIT;
%end;

%mend UPD_DI08;
