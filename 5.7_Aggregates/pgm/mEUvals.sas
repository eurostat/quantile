/** \cond */
/** 
Aggregates calculations

Syntax
------

	%EUVALS(&eu,&ms);
  
Macros used 
-------
ctry_present : list of countries present in rdb.&tab dataset at the beginning
countries_&y1 : list of countries to add at each sample
ctry_add : all ocuntries to use for the calculation (ctry_present+ countries_&y1) 

&intab: LI02 to use for the calculation ( old LI02 + li02 related to the previous year 

Note
----
Could be possible that countries missing in &year are also missing in previous year (&year-1)
*/




%macro _example_aggregate_rule;
	%local flag_unit;

	%let tab=LI01;
	%aggregate_rule(&tab, _flag_=flag_unit);
	%put (i) for tab=&tab, flag_unit=&flag_unit;

	%let tab=dI05;
	%aggregate_rule(&tab, _flag_=flag_unit);
	%put (i) for tab=&tab, flag_unit=&flag_unit;

	%let tab=di02;
	%aggregate_rule(&tab, _flag_=flag_unit);
	%put (i) for tab=&tab, flag_unit=&flag_unit;

%mend _example_aggregate_rule;
%_example_aggregate_rule;
				  	  

%MACRO EUVALS(eu,ms);

%if &euok ne 1 %then %do; 
	%VarExist(ex_data.aggregate,&eu);
    %dif_country(&file1,&file2,&var);
 	%let i=1;
 	%let size_sample=%eval(&ctry_diff-(&ctry_diff-&i));
 	
  	%do  %while(&euok ne 1); 
		proc surveyselect data = countries_diff method = SRS rep = 1 
  			sampsize = &size_sample seed = 12345 out = countries_&y1;
  			id geo;
		run;
		data countries_&y1 (keep=geo);
			set countries_&y1;
		run;
		data ctry_add;
    		 set  ctry_present countries_&y1;
 		run;
 		%compare_size(ctry_add);
        %let i=%eval(&i+1);  
        %let size_sample=%eval(&ctry_diff-(&ctry_diff-&i)); 
		
 	%end;

/* select  from &tab, related previous year, all missing countries */
proc sql;
	create table &tab._&y1 as select a.* 
    from rdb.&tab as a
	inner join countries_&y1 as b on a.geo=b.geo
	where time =&year_1 ;
quit;
data &tab._&y1;
	set &tab._&y1;
	time=&yyyy;
run;
data &intab;
	set rdb.&tab;
	where time=&yyyy;
run;
data &intab;
	set &intab &tab._&y1;
run;
%end;
 
%let flageu=;

%if &euok and &yyyy > 2004 %then %do;

	%let neu=%substr(&eu,%eval(%length(&eu)-1),2); /* takes the normal number of country in the aggregate*/

	%if &nobs ne &neu %then %do; %let flageu=s; %end; /* put flag s if some countries are missing*/

	%if (&eu=EU27 AND &yyyy<2007) %then %do; %let flageu=s; %end; /* put flag s as BG RO are fake data 20111206BB */
	
/* insert test for indicators required only for currency=EUR */
	PROC SQL;
	CREATE TABLE euval1 AS SELECT &intab..*, 
		ccwgh60.Y&yyyy,
		(unrel * Y&yyyy) as wunrel
	 	FROM &intab
		LEFT JOIN ex_data.CCWGH60 ON (&intab..geo = ccwgh60.DB020)
	 %if &tab =di10 or &tab =di02 %then %do;
		WHERE geo in &ms and time = &yyyy and currency in ('EUR');
	%end;
	%if &tab =di03 or &tab =di04 or &tab =di05 or &tab=di07 or &tab=di08 or &tab=di09 or &tab=di13 or &tab=di14 or  &tab=di13b or  &tab=di14b %then %do;
		WHERE geo in &ms and time = &yyyy and unit in ('EUR');
	%end;
	%else %do;
		WHERE geo in &ms and time = &yyyy ;
	%end;
quit;

PROC SQL;
	CREATE TABLE euval AS SELECT DISTINCT 
		 	&grpdim,
			(CASE WHEN unit in ("THS_PER", "THS_CD08") THEN ivalue
					ELSE (ivalue * totwgh ) END) AS wivalue ,
			SUM(totwgh) as SUM_OF_totwgh,
			(SUM(CALCULATED wivalue)) AS SUM_OF_wivalue,
			(CASE WHEN unit in  ("THS_PER", "THS_CD08") THEN ( CALCULATED SUM_of_wivalue * &infl)
			ELSE (CALCULATED SUM_OF_wivalue / CALCULATED SUM_OF_totwgh ) END) AS euvalue,
			SUM(n) as SUM_OF_n,
			SUM(ntot) as SUM_OF_ntot,
			(case when (sum(wunrel)/(&real_size)) > 0.6 then 2
			when (sum(wunrel)/(&real_size)) > 0.3 then 1
			when (sum(wunrel)) ne 0 then 3
			else (case when "&flageu" = "s" then 3
				else 0
			    end)
		    end) as euunrel
	FROM work.euval1
	/*WHERE geo in &ms and time = &yyyy */
	GROUP BY &grpdim;
	CREATE TABLE &tab as
	SELECT DISTINCT 
		"&eu" as geo,
		&yyyy as time,
		&grpdim,
		unit,
		euvalue as ivalue,
		"&flag" as iflag FORMAT=$3. LENGTH=3,
		euunrel as unrel,
		SUM_OF_n as n,
		SUM_OF_ntot as ntot,
		SUM_OF_totwgh as totwgh,
		"&sysdate" as lastup,
		"&sysuserid" as	lastuser 
	FROM euval; 
	QUIT;
* Update RDB;
/*
DATA  rdb.&tab;
	set rdb.&tab(where=(not(time = &yyyy and geo = "&Ucc")))
    work.&tab; 
RUN;
*/
%end;



%MEND EUVALS;








/** \endcond */







