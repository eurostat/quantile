*** Mean and median income by deg_urb status  ***;

/*20122902MG CREATED from LI08 TO MAKE THE AGGREGATES CALCULATIONS */

%macro UPD_di17(yyyy,Ucc,Uccs,flag) /store;

PROC DATASETS lib=work kill nolist;
QUIT;
%let tab=di17;
%let cc=%lowcase(&Ucc);
%let yy=%substr(&yyyy,3,2);
%let EU=0;
%if &Uccs=0 %then %let Uccs=("&Ucc");
%else %let EU=1; 


*** At-risk-poverty-rate by age and gender ***;
PROC FORMAT;
	VALUE f_urb(multilabel)
		1,2 = "TOTAL"
		1 = "OWN"
		2 = "RENT";

	VALUE f_sex (multilabel)
		1 = "M"
		2 = "F"
		1 - 2 = "T";

    VALUE f_age (multilabel)
		0 - 17 = "Y_LT18"

		18 - HIGH = "Y_GE18"

		18 - 64 = "Y18-64"

		65 - HIGH = "Y_GE65"

		60 - HIGH = "Y_GE60"

		75 - HIGH = "Y_GE75"

		0 - HIGH = "TOTAL"
		;
		
	VALUE f_urb (multilabel)
		1 = "DEG1"
		2 = "DEG2"
		3 = "DEG3"
	
		;

RUN;

PROC SQL noprint;
Create table work.idb as 
	select idb.DB010, idb.DB020, idb.DB030, idb.RB030,  RB050a,  idb.Age, idb.RB090, d.DB100, EQ_INC20, 
			idb.rate, idb.ppp     
	from idb.IDB&yy as idb
	left join in.&infil.d as d on (IDB.DB020 = d.DB020 and IDB.DB030 = d.DB030)
	where idb.AGE GE 0 and idb.DB010 = &yyyy and d.DB100 in (1,2,3) and idb.DB020 in &Uccs;
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
	  deg_urb,
	  indic_il,
	  sex,
	  iflag
FROM rdb.&tab
WHERE  time = &yyyy and geo="&Ucc" ;	
quit;
%if &EU=0 %then %do;
	
	PROC MEANS data=work.idb median sumwgt qmethod=os noprint;  
		FORMAT DB100 f_urb15.;
		FORMAT RB090 f_sex.;
		FORMAT AGE f_age15.;
		CLASS DB100 /MLF;
		CLASS RB090 /MLF;
		CLASS AGE /MLF;
    	var EQ_INC20;
		id DB010 DB020 rate ppp;
		weight RB050a;
		output out=work.mm1 mean()=MEANINC median()=MEDIANINC n=n sumwgt=totwgh;
	run;
	
/* PROCESS TO APPEND  MEANINC value after MEDIANINC  inserting the UNIT variable  */

	data mm1;set mm1; where _type_ = 7 ;ntot=n; run;
	
	data mm1(drop= _FREQ_  _TYPE_);set mm1;run;
	data md (drop=MEDIANINC rate ppp rename=(MEANINC=ivalue));set mm1;
	 	indic_il="MEI_E";
		UNIT="NAC";
	run;
	data md;format DB010 DB020 AGE RB090  DB100 INDIC_IL UNIT ivalue;
						set md;run;
						
	data mde (drop=MEDIANINC MEANINC rate ppp rename=(MEANINCe=ivalue) );set mm1;
		indic_il="MEI_E";
		MEANINCe=MEANINC/rate;
		UNIT="EUR";
	run;
	data mde;format DB010 DB020 AGE RB090  DB100 INDIC_IL UNIT ivalue;
						set mde;run;
						
	data mdp (drop=MEDIANINC MEANINC rate ppp rename=(MEANINCp=ivalue) );set mm1;
		indic_il="MEI_E";
		MEANINCp=MEANINC/ppp;
		UNIT="PPS";
	run;
	
	/* format the mdp output in order to make the merge */
	
	data mdp;format DB010 DB020 AGE RB090  DB100 INDIC_IL UNIT ivalue;
						set mdp;run;
						
/* define the indic_il   for median  and calculation of MEANINC for EUR and PPS  */

	data memd (drop=MEANINC rate ppp  rename=(MEDIANINC=ivalue)) ;set mm1; 
		indic_il="MED_E";
		UNIT="NAC";
	run; 

	data memd;format DB010 DB020 AGE RB090  DB100 INDIC_IL UNIT ivalue;
		set memd;run;

	data memde (drop=MEANINC MEDIANINC rate ppp rename=(MEDIANINCe=ivalue) ) ;set mm1; 
		indic_il="MED_E";
		MEDIANINCe=MEDIANINC/rate;
		UNIT="EUR";
	run; 
	data memde;format DB010 DB020 AGE RB090  DB100 INDIC_IL UNIT ivalue;
	set memde;run;

	data memdp (drop=MEANINC MEDIANINC rate ppp rename=(MEDIANINCp=ivalue) ) ;set mm1; 
		indic_il="MED_E";
		MEDIANINCp=MEDIANINC/ppp;
		UNIT="PPS";
	run; 
	data memdp;format DB010 DB020 AGE RB090  DB100 INDIC_IL UNIT ivalue;
	set memdp;run;
						
/* merge mean with median one after the other*/

	data TotValue; 				
						set memde memdp memd mde mdp md; run;
						
/* END APPEND PROCESS */
	proc sql;
				
				INSERT INTO &tab SELECT 
					"&Ucc" as geo,
					&yyyy as time,
					TotValue.Age,
					TotValue.RB090 as sex,
					TotValue.DB100 as deg_urb,
					TotValue.indic_il as indic_il,
					TotValue.unit as unit,
					TotValue.ivalue,
					old_flag.iflag as iflag, 
						(case when ntot < 20 then 2
						  when ntot < 50 then 1
						  else 0
					      end) as unrel,
					n,
					ntot,
			    	totwgh,
					"&sysdate" as lastup,
					"&sysuserid" as	lastuser 
				FROM TotValue LEFT JOIN work.old_flag ON ("&Ucc" = old_flag.geo) AND (TotValue.DB100 = old_flag.deg_urb)
				AND (TotValue.RB090 = old_flag.sex) and (TotValue.indic_il = old_flag.indic_il); 
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
	%let grpdim=age,sex,deg_urb,indic_il,unit;
	%EUVALS(&Ucc,&Uccs);
%end;
PROC SQL;  
     Insert into log.log
     set date = "&sysdate"d, time = "&systime"t, user = "&sysuserid",
		 report = "* &Ucc - &yyyy * di17 (re)calculated *";		  
QUIT;

%end;
%else %do; 
PROC SQL;  
     Insert into log.log
     set date = "&sysdate"d, time = "&systime"t, user = "&sysuserid",
		 report = "* &Ucc - &yyyy * NO DATA !";		  
QUIT;
%end;

%mend UPD_di17;
