*** At-risk-poverty-rate anchored at a fixed moment in time (&ref_yr), by age and gender ***;
/* MG modified 15/03/2013 Added the calculation for 2008 */
%macro UPD_li22b_backwards(yyyy,Ucc,Uccs,flag) /store;

%let tab=li22b_backwards;

*PROC DATASETS lib=work kill nolist;
QUIT;
%global any_year nobs;
%let cc=%lowcase(&Ucc);
%let yy=%substr(&yyyy,3,2);
%let EU=0;
%if &Uccs=0 %then %let Uccs=("&Ucc");
%else %let EU=1; 

%let any_year=2008;

%macro any_year (any_year);

	%let any_yr =%substr(&any_year,3,2);
 
	%if ((&yyyy > 2005 and &any_year <= &yyyy and &Uccs ne "BG" and &Uccs ne "CH" and &Uccs ne "FR" and &Uccs ne "RO") or
		(&any_year > 2005 and &any_year <= &yyyy and &Uccs ="BG") or
		(&any_year > 2006 and &any_year <= &yyyy and &Uccs ="RO") or
		(&any_year > 2007 and &any_year <= &yyyy and &Uccs ="CH") or
		/*(&yyyy > 2005 and &yyyy < = 2008 and &any_year <= &yyyy and &Uccs = "FR")	or */
		(&any_year > 2007 and &any_year <= &yyyy and &Uccs = "FR"))
	%then %do;
		%let not60=0;
		
  
		%if &EU=0 %then %do;

		PROC FORMAT;
		    VALUE f_age (multilabel)
				0 - 17 = "Y_LT18"
				18 - 64 = "Y18-64"
				65 - HIGH = "Y_GE65"
				0 - HIGH = "TOTAL"
				;

			VALUE f_sex (multilabel)
				1 = "M"
				2 = "F"
				1 - 2 = "T";
		RUN;

		PROC SQL /*noprint*/;

		Create Table work.idx as select DISTINCT
			idx.GEO,
			idx.TIME,
			idx.IDX2005 AS IDX_REF_YR,
			idx_2.IDX2005 AS IDX_ANCHOR_YR,
			(100*idx.IDX2005/idx_2.IDX2005) AS IDX,
			(case
				    when (&yyyy > 2006 and &any_year <= 2006 and anchor.DB020 = "MT") then (anchor.ARPT60 / anchor.RATE) 
				    when (&yyyy > 2006 and &any_year <= 2006 and anchor.DB020 = "SI") then (anchor.ARPT60 / anchor.RATE) 
					when (&yyyy > 2008 and &any_year <= 2008 and anchor.DB020 = "CY") then (anchor.ARPT60 /anchor.RATE)
					when (&yyyy > 2008 and &any_year <= 2008 and anchor.DB020 = "SK") then (anchor.ARPT60 /anchor.RATE)
					when (&yyyy > 2011 and &any_year <= 2011 and anchor.DB020 = "EE") then (anchor.ARPT60 /anchor.RATE) 
				    else anchor.ARPT60
				  end) as ARPT60,
			(CALCULATED ARPT60 * CALCULATED IDX / 100) as ARPT60idx
			%if &Ucc =UK or &Ucc =IE %then %do;
				from idb.idx2005 as idx
				left join idb.idx2005 as idx_2 on (idx.GEO = idx_2.GEO)
				left join idb.IDB&any_yr as anchor on (idx.GEO = anchor.DB020)
				where idx.GEO in &Uccs and idx.TIME = (&yyyy) and idx_2.TIME = (&any_year);
				
			%end;
			%else %do;
				from idb.idx2005 as idx
				left join idb.idx2005 as idx_2 on (idx.GEO = idx_2.GEO)
				left join idb.IDB&any_yr as anchor on (idx.GEO = anchor.DB020)
				where idx.GEO in &Uccs and idx.TIME = (&yyyy-1) and idx_2.TIME = (&any_year-1);
			
			%end;
			quit;;
	
			
		Proc sql;
		Create table work.idb as select
					db.DB010, db.DB020, db.DB030, db.RB030, db.RB050a,
					db.Age, db.RB090, db.EQ_INC20,
					idx.idx,
				    idx.ARPT60idx,
			       (case
				    when db.EQ_INC20 < idx.ARPT60idx then 1
					else 0
					end) as ARPT60ix
		 	from idb.IDB&yy as db left join work.idx as idx on  (db.DB020 = idx.GEO)
			where db.age ge 0 and db.DB010 = &yyyy and db.DB020 in &Uccs;

		QUIT;
		Proc sql;
			Select distinct count(DB010) as N 
			into :nobs
			from  work.idb;
		
		QUIT;

	%if &nobs > 0 %then %do;
		PROC TABULATE data=work.idb out=Ti;
			FORMAT AGE f_age15.;
			FORMAT RB090 f_sex.;
			VAR RB050a;
			CLASS AGE /MLF;
			CLASS RB090 /MLF;
			CLASS ARPT60ix;
			CLASS DB020;
			TABLE DB020 * AGE * RB090, ARPT60ix * RB050a * (RowPctSum N Sum) /printmiss;
		RUN;

		PROC SQL;
 
		CREATE TABLE work.old_flag AS
				SELECT distinct
					time,
					geo,
					age,
					sex,
					iflag
				FROM rdb.&tab
				WHERE  time = &yyyy and geo="&Ucc"  ;
		

		CREATE TABLE work.&tab AS
		SELECT DISTINCT
			Ti.DB020 as geo FORMAT=$5. LENGTH=5,
			&yyyy as time,
			Ti.Age,
			Ti.RB090 as sex,
			TI.ARPT60ix as ARPT60ix,
			"LI_R_MD60" as indic_il,
			"PC_POP" as unit,
			Ti.RB050a_PctSum_1101 as ivalue,
			old_flag.iflag as iflag, 
			(case when sum(Ti.RB050a_N) < 20  then 2
				  when sum(Ti.RB050a_N) < 50 then 1
				  else 0
			      end) as unrel,
			Ti.RB050a_N as n,
			sum(Ti.RB050a_N) as ntot,
			sum(Ti.RB050a_Sum) as totwgh,
			"&sysdate" as lastup,
			"&sysuserid" as	lastuser 
		FROM Ti 
			LEFT JOIN work.old_flag ON (Ti.DB020=old_flag.geo) AND ( Ti.Age = old_flag.age) AND ( Ti.RB090 = old_flag.sex)
		GROUP BY Ti.DB020, ti.AGE, ti.RB090
		ORDER BY Ti.DB020, ti.AGE, ti.RB090;
		QUIT;

		* Update RDB;
    	DATA  rdb.&tab(drop= ARPT60ix);
		set rdb.&tab (where=(not(time = &yyyy and geo = "&Ucc" )))
		    work.&tab;
			where ARPT60ix=1;
		RUN;
        %end;
		%end;


		* EU aggregates;
		%if &EU %then %do;
			%if &any_year > &yyyy %then %do; /** changed */
			%let tab=li22b_backwards;
			%let grpdim=age, sex, indic_il, unit;
			%EUVALS(&Ucc,&Uccs);
			%end;
		%end;
	%end;
%mend any_year;

*%if &any_year > &yyyy    %then %do; /** changed  */

	%any_year(&any_year);
	/*
    %if  &nobs >0 %then %do;
		PROC SQL;  
			Insert into log.log
			set date = "&sysdate"d, time = "&systime"t, user = "&sysuserid",
			report = "* &Ucc - &yyyy * li22b_backwards (re)calculated *";		  
		QUIT;
	%end;
    %else %do;
		PROC SQL;  
			Insert into log.log
			set date = "&sysdate"d, time = "&systime"t, user = "&sysuserid",
			report = "* &Ucc - &yyyy * li22b_backwards NO data *";		  
		QUIT;
	%end;
%end;
%else %do;

	PROC SQL;  
		Insert into log.log
			set date = "&sysdate"d, time = "&systime"t, user = "&sysuserid",
		report = "* &Ucc - &yyyy <  reference year  for li22b_backwards *";		  
	QUIT;
*/

%end;


%mend UPD_li22b_backwards;
