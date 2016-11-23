*** Risk at poverty by NUTS1 NUTS2 and COUNTRIES ***;
/****************************************************************************/
/*  Created on 18/03/2011                                                   */
/*                                                                          */
/*  change  listnut=DB020 NUTS1 NUTS2    to setting the NUT                 */
/*  update on MG17102013 -  PL condition                                    */
/****************************************************************************/
%macro UPD_li41(yyyy,Ucc,Uccs,flag,notBDB) /store;

%global nat;
%let tab=LI41;
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
%let not60=0;

/*  all macros used for the process */
%macro UPD_LI411(nut);
/* main macro creates the input datasets and call the other macros */
%if &nut =NUTS1  %then %do;
PROC SQL noprint;
    Create table work.bdb as 
	select distinct DB010, DB020, DB030,
	substr(BDB_D.DB040,1,3) AS NUTS1, length(DB040) as lDB100,
 	BDB_D.DB040 AS NUTS2
	from in.&infil.d  as BDB_D
	where DB020 in &Uccs 
	having lDB100 ge 4;
quit;

%end;
%if &nut =NUTS2 %then %do;
PROC SQL noprint;
  Create table work.bdb as 
	select distinct DB010, DB020, DB030,
	substr(BDB_D.DB040,1,3) AS NUTS1, length(DB040) as lDB100,
 	(case when BDB_D.DB040 in ('FI19' , 'FI20') then 'FI19_20' else BDB_D.DB040 end) AS NUTS2
	from in.&infil.d  as BDB_D
	where DB020 in &Uccs 
	having lDB100 ge 4;
quit; 

%end;
%if  &nut =NUTS2  or  &nut =NUTS1  %then %do;
Proc sql;
  Create table work.idb as 
	select distinct IDB.DB010, IDB.DB020, RB030, RB050a, ARPT60i, NUTS1, NUTS2
	from idb.IDB&yy as IDB
	left join work.bdb as BDB on (IDB.DB020 = BDB.DB020 and IDB.DB030 = BDB.DB030)
	where IDB.DB020 in &Uccs
;

Select distinct count(&nut) as N 
	into :nobs
	from  work.idb;
Create table work.LI41 like rdb.LI41; 
QUIT;
**** MISSINGS *;
Proc sql;
CREATE TABLE nfilled AS SELECT DISTINCT DB020, (N(RB030)) AS N1 FROM work.idb WHERE "&nut" not is missing GROUP BY DB020;
CREATE TABLE nmissing AS SELECT DISTINCT DB020, (N(RB030)) AS N_1 FROM work.idb WHERE "&nut" is missing GROUP BY DB020;
CREATE TABLE m&NUT AS SELECT nfilled.DB020, (100/(N1+N_1)*N_1) AS m&NUT FROM nfilled LEFT JOIN nmissing ON (nfilled.DB020 = nmissing.DB020);

CREATE TABLE nfilled AS SELECT DISTINCT DB020, (N(RB030)) AS N1 FROM work.idb WHERE arpt60i not is missing GROUP BY DB020;
CREATE TABLE nmissing AS SELECT DISTINCT DB020, (N(RB030)) AS N_1 FROM work.idb WHERE arpt60i is missing GROUP BY DB020;
CREATE TABLE marpt60i AS SELECT nfilled.DB020, (100/(N1+N_1)*N_1) AS marpt60i FROM nfilled LEFT JOIN nmissing ON (nfilled.DB020 = nmissing.DB020);

CREATE TABLE missunrel AS SELECT m&NUT..DB020, 
	max(m&NUT, mARPT60i) AS pcmiss
	FROM m&NUT LEFT JOIN mARPT60i ON (m&NUT..DB020 = mARPT60i.DB020);
quit;

%end;
/* for countries */
%if &nut=DB020  %then %do; 
Proc sql;
  Create table work.idb as 
	select distinct IDB.DB010, IDB.DB020, RB030, RB050a, ARPT60i
	from idb.IDB&yy as IDB
	where IDB.DB020 in &Uccs
;
 
Select distinct count(DB020) as N 
	into :nobs
	from  work.idb;
Create table work.LI41 like rdb.LI41; 
QUIT;
**** MISSINGS *;
Proc sql;

CREATE TABLE nfilled AS SELECT DISTINCT DB020, (N(RB030)) AS N1 FROM work.idb WHERE arpt60i not is missing GROUP BY DB020;
CREATE TABLE nmissing AS SELECT DISTINCT DB020, (N(RB030)) AS N_1 FROM work.idb WHERE arpt60i is missing GROUP BY DB020;
CREATE TABLE marpt60i AS SELECT nfilled.DB020, (100/(N1+N_1)*N_1) AS marpt60i FROM nfilled LEFT JOIN nmissing ON (nfilled.DB020 = nmissing.DB020);

CREATE TABLE missunrel AS SELECT marpt60i.DB020, 
	 mARPT60i AS pcmiss
	FROM mARPT60i ;
quit;
%end;

/* to test if there are enought NUTS1: nobs2=1  not NUTS1 enought */
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
	 /* arpt60i,*/
	  unit,
	  iflag
	  FROM rdb.&tab
WHERE  time = &yyyy and substr(geo,1, 2)= "&Ucc" and &GeoLen 
group by time, geo /*,arpt60i*/;

QUIT;

PROC TABULATE data=work.idb out=Ti;
	FORMAT ARPT60i f_incgrp.;	
	CLASS &NUT /MLF;
	CLASS ARPT60i;
	CLASS DB020;
	VAR RB050a;
	TABLE DB020 * &NUT, ARPT60i * RB050a * (RowPctSum N Sum) /printmiss;
RUN;

*%by_unit(THS_PER,RB050a_Sum/1000);
	%if &nut =DB020 %then %by_unit(PC_POP,RB050a_PctSum_10);
	%else 	%by_unit(PC_POP,RB050a_PctSum_101);

	%end;
%else %do; 
PROC SQL;  
     Insert into log.log
     set date = "&sysdate"d, time = "&systime"t, user = "&sysuserid",
		 report = "* &nut - &Ucc- &yyyy * LI41 NO DATA !";		  
QUIT;
%end;	
	

%mend UPD_LI411;


* fill RDB variables;
%macro by_unit(unit,ival); 
/* macro to calculate the work indicator and also does the  update bu NUTs */

PROC SQL;
CREATE TABLE work.LI41 AS
SELECT 
  	Ti.&NUT as geo FORMAT=$7. LENGTH=7,
	&yyyy as time,
	ti.ARPT60i,
	"&unit" as unit FORMAT=$9.,
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
LEFT JOIN work.old_flag ON (Ti.&nut = old_flag.geo) /*AND (Ti.ARPT60i = old_flag.ARPT60i) */
	and ("&unit"=old_flag.unit) 
	
GROUP BY  ti.&NUT
ORDER BY  Ti.&NUT;

QUIT;
/*data work.LI41; set work.LI41; if geo in ('BE1')  then iflag='u'; run;*/
/***  UPDATE RDB ***/
 
%if &nut=NUTS1 %then %do;
	DATA  rdb.LI41 (drop=ARPT60i); ;
					set rdb.LI41(where=(not(time = &yyyy and  substr(geo,1, 2)= "&Ucc" and length(geo)=3 and unit="&unit")))
    			    work.LI41(WHERE=( ARPT60i=1 ));
					run;  
	%end;	
%if &nut=NUTS2 %then %do;
   %if (&yyyy =2007 or &yyyy =2008) and &Ucc=RO  %then %do;
    data work.LI41;  set work.LI41;  
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

 
	DATA  rdb.LI41 (drop=ARPT60i); ;
					set rdb.LI41(where=(not(time = &yyyy and substr(geo,1, 2)= "&Ucc" and length(geo)>3  and unit="&unit")))
    				work.LI41(WHERE=( ARPT60i=1 ));
					run;  
%end; 
%if &nut=DB020  %then %do;
DATA  rdb.LI41 (drop=ARPT60i); ;
					set rdb.LI41(where=(not(time = &yyyy and  geo = "&Ucc" and length(geo)=2  and unit="&unit")))
    				work.LI41(WHERE=( ARPT60i=1));
				
					run;  
%end; 
PROC SQL;  
     Insert into log.log
     set date = "&sysdate"d, time = "&systime"t, user = "&sysuserid",
		 report = "* &nut - &Ucc - &yyyy * LI41 (re)calculated *";		  
QUIT;
 
%mend by_unit;
%if &EU=0 %then %do;
********************;
**  FORMATS;
Proc format;

VALUE f_incgrp (multilabel)
		0 = "A_MD60"
		1 = "B_MD60";
run;

* extract from BDB and then IDB;
%let listnut=  DB020  NUTS1  NUTS2   ;  
%let i=1; 
%let nut=%scan(&listnut,&i,%str( )); 
  %do  %while(&nut ne ); 
	%if &nut=DB020 %then %UPD_LI411(&nut); 
 	%if (&nut=NUTS1 or &nut=NUTS2) %then %do;
     	%if &yyyy > 2007 and (&Ucc=CZ or &Ucc=DK  or &Ucc=IE or &Ucc=ES or &Ucc=IT or
	    &Ucc=SK or &Ucc=FI or &Ucc =SE or  &Ucc =BG or &Ucc  =SI or &Ucc  =RO)  %then %UPD_LI411(&nut) ;
	 	%if &yyyy < 2008
		and  (&Ucc=CZ  or &Ucc=IE or &Ucc=ES or &Ucc=IT or
		&Ucc=SK or &Ucc=FI ) %then %UPD_LI411(&nut) ;
		%if &yyyy =2007 and (&Ucc= RO or &Ucc= =DK) %then %UPD_LI411(&nut) ;
		%if &yyyy >2004 and &Ucc=NO and &nut=NUTS1 %then %UPD_LI411(&nut) ;
		%if  &Ucc=NO and &nut=NUTS2 and  &yyyy ne 2004 %then %UPD_LI411(&nut) ;
		/*%if &Ucc=AT and &nut=NUTS2 %then %UPD_LI411(&nut) ;*/
		%if  &Ucc=CH and &nut=NUTS2 and  &yyyy > 2007 %then %UPD_LI411(&nut) ;
	%end;
    %if &nut=NUTS1 and  &Ucc=PL and &yyyy > 2011  %then %UPD_LI411(&nut) ;
	%if &nut=NUTS1 and  (&Ucc=HU or &Ucc=EL /*or &Ucc=BE*/ ) %then %UPD_LI411(&nut) ;
	%if &nut=NUTS1 and  &Ucc=NL and &yyyy > 2010 %then %UPD_LI411(&nut) ;
	/*%if &nut=NUTS2  and  &Ucc=AT and &yyyy < 2013 %then %UPD_LI411(&nut) ;*/
	%let i=%eval(&i+1);                                  
	%let nut=%scan(&listnut,&i,%str( )); 
  %end;  
%end;

%mend UPD_li41; 
