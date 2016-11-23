%macro UPD_DI01(yyyy,Ucc,Uccs,flag) /store;
/**********************************************************/
/** Program : z:\IDB_RDB_TEST\pgm                         */
/*           DI01.sas                                     */
/*--------------------------------------------------------*/
/* Auteur  : Marina Grillo                                */
/* Date    : 01/02/2011                                   */
/* Sujet   : Decile Percintile quartile Quintile          */
/* Modified   : 15/01/2012                                */
/*  added the total VALUES IT IS CALCULATED WHEN 		  */
/*           &percent=percentile                          */
/*  removed the last quantile       20111114MG            */
/*  modified EU aggregates method   20120117MG            */
/*  modified quantile calculation for indic_il=share      */
/*           uses the current area and not the cumulated  */
/*           area as before   20120221MG                  */
/*  modified ntot calculation                             */
/*           01112013MG                                   */
/**********************************************************/
PROC DATASETS lib=work kill nolist;
QUIT;
%let tab=DI01;
%let lEQ_INC20 = equivalised income in NA;
%let lEQ_INC20eur = equivalised income in EUROS;
%let lEQ_INC20ppp = equivalised income in PPP;
%let cc=%lowcase(&Ucc);
%let yy=%substr(&yyyy,3,2);
%let EU=0;
%if &Uccs=0 %then %let Uccs=("&Ucc");
%else %let EU=1; 

PROC SQL noprint;
CREATE TABLE work.idb AS SELECT
	 DB010,
	 DB020 AS COUNTRY,
	 RB030,
	 RB050a,
	 EQ_INC20eur,
	 EQ_INC20ppp,
	 EQ_INC20
	from idb.IDB&yy
	where age ge 0 and DB010 = &yyyy and DB020 in &Uccs;
Select distinct count(DB010) as N 
	into :nobs
	from  work.idb;
Create table work.DI01 like rdb.DI01; 
QUIT;

%if &nobs > 0
%then %do;
proc sql;
CREATE TABLE work.old_flag AS
SELECT distinct
      time,
      geo,
	  indic_il,
	  quantile,
	  iflag
	  FROM rdb.&tab
WHERE  time = &yyyy and geo="&Ucc"  
group by time, geo , indic_il, quantile ;

QUIT;


	%macro Percentile (typ,inc,year, weight,Ucc, percentile);
	%if &percentile=decile %then %do;
		%let text1=DECILE;
		%let text2= (P_10={LABEL='DECILE 1'}  *F=12.0
		  P_20={LABEL='DECILE 2'}  *F=12.0
		  P_30={LABEL='DECILE 3'}  *F=12.0
		  P_40={LABEL='DECILE 4'}  *F=12.0
		  P_50={LABEL='DECILE 5'}  *F=12.0
		  P_60={LABEL='DECILE 6'}  *F=12.0
		  P_70={LABEL='DECILE 7'}  *F=12.0
		  P_80={LABEL='DECILE 8'}  *F=12.0
		  P_90={LABEL='DECILE 9'}  *F=12.0  
		  P_100={LABEL='DECILE 10'}  *F=12.0);
    	  %let text3=(CASE 
   		  WHEN idb.&inc < OUTW.P_10 THEN "DECILE1" 
		  WHEN idb.&inc < OUTW.P_20 THEN "DECILE2" 
		  WHEN idb.&inc < OUTW.P_30 THEN "DECILE3" 
   		  WHEN idb.&inc < OUTW.P_40 THEN "DECILE4" 
   		  WHEN idb.&inc < OUTW.P_50 THEN "DECILE5" 
   		  WHEN idb.&inc < OUTW.P_60 THEN "DECILE6" 
  		  WHEN idb.&inc < OUTW.P_70 THEN "DECILE7" 
  		  WHEN idb.&inc < OUTW.P_80 THEN "DECILE8" 
  		  WHEN idb.&inc < OUTW.P_90 THEN "DECILE9" 
   		  ELSE  "DECILE10" 
		  END ) AS DECILE;
     %end;

     %if &percentile=quintile %then %do;
	 %let text1=QUINTILE;
  	 %let text2= (P_20={LABEL='QUINTILE 1'}  *F=12.0
		  P_40={LABEL='QUINTILE 2'}  *F=12.0
		  P_60={LABEL='QUINTILE 3'}  *F=12.0
		  P_80={LABEL='QUINTILE 4'}  *F=12.0 
		  P_100={LABEL='QUINTILE 5'}  *F=12.0);

 	 %let text3=(CASE 
   		WHEN idb.&inc < OUTW.P_20 THEN "QUINTILE1" 
   		WHEN idb.&inc < OUTW.P_40 THEN "QUINTILE2"
   		WHEN idb.&inc < OUTW.P_60 THEN "QUINTILE3" 		
  		WHEN idb.&inc < OUTW.P_80 THEN "QUINTILE4" 
   		ELSE "QUINTILE5" 
		END ) AS QUINTILE;
	%end;

	%if &percentile=quartile %then %do;
	%let text1=QUARTILE;
	%let text2= (P_25={LABEL='QUARTILE 1'}  *F=12.0
		  P_50={LABEL='QUARTILE 2'}  *F=12.0
		  P_75={LABEL='QUARTILE 3'}  *F=12.0 
          P_100={LABEL='QUARTILE 4'}  *F=12.0);
    %let text3=(CASE 
   		WHEN idb.&inc < OUTW.P_25 THEN "QUARTILE1" 
   		WHEN idb.&inc < OUTW.P_50 THEN "QUARTILE2" 
   		WHEN idb.&inc < OUTW.P_75 THEN "QUARTILE3" 		
   		ELSE "QUARTILE4" 
		END ) AS QUARTILE;
   %end; 
   %if &percentile=percentile %then %do;
	   %let text1=PERCENTILE;

	  %let text2= (P_1={LABEL='PERCENTILE 1'}  *F=12.0
		  P_2={LABEL='PERCENTILE 2'}  *F=12.0
		  P_3={LABEL='PERCENTILE 3'}  *F=12.0
		  P_4={LABEL='PERCENTILE 4'}  *F=12.0 
		  P_5={LABEL='PERCENTILE 5'}  *F=12.0 
		  P_6={LABEL='PERCENTILE 6'}  *F=12.0 
		  P_7={LABEL='PERCENTILE 7'}  *F=12.0 
		  P_8={LABEL='PERCENTILE 8'}  *F=12.0 
		  P_9={LABEL='PERCENTILE 9'}  *F=12.0 
		  P_10={LABEL='PERCENTILE 10'}  *F=12.0 
		  P_11={LABEL='PERCENTILE 11'}  *F=12.0 
		  P_12={LABEL='PERCENTILE 12'}  *F=12.0 
		  P_13={LABEL='PERCENTILE 13'}  *F=12.0 
		  P_14={LABEL='PERCENTILE 14'}  *F=12.0 
		  P_15={LABEL='PERCENTILE 15'}  *F=12.0 
		  P_16={LABEL='PERCENTILE 16'}  *F=12.0 
		  P_17={LABEL='PERCENTILE 17'}  *F=12.0 
		  P_18={LABEL='PERCENTILE 18'}  *F=12.0 
		  P_19={LABEL='PERCENTILE 19'}  *F=12.0
			 P_20={LABEL='PERCENTILE 20'}  *F=12.0
			 P_21={LABEL='PERCENTILE 21'}  *F=12.0
			 P_22={LABEL='PERCENTILE 22'}  *F=12.0
			 P_23={LABEL='PERCENTILE 23'}  *F=12.0
			 P_24={LABEL='PERCENTILE 24'}  *F=12.0
			 P_25={LABEL='PERCENTILE 25'}  *F=12.0
			 P_26={LABEL='PERCENTILE 26'}  *F=12.0
			 P_27={LABEL='PERCENTILE 27'}  *F=12.0
			 P_28={LABEL='PERCENTILE 28'}  *F=12.0
			 P_29={LABEL='PERCENTILE 29'}  *F=12.0
			 P_30={LABEL='PERCENTILE 30'}  *F=12.0
			 P_31={LABEL='PERCENTILE 31'}  *F=12.0
			 P_32={LABEL='PERCENTILE 32'}  *F=12.0
		 P_33={LABEL='PERCENTILE 33'}  *F=12.0
		 P_34={LABEL='PERCENTILE 34'}  *F=12.0
		 P_35={LABEL='PERCENTILE 35'}  *F=12.0
		 P_36={LABEL='PERCENTILE 36'}  *F=12.0
		 P_37={LABEL='PERCENTILE 37'}  *F=12.0
    	 P_38={LABEL='PERCENTILE 38'}  *F=12.0
	     P_39={LABEL='PERCENTILE 39'}  *F=12.0
		 P_40={LABEL='PERCENTILE 40'}  *F=12.0
		 P_41={LABEL='PERCENTILE 41'}  *F=12.0
	P_42={LABEL='PERCENTILE 42'}  *F=12.0
	P_43={LABEL='PERCENTILE 43'}  *F=12.0
	P_44={LABEL='PERCENTILE 44'}  *F=12.0
	P_45={LABEL='PERCENTILE 45'}  *F=12.0
	P_46={LABEL='PERCENTILE 46'}  *F=12.0
	P_47={LABEL='PERCENTILE 47'}  *F=12.0
	P_48={LABEL='PERCENTILE 48'}  *F=12.0
	P_49={LABEL='PERCENTILE 49'}  *F=12.0
	P_50={LABEL='PERCENTILE 50'}  *F=12.0
	P_51={LABEL='PERCENTILE 51'}  *F=12.0
	P_52={LABEL='PERCENTILE 52'}  *F=12.0
	P_53={LABEL='PERCENTILE 53'}  *F=12.0
	P_54={LABEL='PERCENTILE 54'}  *F=12.0
	P_55={LABEL='PERCENTILE 55'}  *F=12.0
	P_56={LABEL='PERCENTILE 56'}  *F=12.0
	P_57={LABEL='PERCENTILE 57'}  *F=12.0
	P_58={LABEL='PERCENTILE 58'}  *F=12.0
	P_59={LABEL='PERCENTILE 59'}  *F=12.0
	P_60={LABEL='PERCENTILE 60'}  *F=12.0
	P_61={LABEL='PERCENTILE 61'}  *F=12.0
	P_62={LABEL='PERCENTILE 62'}  *F=12.0
	P_63={LABEL='PERCENTILE 63'}  *F=12.0
	P_64={LABEL='PERCENTILE 64'}  *F=12.0
	P_65={LABEL='PERCENTILE 65'}  *F=12.0
	P_66={LABEL='PERCENTILE 66'}  *F=12.0
	P_67={LABEL='PERCENTILE 67'}  *F=12.0
	P_68={LABEL='PERCENTILE 68'}  *F=12.0
	P_69={LABEL='PERCENTILE 69'}  *F=12.0	
	P_70={LABEL='PERCENTILE 70'}  *F=12.0
	P_71={LABEL='PERCENTILE 71'}  *F=12.0
	P_72={LABEL='PERCENTILE 72'}  *F=12.0
	P_73={LABEL='PERCENTILE 73'}  *F=12.0
	P_74={LABEL='PERCENTILE 74'}  *F=12.0
	P_75={LABEL='PERCENTILE 75'}  *F=12.0
	P_76={LABEL='PERCENTILE 76'}  *F=12.0
	P_77={LABEL='PERCENTILE 77'}  *F=12.0
	P_78={LABEL='PERCENTILE 78'}  *F=12.0
	P_79={LABEL='PERCENTILE 79'}  *F=12.0
	P_80={LABEL='PERCENTILE 80'}  *F=12.0
	P_81={LABEL='PERCENTILE 81'}  *F=12.0
	P_82={LABEL='PERCENTILE 82'}  *F=12.0
	P_83={LABEL='PERCENTILE 83'}  *F=12.0
	P_84={LABEL='PERCENTILE 84'}  *F=12.0
	P_85={LABEL='PERCENTILE 85'}  *F=12.0
	P_86={LABEL='PERCENTILE 86'}  *F=12.0
	P_87={LABEL='PERCENTILE 87'}  *F=12.0
	P_88={LABEL='PERCENTILE 88'}  *F=12.0
	P_89={LABEL='PERCENTILE 89'}  *F=12.0 
	P_90={LABEL='PERCENTILE 90'}  *F=12.0 
	P_91={LABEL='PERCENTILE 91'}  *F=12.0 
	P_92={LABEL='PERCENTILE 92'}  *F=12.0 
	P_93={LABEL='PERCENTILE 93'}  *F=12.0 
	P_94={LABEL='PERCENTILE 94'}  *F=12.0 
		  P_95={LABEL='PERCENTILE 95'}  *F=12.0 
		  P_96={LABEL='PERCENTILE 96'}  *F=12.0 
		  P_97={LABEL='PERCENTILE 97'}  *F=12.0 
 		  P_98={LABEL='PERCENTILE 98'}  *F=12.0 
		  P_99={LABEL='PERCENTILE 99'}  *F=12.0 
 		  P_100={LABEL='PERCENTILE 100'}  *F=12.0)
			;
	  %let text3=(CASE 
   		WHEN idb.&inc < OUTW.P_1 THEN "PERCENTILE1" 
   		WHEN idb.&inc < OUTW.P_2 THEN "PERCENTILE2" 
   		WHEN idb.&inc < OUTW.P_3 THEN "PERCENTILE3" 	
		WHEN idb.&inc < OUTW.P_4 THEN "PERCENTILE4" 	
		WHEN idb.&inc < OUTW.P_5 THEN "PERCENTILE5" 
		WHEN idb.&inc < OUTW.P_5 THEN "PERCENTILE5" 
		WHEN idb.&inc < OUTW.P_6 THEN "PERCENTILE6" 
		WHEN idb.&inc < OUTW.P_7 THEN "PERCENTILE7" 
		WHEN idb.&inc < OUTW.P_8 THEN "PERCENTILE8" 
		WHEN idb.&inc < OUTW.P_9 THEN "PERCENTILE9" 
		WHEN idb.&inc < OUTW.P_10 THEN "PERCENTILE10" 
		WHEN idb.&inc < OUTW.P_11 THEN "PERCENTILE11" 
		WHEN idb.&inc < OUTW.P_12 THEN "PERCENTILE12" 
		WHEN idb.&inc < OUTW.P_13 THEN "PERCENTILE13" 
		WHEN idb.&inc < OUTW.P_14 THEN "PERCENTILE14" 
		WHEN idb.&inc < OUTW.P_15 THEN "PERCENTILE15" 
		WHEN idb.&inc < OUTW.P_16 THEN "PERCENTILE16" 
		WHEN idb.&inc < OUTW.P_17 THEN "PERCENTILE17" 
		WHEN idb.&inc < OUTW.P_18 THEN "PERCENTILE18" 
		WHEN idb.&inc < OUTW.P_19 THEN "PERCENTILE19" 
		WHEN idb.&inc < OUTW.P_20 THEN "PERCENTILE20" 
		WHEN idb.&inc < OUTW.P_21 THEN "PERCENTILE21" 
		WHEN idb.&inc < OUTW.P_22 THEN "PERCENTILE22" 
		WHEN idb.&inc < OUTW.P_23 THEN "PERCENTILE23" 
		WHEN idb.&inc < OUTW.P_24 THEN "PERCENTILE24" 
		WHEN idb.&inc < OUTW.P_25 THEN "PERCENTILE25" 
		WHEN idb.&inc < OUTW.P_26 THEN "PERCENTILE26" 
		WHEN idb.&inc < OUTW.P_27 THEN "PERCENTILE27" 
		WHEN idb.&inc < OUTW.P_28 THEN "PERCENTILE28" 
		WHEN idb.&inc < OUTW.P_29 THEN "PERCENTILE29" 
		WHEN idb.&inc < OUTW.P_30 THEN "PERCENTILE30" 
		WHEN idb.&inc < OUTW.P_31 THEN "PERCENTILE31" 
		WHEN idb.&inc < OUTW.P_32 THEN "PERCENTILE32" 
		WHEN idb.&inc < OUTW.P_33 THEN "PERCENTILE33" 
		WHEN idb.&inc < OUTW.P_34 THEN "PERCENTILE34" 
		WHEN idb.&inc < OUTW.P_35 THEN "PERCENTILE35" 
		WHEN idb.&inc < OUTW.P_36 THEN "PERCENTILE36" 
		WHEN idb.&inc < OUTW.P_37 THEN "PERCENTILE37" 
		WHEN idb.&inc < OUTW.P_38 THEN "PERCENTILE38" 
		WHEN idb.&inc < OUTW.P_39 THEN "PERCENTILE39" 
		WHEN idb.&inc < OUTW.P_40 THEN "PERCENTILE40" 
		WHEN idb.&inc < OUTW.P_41 THEN "PERCENTILE41" 
		WHEN idb.&inc < OUTW.P_42 THEN "PERCENTILE42" 
		WHEN idb.&inc < OUTW.P_43 THEN "PERCENTILE43" 
		WHEN idb.&inc < OUTW.P_44 THEN "PERCENTILE44" 
		WHEN idb.&inc < OUTW.P_45 THEN "PERCENTILE45" 
		WHEN idb.&inc < OUTW.P_46 THEN "PERCENTILE46" 
		WHEN idb.&inc < OUTW.P_47 THEN "PERCENTILE47" 
		WHEN idb.&inc < OUTW.P_48 THEN "PERCENTILE48" 
		WHEN idb.&inc < OUTW.P_49 THEN "PERCENTILE49" 
		WHEN idb.&inc < OUTW.P_50 THEN "PERCENTILE50" 
		WHEN idb.&inc < OUTW.P_51 THEN "PERCENTILE51" 
		WHEN idb.&inc < OUTW.P_52 THEN "PERCENTILE52" 
		WHEN idb.&inc < OUTW.P_53 THEN "PERCENTILE53" 
		WHEN idb.&inc < OUTW.P_54 THEN "PERCENTILE54" 
		WHEN idb.&inc < OUTW.P_55 THEN "PERCENTILE55" 
		WHEN idb.&inc < OUTW.P_56 THEN "PERCENTILE56" 
		WHEN idb.&inc < OUTW.P_57 THEN "PERCENTILE57" 
		WHEN idb.&inc < OUTW.P_58 THEN "PERCENTILE58" 
		WHEN idb.&inc < OUTW.P_59 THEN "PERCENTILE59" 
		WHEN idb.&inc < OUTW.P_60 THEN "PERCENTILE60" 
		WHEN idb.&inc < OUTW.P_61 THEN "PERCENTILE61" 
		WHEN idb.&inc < OUTW.P_62 THEN "PERCENTILE62" 
		WHEN idb.&inc < OUTW.P_63 THEN "PERCENTILE63" 
		WHEN idb.&inc < OUTW.P_64 THEN "PERCENTILE64" 
		WHEN idb.&inc < OUTW.P_65 THEN "PERCENTILE65" 
		WHEN idb.&inc < OUTW.P_66 THEN "PERCENTILE66" 
		WHEN idb.&inc < OUTW.P_67 THEN "PERCENTILE67" 
		WHEN idb.&inc < OUTW.P_68 THEN "PERCENTILE68" 
		WHEN idb.&inc < OUTW.P_69 THEN "PERCENTILE69" 
		WHEN idb.&inc < OUTW.P_70 THEN "PERCENTILE70" 
		WHEN idb.&inc < OUTW.P_71 THEN "PERCENTILE71" 
		WHEN idb.&inc < OUTW.P_72 THEN "PERCENTILE72" 
		WHEN idb.&inc < OUTW.P_73 THEN "PERCENTILE73" 
		WHEN idb.&inc < OUTW.P_74 THEN "PERCENTILE74" 
		WHEN idb.&inc < OUTW.P_75 THEN "PERCENTILE75" 
		WHEN idb.&inc < OUTW.P_76 THEN "PERCENTILE76" 
		WHEN idb.&inc < OUTW.P_77 THEN "PERCENTILE77" 
		WHEN idb.&inc < OUTW.P_78 THEN "PERCENTILE78" 
		WHEN idb.&inc < OUTW.P_79 THEN "PERCENTILE79" 
		WHEN idb.&inc < OUTW.P_80 THEN "PERCENTILE80" 
		WHEN idb.&inc < OUTW.P_81 THEN "PERCENTILE81" 
		WHEN idb.&inc < OUTW.P_82 THEN "PERCENTILE82" 
		WHEN idb.&inc < OUTW.P_83 THEN "PERCENTILE83" 
		WHEN idb.&inc < OUTW.P_84 THEN "PERCENTILE84" 
		WHEN idb.&inc < OUTW.P_85 THEN "PERCENTILE85" 
		WHEN idb.&inc < OUTW.P_86 THEN "PERCENTILE86" 
		WHEN idb.&inc < OUTW.P_87 THEN "PERCENTILE87" 
		WHEN idb.&inc < OUTW.P_88 THEN "PERCENTILE88" 
		WHEN idb.&inc < OUTW.P_89 THEN "PERCENTILE89" 
		WHEN idb.&inc < OUTW.P_90 THEN "PERCENTILE90" 
		WHEN idb.&inc < OUTW.P_91 THEN "PERCENTILE91" 
		WHEN idb.&inc < OUTW.P_92 THEN "PERCENTILE92" 
		WHEN idb.&inc < OUTW.P_93 THEN "PERCENTILE93" 
		WHEN idb.&inc < OUTW.P_94 THEN "PERCENTILE94" 
		WHEN idb.&inc < OUTW.P_95 THEN "PERCENTILE95" 
		WHEN idb.&inc < OUTW.P_96 THEN "PERCENTILE96" 
   		WHEN idb.&inc < OUTW.P_97 THEN "PERCENTILE97" 
   		WHEN idb.&inc < OUTW.P_98 THEN "PERCENTILE98" 	
		WHEN idb.&inc < OUTW.P_99 THEN "PERCENTILE99" 
			ELSE "PERCENTILE100" 
		END ) AS PERCENTILE;
     %end;
/* to calculte the Quantiles  */
PROC UNIVARIATE DATA=WORK.idb NOPRINT;
  VAR &inc;
  CLASS COUNTRY;
  WEIGHT &weight; 
  *OUTPUT OUT=WORK.OUTW PCTLPRE=P_ PCTLPTS=1 to 5 by 1 PCTLPTS=5 TO 95 BY 5 PCTLPTS=95 TO 100 BY 1;
  OUTPUT OUT=WORK.OUTW PCTLPRE=P_ PCTLPTS=1 to 100 BY 1;
RUN; 

/* to identify the value for each  quantile  */
PROC TABULATE
DATA=WORK.OUTW out=idb2;
	
VAR P_1 P_2 P_3 P_4 P_5 P_6 P_7 P_8 P_9 P_10 P_11 P_12 P_13 P_14 P_15 P_16 
    P_17 P_18 P_19 P_20 P_21 P_22 P_23 P_24 P_25 P_26 P_27 P_28 P_29 P_30 
	P_31 P_32 P_33 P_34 P_35 P_36 P_37 P_38 P_39 P_40
    P_41 P_42 P_43 P_44 P_45 P_46 P_47 P_48 P_49 P_50
    P_51 P_52 P_53 P_54 P_55 P_56 P_57 P_58 P_59 P_60 
	P_61 P_62 P_63 P_64 P_65 P_66 P_67 P_68 P_69 P_70 
	P_71 P_72 P_73 P_74 P_75 P_76 P_77 P_78 P_79 P_80
    P_81 P_82 P_83 P_84 P_85 P_86 P_87 P_88 P_89 P_90
    P_91 P_92 P_93 P_94 P_95 P_96 P_97 P_98 P_98 P_99 P_100;
	CLASS COUNTRY /	ORDER=FORMATTED ;
	TABLE 
COUNTRY={LABEL=''}*
  Sum={LABEL=''},
 ALL={LABEL="&text1 BOUNDARIES FOR &&l&inc"}*
  &text2
 / BOX={LABEL="YEAR &year" } 		;
RUN;

data idb2(drop=_TYPE_  _PAGE_  _TABLE_); set  idb2;
	TIME="&yyyy";CURRENCY="&typ";IFLAG="";
run;
%if "idb" ="RPHD"  %then %do;
    data idb2(rename=(Country=GEO));set idb2;run;
%end;
  data idb2;set idb2(drop=Country);
  GEO="&Ucc";run;

  /* to rename the variables */
%if  &percentile=quintile %then %do;
	%let text11=&text1.1;
	%let text12=&text1.2;
	%let text13=&text1.3;
	%let text14=&text1.4;
	%let text15=&text1.5;
	Data idb2(rename=(P_20_SUM=&text11 P_40_SUM=&text12 P_60_SUM=&text13 P_80_SUM=&text14 P_100_SUM=&text15));
		format  GEO TIME CURRENCY IFLAG P_20_SUM P_40_SUM P_60_SUM P_80_SUM P_100_SUM;
		set idb2;
	run;
%end;
%if  &percentile=quartile %then %do;
	%let text11=&text1.1;
	%let text12=&text1.2;
	%let text13=&text1.3;
	%let text14=&text1.4;

	Data idb2(rename=(P_25_SUM=&text11 P_50_SUM=&text12 P_75_SUM=&text13 P_100_SUM=&text14));
		format GEO TIME CURRENCY IFLAG P_25_SUM P_50_SUM P_75_SUM P_100_SUM;
		set idb2;
	run;
%end;
%if  &percentile=decile %then %do;
	%let text11=&text1.1;
	%let text12=&text1.2;
	%let text13=&text1.3;
	%let text14=&text1.4;
	%let text15=&text1.5;
	%let text16=&text1.6;
	%let text17=&text1.7;
	%let text18=&text1.8;
	%let text19=&text1.9;
	%let text20=&text1.10;
	Data idb2
		(rename=(P_10_SUM=&text11 P_20_SUM=&text12 P_30_SUM=&text13 P_40_SUM=&text14 P_50_SUM=&text15 P_60_SUM=&text16 P_70_SUM=&text17 P_80_SUM=&text18 P_90_SUM=&text19 P_100_SUM=&text20));
		format GEO TIME CURRENCY IFLAG P_10_SUM P_20_SUM P_30_SUM P_40_SUM P_50_SUM P_60_SUM P_70_SUM P_80_SUM P_90_SUM P_100_SUM;
	set idb2;
	run;
%end;
%if  &percentile=percentile %then %do;
	%let text11=&text1.1;
	%let text12=&text1.2;
	%let text13=&text1.3;
	%let text14=&text1.4;
	%let text15=&text1.5;
	%let text16=&text1.6;
	%let text17=&text1.7;
	%let text18=&text1.8;
	%let text19=&text1.9;
	%let text110=&text1.10;
	%let text111=&text1.11;
	%let text112=&text1.12;
	%let text113=&text1.13;
	%let text114=&text1.14;
	%let text115=&text1.15;
	%let text116=&text1.16;
	%let text117=&text1.17;
	%let text118=&text1.18;
	%let text119=&text1.19;
	%let text120=&text1.20;
	%let text121=&text1.21;
	%let text122=&text1.22;
	%let text123=&text1.23;
	%let text124=&text1.24;
	%let text125=&text1.25;
	%let text126=&text1.26;
	%let text127=&text1.27;
	%let text128=&text1.28;
	%let text129=&text1.29;
	%let text130=&text1.30;
	%let text131=&text1.31;
	%let text132=&text1.32;
	%let text133=&text1.33;
	%let text134=&text1.34;
	%let text135=&text1.35;
	%let text136=&text1.36;
	%let text137=&text1.37;
	%let text138=&text1.38;
	%let text139=&text1.39;
	%let text139=&text1.39;
	%let text140=&text1.40;
	%let text141=&text1.41;
	%let text142=&text1.42;
	%let text143=&text1.43;
	%let text144=&text1.44;
	%let text145=&text1.45;
	%let text146=&text1.46;
	%let text147=&text1.47;
	%let text148=&text1.48;
	%let text149=&text1.49;
	%let text150=&text1.50;
	%let text151=&text1.51;
	%let text152=&text1.52;
	%let text153=&text1.53;
	%let text154=&text1.54;
	%let text155=&text1.55;
	%let text156=&text1.56;
	%let text157=&text1.57;
	%let text158=&text1.58;
	%let text159=&text1.59;
	%let text160=&text1.60;
	%let text161=&text1.61;
	%let text162=&text1.62;
	%let text163=&text1.63;
	%let text164=&text1.64;
	%let text165=&text1.65;
	%let text166=&text1.66;
	%let text167=&text1.67;
	%let text168=&text1.68;
	%let text169=&text1.69;
	%let text170=&text1.70;
	%let text171=&text1.71;
	%let text172=&text1.72;
	%let text173=&text1.73;
	%let text174=&text1.74;
	%let text175=&text1.75;
	%let text176=&text1.76;
	%let text177=&text1.77;
	%let text178=&text1.78;
	%let text179=&text1.79;
	%let text180=&text1.80;
	%let text181=&text1.81;
	%let text182=&text1.82;
	%let text183=&text1.83;
	%let text184=&text1.84;
	%let text185=&text1.85;
	%let text186=&text1.86;
	%let text187=&text1.87;
	%let text188=&text1.88;
	%let text189=&text1.89;
	%let text190=&text1.90;
	%let text191=&text1.91;
	%let text192=&text1.92;
	%let text193=&text1.93;
	%let text194=&text1.94;
	%let text195=&text1.95;
	%let text196=&text1.96;
	%let text197=&text1.97;
	%let text198=&text1.98;
	%let text199=&text1.99;
	%let text100=&text1.100;

	Data idb2
		(rename=(P_1_SUM=&text11 P_2_SUM=&text12 P_3_SUM=&text13 P_4_SUM=&text14 P_5_SUM=&text15 
		P_6_SUM=&text16 P_7_SUM=&text17 P_8_SUM=&text18  P_9_SUM=&text19 P_10_SUM=&text110
		P_11_SUM=&text111 P_12_SUM=&text112 P_13_SUM=&text113 P_14_SUM=&text114 P_15_SUM=&text115 P_16_SUM=&text116 P_17_SUM=&text117
		P_18_SUM=&text118 P_19_SUM=&text119 P_20_SUM=&text120
		P_21_SUM=&text121 P_22_SUM=&text122 P_23_SUM=&text123 P_24_SUM=&text124 P_25_SUM=&text125 P_26_SUM=&text126
		P_27_SUM=&text127 P_28_SUM=&text128 P_29_SUM=&text129 P_30_SUM=&text130
		P_31_SUM=&text131 P_32_SUM=&text132 P_33_SUM=&text133 P_34_SUM=&text134 P_35_SUM=&text135 P_36_SUM=&text136
		P_37_SUM=&text137 P_38_SUM=&text138 P_39_SUM=&text139 P_40_SUM=&text140
		P_41_SUM=&text141 P_42_SUM=&text142 P_43_SUM=&text143 P_44_SUM=&text144 P_45_SUM=&text145 P_46_SUM=&text146
		P_47_SUM=&text147 P_48_SUM=&text148 P_49_SUM=&text149 P_50_SUM=&text150
		P_51_SUM=&text151 P_52_SUM=&text152 P_53_SUM=&text153 P_54_SUM=&text154 P_55_SUM=&text155 P_56_SUM=&text156 P_57_SUM=&text157
		P_58_SUM=&text158 P_59_SUM=&text159 P_60_SUM=&text160
		P_61_SUM=&text161 P_62_SUM=&text162 P_63_SUM=&text163 P_64_SUM=&text164 P_65_SUM=&text165 P_66_SUM=&text166
		P_67_SUM=&text167 P_68_SUM=&text168 P_69_SUM=&text169 P_70_SUM=&text170
		P_71_SUM=&text171 P_72_SUM=&text172 P_73_SUM=&text173 P_74_SUM=&text174 P_75_SUM=&text175 P_76_SUM=&text176
		P_77_SUM=&text177 P_78_SUM=&text178 P_79_SUM=&text179 P_80_SUM=&text180
		P_81_SUM=&text181 P_82_SUM=&text182 P_83_SUM=&text183 P_84_SUM=&text184 P_85_SUM=&text185 P_86_SUM=&text186
		P_87_SUM=&text187 P_88_SUM=&text188 P_89_SUM=&text189 P_90_SUM=&text190
		P_91_SUM=&text191 P_92_SUM=&text192 P_93_SUM=&text193 P_94_SUM=&text194 		
		P_95_SUM=&text195 P_96_SUM=&text196 P_97_SUM=&text197 P_98_SUM=&text198 P_99_SUM=&text199 P_100_SUM=&text100));
		
		format GEO TIME CURRENCY IFLAG P_1_SUM P_2_SUM P_3_SUM P_4_SUM 
		P_5_SUM P_6_SUM P_7_SUM P_8_SUM  P_9_SUM P_10_SUM
		P_11_SUM P_12_SUM P_13_SUM P_14_SUM P_15_SUM P_16_SUM P_17_SUM P_18_SUM P_19_SUM P_20_SUM
		P_21_SUM P_22_SUM P_23_SUM P_24_SUM P_25_SUM P_26_SUM P_27_SUM P_28_SUM P_29_SUM P_30_SUM
		P_31_SUM P_32_SUM P_33_SUM P_34_SUM P_35_SUM P_36_SUM P_37_SUM P_38_SUM P_39_SUM P_40_SUM
		P_41_SUM P_42_SUM P_43_SUM P_44_SUM P_45_SUM P_46_SUM P_47_SUM P_48_SUM P_49_SUM P_50_SUM
		P_51_SUM P_52_SUM P_53_SUM P_54_SUM P_55_SUM P_56_SUM P_57_SUM P_58_SUM P_59_SUM P_60_SUM
		P_61_SUM P_62_SUM P_63_SUM P_64_SUM P_65_SUM P_66_SUM P_67_SUM P_68_SUM P_69_SUM P_70_SUM
		P_71_SUM P_72_SUM P_73_SUM P_74_SUM P_75_SUM P_76_SUM P_77_SUM P_78_SUM P_79_SUM P_80_SUM
		P_81_SUM P_82_SUM P_83_SUM P_84_SUM P_85_SUM P_86_SUM P_87_SUM P_88_SUM P_89_SUM P_90_SUM	
		P_91_SUM P_92_SUM P_93_SUM P_94_SUM	P_95_SUM P_96_SUM P_97_SUM P_98_SUM P_99_SUM P_100_SUM;
		set idb2;
	run;
	%end;
/* to associate for each observation which quantile belong to */
PROC SQL;
     CREATE TABLE WORK.idb1 AS
  	 SELECT idb.*, 
	 &text3  ,
		(CASE WHEN CALCULATED &text1 is missing THEN -1 ELSE 1 END) AS &text1._F
 	 FROM WORK.idb INNER JOIN WORK.OUTW ON idb.COUNTRY = OUTW.COUNTRY;
QUIT;
/* to  calculate  frequencies, cumulative  frequencies and weights and income */
proc sort data=idb1; by country &percentile &inc;run;
PROC MEANS data=idb1 median sumwgt qmethod=os noprint;  
	var &inc;
    by country &percentile; 
    weight &weight; 
	output out=work.mm    n=n sumwgt=totwgh sum=prod;run;
    data mm(drop=_freq_ _type_);set mm;
run;
%if (&percentile=percentile  )  %then %do;
 data mm;set mm;
	if  percentile not in ('PERCENTILE1','PERCENTILE2',
	'PERCENTILE3','PERCENTILE4','PERCENTILE5','PERCENTILE95',
	'PERCENTILE96','PERCENTILE97','PERCENTILE98','PERCENTILE99','PERCENTILE100')
	then delete;
 run;
%end;
/* rename last percentile and quintile 100 in 999 and 10 in 99 */
%if  (&percentile=percentile or  &percentile=decile)  %then %do;
	%if ( &percentile=percentile ) %then %do;
	proc sql;
	 create table perc_100 as select *,
 	(case when percentile ="PERCENTILE100"  then "PERCENTILE999"
	    else percentile
			end) as perc100
			from mm;
	quit;
	
	%end;
	%if (  &percentile=decile ) %then %do;
	proc sql;
 	create table perc_100 as select *,
 	(case when &percentile ="DECILE10"  then "DECILE99"
	    else &percentile
			end) as perc100
			from mm;
	quit;
	%end;
	data mm(rename =(perc100=&percentile));set perc_100(drop=&percentile);run;
%end;

proc sort data=mm; by country &percentile ;run;
data idb3(drop=prod); 
	set mm;
	by country &percentile;
	retain ntot;
	retain cumulative_Totwgh;
	retain cumulative_area;
	current_area=prod;
	ntot=n;
	if first.country then cumulative_area=prod;  
 		else  cumulative_area=cumulative_area+prod;
	
run;
/* restore the  last percentile and quintile  999 in 100 and 99 in 10  */
%if ( &percentile=percentile or &percentile=decile ) %then %do;
    %if ( &percentile=percentile ) %then %do;
	proc sql;
	create table perc_100x as select *,
 	(case when percentile ="PERCENTILE999"  then "PERCENTILE100"
		else percentile
			end) as perc100
			from idb3;
	quit;
	%end;
	%if (  &percentile=decile ) %then %do;
	proc sql;
	create table perc_100x as select *,
 	(case when &percentile ="DECILE99"  then "DECILE10"
		else &percentile
			end) as perc100
			from idb3;
	quit;
	%end;
data idb3(rename =(perc100=&percentile));set perc_100x(drop=&percentile);run;
%end;

/* to keep the total INCOME value by country and merge*/
PROC MEANS data=idb1 median sumwgt qmethod=os noprint;  
	var &inc;
    by country ; 
    weight RB050a; 
	output out=work.pp     sum=totvalue;
run;

data pp(drop=_freq_ _type_);set pp;run;
	data idb3; merge idb3 pp; by country;
run;
/* formatting GEO variable */
data  Perc_Data; 
length  GEO $5;
format GEO $5.0;
set   idb2; run;

 %if ( &percentile=percentile  ) %then %do;
 data Perc_Data(keep=GEO &percent.1 &percent.2 &percent.3 &percent.4 &percent.5 &percent.95 
 &percent.96 &percent.97 &percent.98 &percent.99 &percent.100 time currency iflag) ;
 set Perc_Data;

run;

%end;

data  Tot_Country (rename=(country=geo) rename=(&percent=quantile)); 
length  country $5;
format country  $5.0;
set  idb3; run;

proc sort data=Perc_Data; by geo time CURRENCY iflag;run;
/* traspose the  QUANTILE VALUE dataset   */ 
%if &percent=decile %then %do;
proc transpose data=Perc_Data
     out=T_Perc_Data(rename=(col1=ivalue) rename=(_name_=quantile)); 
     var &percent.1 &percent.2 &percent.3 &percent.4 &percent.5 &percent.6 &percent.7 &percent.8 &percent.9 &percent.10; 
     by geo time CURRENCY iflag;
run;
%end;
%if &percent=quintile %then %do;
proc transpose data=Perc_Data
     out=T_Perc_Data(rename=(col1=ivalue) rename=(_name_=quantile)); 
     var &percent.1 &percent.2 &percent.3 &percent.4 &percent.5; 
     by geo time CURRENCY iflag;
run;
%end;
%if &percent=quartile %then %do;
proc transpose data=Perc_Data
     out=T_Perc_Data(rename=(col1=ivalue) rename=(_name_=quantile)); 
     var &percent.1 &percent.2 &percent.3 &percent.4; 
     by geo time CURRENCY iflag;
run;
%end;
%if &percent=percentile %then %do;
proc transpose data=Perc_Data
     out=T_Perc_Data(rename=(col1=ivalue) rename=(_name_=quantile)); 
     var &percent.1 &percent.2 &percent.3 &percent.4 &percent.5 &percent.95 &percent.96 &percent.97 &percent.98 &percent.99 &percent.100; 
     by geo time CURRENCY iflag;
run;
%end;
/* merge values quantile with cumulative values */
proc sort data=Tot_Country  ; by geo quantile;run;

proc sql; create table quantile_&typ as 
select a.*,b.time,b.CURRENCY, b.iflag, b.ivalue

from Tot_Country as a,
       T_Perc_Data as b 
   where a.geo =b.geo and a.quantile = b.quantile;
quit;

/* define quantile variable lenght  */
data quantile_&typ;
length  quantile  $13;
format quantile   $13.0;
set quantile_&typ;
indic_il="TC   ";
run;

/* calculate SHARE values  */
data share_&typ;set quantile_&typ(drop=ivalue);
if totvalue not in ('.') then 
ivalue=current_area/totvalue*100;
indic_il="SHARE";
run;
data quantile_&typ(drop=current_area totvalue);set quantile_&typ share_&typ;run;

/* formatting quantile_typ dataset  */
data quantile_&typ ;
format geo time indic_il CURRENCY quantile ivalue iflag unrel n ntot totwgh  cumulative_area lastup lastuser; 
				set quantile_&typ; run;
/* to calculate the  value for quantile='TOTAL '  */
%if &percent=percentile %then %do;
data t_total;set quantile_&typ ;
if quantile not in ('PERCENTILE100') then delete;run;
data t_total;set t_total;quantile='TOTAL      ';run;
data quantile_&typ ;set quantile_&typ t_total;run;
%end;

data quantile_&typ ;set quantile_&typ;
if quantile in ('PERCENTILE100','DECILE10','QUARTILE4','QUINTILE5','TOTAL')  and ivalue=. then delete;
run;


/* append calculated  values to work.DI01 datasets */

%if %sysfunc(exist(work.quantile_&typ)) %then %do;
	PROC SQL;
		 INSERT INTO &tab SELECT 
			"&Ucc" as geo,
			&yyyy as time,
			quantile_&typ..indic_il as indic_il,
			quantile_&typ..CURRENCY as CURRENCY,
			quantile_&typ..quantile as quantile,
			quantile_&typ..ivalue as ivalue,
			old_flag.iflag as iflag, 
			(case when ntot < 20 then 2
				when ntot < 50 then 1
						  else 0
					      end) as unrel,
	       	quantile_&typ..n as n,
			quantile_&typ..ntot as ntot,
			quantile_&typ..totwgh as totwgh,
			"&sysdate" as lastup,
			"&sysuserid" as	lastuser 
			FROM quantile_&typ 						    
				LEFT JOIN work.old_flag ON ("&Ucc" = old_flag.geo) 
					 AND (quantile_&typ..indic_il = old_flag.indic_il)  AND (quantile_&typ..quantile = old_flag.quantile) 
					group by  quantile_&typ..geo, "&percent" ;
			QUIT;
%end;
					
data &tab; set &tab;
if quantile in ('DECILE10','QUARTILE4','QUINTILE5','PERCENTILE100','TOTAL') and indic_il in ('TC') then delete; 
if quantile in ('TOTAL') and indic_il in ('SHARE') then delete; 
run;
%mend Percentile;

%macro Calc_Eur;
	PROC SQL;
				Create table work.rdb as 
				select time, geo,indic_il,CURRENCY,quantile, ivalue, n,ntot, totwgh, 
					(ivalue * totwgh) as wval
				from rdb.di01
				where time = &yyyy and geo in &Uccs and CURRENCY="EUR";
			quit;
	
			proc sql;
			create table work.di01 as select distinct
			"&Ucc" as geo,
			&yyyy as time,
			rdb.indic_il as indic_il, 
			rdb.CURRENCY as CURRENCY,
			rdb.quantile as quantile,
			(sum(wval) / sum(totwgh)) as ivalue,
			old_flag.iflag as iflag, 
			(case when sum(ntot)  < 20 then 2
				when sum(ntot)  < 50 then 1
						  else 0
					      end) as unrel,
			sum(ntot) as n,
			sum(ntot) as ntot,
			sum(totwgh) as totwgh,
			"&sysdate" as lastup,
			"&sysuserid" as	lastuser 
			from work.rdb
			LEFT JOIN work.old_flag ON ("&Ucc" = old_flag.geo) 
					 AND (rdb.indic_il = old_flag.indic_il)  AND (rdb.quantile = old_flag.quantile) 
			group by rdb.indic_il, rdb.currency,rdb.quantile;
			quit;
	

%mend Calc_Eur;

%let listper= decile  quartile quintile  percentile;
%let i=1; 
%let percent=%scan(&listper,&i,%str( )); 
%do  %while(&percent ne ); 
 		%if &EU=1 %then %do;
		    		%Calc_Eur;
		%end;
		%else %do;
			%Percentile (EUR,EQ_INC20eur,&yyyy, RB050a, &Ucc, &percent); 
			%Percentile (PPS,EQ_INC20ppp,&yyyy, RB050a, &Ucc, &percent); 
		    %Percentile (NAC,EQ_INC20,&yyyy, RB050a, &Ucc, &percent); 
    	%end;
	%let i=%eval(&i+1);                                  
	%let percent=%scan(&listper,&i,%str( ));  
%end;  
	
* Update RDB;  
 
DATA  rdb.&tab;
set rdb.&tab (where=(not(time = &yyyy and geo = "&Ucc")))
    work.&tab; 
run;  
PROC SQL;  
     Insert into log.log
     set date = "&sysdate"d, time = "&systime"t, user = "&sysuserid",
		 report = "* &Ucc - &yyyy * DI01 (re)calculated *";		  
QUIT;
 
%end;
%else %do; 
PROC SQL;  
     Insert into log.log
     set date = "&sysdate"d, time = "&systime"t, user = "&sysuserid",
		 report = "* &Ucc - &yyyy * NO DATA !";		  
QUIT;
%end;

%mend UPD_DI01;
