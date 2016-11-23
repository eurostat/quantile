*** low work intensity   by NUTS1 NUTS2 and COUNTRIES ***;
/****************************************************************************/
/*  Created on 28/03/2011                                                   */
/*                                                                          */
/*  change  listnut=DB020 NUTS1 NUTS2    to setting the NUT                 */
/*  update on MG17102013 -  PL condition                                    */
/*                                                                          */
/****************************************************************************/
%macro UPD_lvhl21(yyyy,Ucc,Uccs,flag,notBDB);
/* 20111129BB filtering of people keep only age<60*/
%global nat;
%let tab=lvhl21;
%let cc=%lowcase(&Ucc);
%let yy=%substr(&yyyy,3,2);
%let EU=0;

%if &Uccs=0 %then %let Uccs=("&Ucc");
%else %let EU=1;
 
proc datasets lib=work kill nolist;
run;
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
	PROC SQL noprint;
Create table work.bdb as 
	select distinct HB010, HB020, HB030,
	substr(BDB_D.DB040,1,3) AS NUTS1,
 	(case when BDB_D.DB040 in ('FI19' , 'FI20') then 'FI19_20' else BDB_D.DB040 end) AS NUTS2 
	from in.&infil.h as BDB 
	inner join in.&infil.d as BDB_d on (BDB.HB010 = BDB_D.DB010 and BDB.HB020 = BDB_D.DB020 and BDB.HB030 = BDB_D.DB030)
	where HB020 in &Uccs;

Create table work.idb as 
	select distinct DB010, DB020, RB030, RB050a, Age, RB090, NUTS1, NUTS2, LWI
	from idb.IDB&yy as IDB
	left join work.bdb as BDB on (IDB.DB020 = BDB.HB020 and IDB.DB030 = BDB.HB030)
	where DB020 in &Uccs and Age <60

;
quit;

/*  all macros used for the process */
%macro lvhl211(nut);
/* main macro creates the input datasets and call the other macros */

proc sql;
Select distinct count(&nut) as N 
	into :nobs
	from  work.idb;
Create table work.lvhl21 like rdb.lvhl21; 
QUIT;
**** MISSINGS *;
%if &nut=NUTS1 or &nut=NUTS2 %then %do;
Proc sql;
CREATE TABLE nfilled AS SELECT DISTINCT DB020, (N(RB030)) AS N1 FROM work.idb WHERE "&nut" not is missing GROUP BY DB020;
CREATE TABLE nmissing AS SELECT DISTINCT DB020, (N(RB030)) AS N_1 FROM work.idb WHERE "&nut" is missing GROUP BY DB020;
CREATE TABLE m&NUT AS SELECT nfilled.DB020, (100/(N1+N_1)*N_1) AS m&NUT FROM nfilled LEFT JOIN nmissing ON (nfilled.DB020 = nmissing.DB020);

CREATE TABLE nfilled AS SELECT DISTINCT DB020, (N(RB030)) AS N1 FROM work.idb WHERE LWI not is missing GROUP BY DB020;
CREATE TABLE nmissing AS SELECT DISTINCT DB020, (N(RB030)) AS N_1 FROM work.idb WHERE LWI is missing GROUP BY DB020;
CREATE TABLE mLWI AS SELECT nfilled.DB020, (100/(N1+N_1)*N_1) AS mLWI FROM nfilled LEFT JOIN nmissing ON (nfilled.DB020 = nmissing.DB020);

CREATE TABLE missunrel AS SELECT m&NUT..DB020, 
	max(m&NUT, mLWI) AS pcmiss
	FROM m&NUT LEFT JOIN mLWI ON (m&NUT..DB020 = mLWI.DB020);
quit;

%end;
/* for countries */
%if &nut=DB020  %then %do; 

**** MISSINGS *;
Proc sql;

CREATE TABLE nfilled AS SELECT DISTINCT DB020, (N(RB030)) AS N1 FROM work.idb WHERE LWI not is missing GROUP BY DB020;
CREATE TABLE nmissing AS SELECT DISTINCT DB020, (N(RB030)) AS N_1 FROM work.idb WHERE LWI is missing GROUP BY DB020;
CREATE TABLE mLWI AS SELECT nfilled.DB020, (100/(N1+N_1)*N_1) AS mLWI FROM nfilled LEFT JOIN nmissing ON (nfilled.DB020 = nmissing.DB020);

CREATE TABLE missunrel AS SELECT mLWI.DB020, 
	 mLWI AS pcmiss
	FROM mLWI ;
quit;
%end;
/* macro to check if there are enought NUT1s for processing */
%let nobs2=2;
%if &nut=NUTS1 %then %do;
proc sql; create table TestNut1 as select distinct NUTS1 from work.bdb;
select distinct count(NUTS1) as M 
	into :nobs2 
	from  TestNut1;quit;
%end;

%if &nobs > 0 and &nobs2>1 
%then %do;
 %if &nut=DB020 %then %let GeoLen =length(geo)=2;
 %if &nut=NUTS1 %then %let GeoLen= length(geo)=3;
 %if &nut=NUTS2 %then %let GeoLen= length(geo)>3;

proc sql;
CREATE TABLE work.old_flag AS
SELECT distinct
      time,
      geo,
	  unit,
	  iflag
	  FROM rdb.&tab
WHERE  time = &yyyy and substr(geo,1, 2)= "&Ucc" and &GeoLen 
group by time, geo ;

QUIT;
PROC TABULATE data=work.idb out=Ti;
	CLASS &nut;
	CLASS LWI;
	CLASS DB020;
	VAR RB050a;
	TABLE DB020 * &nut, LWI * RB050a * (RowPctSum N Sum) /printmiss;
RUN;
%if &nut =DB020 %then %let ival =RB050a_PctSum_10 ;
	%else 	%let ival =RB050a_PctSum_101 ;
* fill RDB variables;
PROC SQL;
CREATE TABLE work.lvhl21 AS
SELECT 
	Ti.&nut as geo FORMAT=$7. LENGTH=7,
	&yyyy as time,
	"PC_Y_LT60" as unit,
	ti.LWI,
	Ti.&ival as ivalue,
	old_flag.iflag as iflag FORMAT=$3. LENGTH=3,
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
LEFT JOIN work.old_flag ON (Ti.&nut = old_flag.geo) AND (Ti.LWI=1) 
	and ("PC_Y_LT60"=old_flag.unit) 
	
GROUP BY  ti.&NUT
ORDER BY  Ti.&NUT;
QUIT;

/***  UPDATE RDB ***/
%if &nut=NUTS1 %then %do;
	DATA  rdb.lvhl21(drop=LWI) ;
					set rdb.lvhl21(where=(not(time = &yyyy and  substr(geo,1, 2)= "&Ucc" and length(geo)=3 )))
    				work.lvhl21; 
					WHERE LWI=1 ;
					run;  
	%end;	
%if &nut=NUTS2 %then %do;	
 %if (&yyyy =2007 or &yyyy =2008) and &Ucc=RO  %then %do;
    data work.lvhl21;  set work.lvhl21; 
		if geo="RO01" then geo="RO21";
		if geo="RO02" then geo="RO22";
		if geo="RO03" then geo="RO31";
		if geo="RO04" then geo="RO41";
		if geo="RO05" then geo="RO42";
		if geo="RO06" then geo="RO11";
		if geo="RO07" then geo="RO12";
		if geo="RO08" then geo="RO32";
	run;
	 %end;
	DATA  rdb.lvhl21 (drop=LWI) ;;
					set rdb.lvhl21(where=(not(time = &yyyy and substr(geo,1, 2)= "&Ucc" and length(geo)>3  )))
    				work.lvhl21; 
					WHERE LWI=1 ;
					run;  
%end; 
%if &nut=DB020  %then %do;
DATA  rdb.lvhl21 (drop=LWI) ;;
					set rdb.lvhl21(where=(not(time = &yyyy and  geo = "&Ucc" and length(geo)=2  )))
    				work.lvhl21; 
					WHERE LWI=1 ;
					run;  
%end; 
PROC SQL;  
     Insert into log.log
     set date = "&sysdate"d, time = "&systime"t, user = "&sysuserid",
		 report = "* &nut - &Ucc - &yyyy * lvhl21 (re)calculated *";		  
QUIT;
%end;
%else %do; 
PROC SQL;  
     Insert into log.log
     set date = "&sysdate"d, time = "&systime"t, user = "&sysuserid",
		 report = "* &nut - &Ucc - &yyyy * lvhl21 NO DATA !";		  
QUIT;
%end;

%mend lvhl211;

%if &EU=0 %then %do;
********************;
**  FORMATS;
PROC FORMAT;
VALUE f_age (multilabel)
		0 - 17 = "Y0_17"
		18 - 64 = "Y18_64"
		65 - HIGH = "Y_GE65"
		0 - HIGH = "TOTAL";

VALUE f_sex (multilabel)
		1 = "M"
		2 = "F"
		1 - 2 = "T";

RUN;

* extract from BDB and then IDB;
%let listnut= DB020 NUTS1 NUTS2  ;  
%let i=1; 
%let nut=%scan(&listnut,&i,%str( )); 
  %do  %while(&nut ne ); 
	%if &nut=DB020 %then %lvhl211(&nut); 

	%if (&nut=NUTS1 or &nut=NUTS2) %then %do;
     	%if &yyyy > 2007 and (&Ucc=CZ or &Ucc=DK  or &Ucc=IE or &Ucc=ES or &Ucc=IT or
		&Ucc=SK or &Ucc=FI  or &Ucc =SE or  &Ucc =BG or &Ucc  =SI or &Ucc  =RO )  %then %lvhl211(&nut) ;
	 	%if &yyyy < 2008
		and  (&Ucc=CZ  or &Ucc=IE or &Ucc=ES or &Ucc=IT or
		&Ucc=SK or &Ucc=FI ) %then %lvhl211(&nut) ;
		%if &yyyy =2007 and  (&Ucc= RO or &Ucc= =DK) %then %lvhl211(&nut) ;
		%if &yyyy >2004 and &Ucc=NO and &nut=NUTS1 %then %lvhl211(&nut) ;
		%if  &Ucc=NO and &nut=NUTS2 and  &yyyy ne 2004 %then %lvhl211(&nut) ;
		%if  &Ucc=CH and &nut=NUTS2 and  &yyyy > 2007 %then %lvhl211(&nut) ;
	%end;
    
	%if &nut=NUTS1 and  &Ucc=PL and  &yyyy > 2011 %then %lvhl211(&nut) ;
	%if &nut=NUTS1 and  (&Ucc=HU or &Ucc=EL /*or &Ucc=BE*/ ) %then %lvhl211(&nut) ;
	%if &nut=NUTS1 and  &Ucc=NL and &yyyy > 2010 %then %lvhl211(&nut) ;
	/*%if &nut=NUTS2 and  &Ucc=AT  and &yyyy > 2007 and &yyyy < 2013 %then %lvhl211(&nut) ;*/
	%let i=%eval(&i+1);                                  
	%let nut=%scan(&listnut,&i,%str( )); 
  %end;  

%end;

%mend UPD_lvhl21;
