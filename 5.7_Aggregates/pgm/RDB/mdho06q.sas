%macro UPD_mdho06q(yyyy,Ucc,Uccs,flag,notBDB);
/*severe housing deprivation by quantile */
PROC DATASETS lib=work kill nolist;
QUIT;

%let cc=%lowcase(&Ucc);
%let yy=%substr(&yyyy,3,2);
%let EU=0;
%let tab=mdho06q;
%if &Uccs=0 %then %let Uccs=("&Ucc");
%else %let EU=1;

* input datasets;
/*
%if &notBDB %then %do;
	libname in "&eusilc/&cc/c&yy"; 
	%let infil=c&cc&yy;
	%end;
%else %do;
	libname in "&eusilc/BDB"; 
	%let infil=BDB_c&yy;
	%end;
 */
%let not60=0;

PROC FORMAT;

VALUE f_QUANTILE (multilabel)
		1 = "QUINTILE1"
		2 = "QUINTILE2"
		3 = "QUINTILE3"
		4 = "QUINTILE4"
		5 = "QUINTILE5"
		1-5="TOTAL  ";
RUN;

*calculate SEVERE_HH_DEP (severe housing deprivation);
PROC SQL;
 CREATE TABLE work.idb AS SELECT DISTINCT IDB.DB010,IDB.DB020, IDB.DB030, IDB.RB030, IDB.RB050a, IDB.QITILE, BDBd.DB100, IDB.OVERCROWDED,
	 BDBh.HH040,
	 (CASE WHEN BDBh.HH040=1 THEN 1 WHEN BDBh.HH040=2 THEN 0 ELSE BDBh.HH040 END) AS LEAKING_ROOF,
	
	%if &yyyy<2008 %then %do;
		BDBh.HH080,
		BDBh.HH080_F,
		BDBh.HH090,
		BDBh.HH090_F,
		(CASE WHEN BDBh.HH080= 2 THEN 1 WHEN BDBh.HH080= 1 THEN 0 ELSE BDBh.HH080 END) AS LACK_BATH_SHOWER,
		(CASE WHEN BDBh.HH090= 2 THEN 1 WHEN BDBh.HH090= 1 THEN 0 ELSE BDBh.HH090 END) AS LACK_TOILET,
	%end;
	%if &yyyy>2007 and &yyyy<2011 %THEN %DO;
		BDBh.HH081,
		BDBh.HH081_F,
		(CASE WHEN (BDBh.HH081_F=1 AND BDBh.HH081= 3) THEN 1 WHEN (BDBh.HH081_F=-5 AND BDBh.HH080= 2) THEN 1 
			WHEN (BDBh.HH081_F=1 AND BDBh.HH081 in (1,2)) THEN 0 WHEN (BDBh.HH081_F=-5 AND BDBh.HH080=1) THEN 0 
		ELSE . END) AS LACK_BATH_SHOWER,
	 	BDBh.HH091,
	 	BDBh.HH091_F,
	 	(CASE WHEN (BDBh.HH091_F=1 AND BDBh.HH091= 3) THEN 1 WHEN (BDBh.HH091_F=-5 AND BDBh.HH090= 2) THEN 1 
			WHEN (BDBh.HH091_F=1 AND BDBh.HH091 in (1,2)) THEN 0 WHEN (BDBh.HH091_F=-5 AND BDBh.HH090=1) THEN 0 
		ELSE . END) AS LACK_TOILET,
	 %END;
	 %if &yyyy>2010 %then %do;
		BDBh.HH081,
		BDBh.HH081_F,
		(CASE WHEN BDBh.HH081= 3 THEN 1 
			WHEN BDBh.HH081 in (1,2) THEN 0
		ELSE . END) AS LACK_BATH_SHOWER,
	 	BDBh.HH091,
	 	BDBh.HH091_F,
	 	(CASE WHEN BDBh.HH091= 3 THEN 1 
			WHEN BDBh.HH091 in (1,2) THEN 0 
		ELSE . END) AS LACK_TOILET,
	 %END;

	(CASE  WHEN CALCULATED LACK_BATH_SHOWER =1 AND CALCULATED LACK_TOILET = 1 THEN 1
		  WHEN (CALCULATED LACK_BATH_SHOWER is missing OR CALCULATED LACK_TOILET is missing ) THEN . ELSE 0 END ) AS LACK_BST,

	BDBh.HS160,
	BDBh.HS160_F,
	 (CASE WHEN BDBh.HS160=1 THEN 1 WHEN BDBh.HS160=2 THEN 0 ELSE . END) AS TOO_DARK,

	 (CASE  WHEN IDB.OVERCROWDED =1 AND(CALCULATED LEAKING_ROOF = 1 OR CALCULATED LACK_BST = 1 OR CALCULATED TOO_DARK = 1)THEN 1
			WHEN (IDB.OVERCROWDED is missing /*OR CALCULATED LEAKING_ROOF is missing OR CALCULATED LACK_BST is missing OR CALCULATED TOO_DARK is missing*/) THEN . 
			ELSE 0 END ) AS SEVERE_HH_DEP
 
 FROM IDB.IDB&yy AS IDB
	left join in.&infil.d as BDBd on (IDB.DB020 = BDBd.DB020 and IDB.DB030 = BDBd.DB030)
	left join in.&infil.h as BDBh on (IDB.DB020 = BDBh.HB020 and IDB.DB030 = BDBh.HB030)
	where BDBd.DB100 in(1,2,3) AND IDB.DB020 in &Uccs;
QUIT;
proc sql;
Select distinct count(DB010) as N 
	into :nobs
	from  work.idb;

QUIT;

%if &nobs > 0
%then %do;

%if &EU=0 %then %do;

* calculate % missing values;
PROC SQL noprint;
CREATE TABLE nfilled AS SELECT DISTINCT DB020, (N(RB030)) AS N1 FROM work.idb WHERE SEVERE_HH_DEP not is missing GROUP BY DB020;
CREATE TABLE nmissing AS SELECT DISTINCT DB020, (N(RB030)) AS N_1 FROM work.idb WHERE SEVERE_HH_DEP is missing GROUP BY DB020;
CREATE TABLE mSEVERE_HH_DEP AS SELECT nfilled.DB020, (100/(N1+N_1)*N_1) AS mSEVERE_HH_DEP FROM nfilled LEFT JOIN nmissing ON (nfilled.DB020 = nmissing.DB020);

CREATE TABLE missunrel AS SELECT mSEVERE_HH_DEP.DB020, 
				max(mSEVERE_HH_DEP,0) AS pcmiss
	FROM mSEVERE_HH_DEP;
QUIT;

* Severe housing deprivation rate by household type 
* calc values, N and total weights;

PROC TABULATE data=work.idb out=Ti;
		FORMAT qitile f_quantile.;
		CLASS qitile /MLF;	
		CLASS SEVERE_HH_DEP;
		CLASS DB020;
		CLASS DB010;
	VAR RB050a;
	TABLE DB010 * DB020 * qitile, SEVERE_HH_DEP* RB050a * (RowPctSum N Sum) /printmiss;
RUN;

* fill RDB variables;
PROC SQL;
CREATE TABLE work.old_flag AS
SELECT 
      time,
      geo,
	  quantile,
   	  iflag
FROM rdb.&tab
WHERE  time = &yyyy ;
CREATE TABLE work.&tab AS
SELECT 
	Ti.DB020 as geo FORMAT=$5. LENGTH=5,
	Ti.DB010 as time,
	Ti.qitile as quantile,
	"PC_POP" as unit,
	ti.SEVERE_HH_DEP,
	Ti.RB050a_PctSum_1011 as ivalue,
	old_flag.iflag as iflag,
	(case when sum(Ti.RB050a_N) < 20 or missunrel.pcmiss > 50 then 2
		  when sum(Ti.RB050a_N) < 50 or missunrel.pcmiss > 20 then 1
		  else 0
	      end) as unrel,
	Ti.RB050a_N as n,
	sum(Ti.RB050a_N) as ntot,
	sum(Ti.RB050a_Sum) as totwgh,
	"&sysdate" as lastup,
	"&sysuserid" as	lastuser 
	
	
FROM Ti LEFT JOIN missunrel ON (Ti.DB020 = missunrel.DB020)
		LEFT JOIN work.old_flag ON (Ti.DB020 = old_flag.geo) 
		AND (Ti.qitile= old_flag.quantile) 
GROUP BY Ti.DB020, Ti.qitile;
	QUIT;

* Update RDB;
DATA  rdb.&tab(drop=SEVERE_HH_DEP);
set rdb.&tab(where=(not(time = &yyyy and geo in &Uccs)))
    work.&tab(where=(SEVERE_HH_DEP = 1 )); 
RUN;


%end;
* EU aggregates;
	%if &EU %then %do;
	%let tab=mdho06q;
	%let grpdim=quantile, unit;
	%EUVALS(&Ucc,&Uccs);
	%end;
	%if &euok = 0 and &EU %then %do;
		PROC SQL;  
		Insert into log.log
		set date = "&sysdate"d, time = "&systime"t, user = "&sysuserid",
			report = "* &Ucc - &yyyy * NO enought countries available! ";		  
		QUIT;
		%end;
		%else %do;
		PROC SQL;  
		Insert into log.log
		set date = "&sysdate"d, time = "&systime"t, user = "&sysuserid",
			report = "* &Ucc - &yyyy * mdho06q (re)calculated *";		  
		QUIT;
	%end;
%end;
%else %do; 
PROC SQL;  
     Insert into log.log
     set date = "&sysdate"d, time = "&systime"t, user = "&sysuserid",
		 report = "* &Ucc - &yyyy * NO DATA !";		  
QUIT;
%end;

%mend UPD_mdho06q;
