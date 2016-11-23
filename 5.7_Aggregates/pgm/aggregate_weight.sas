/** 
## aggregate_weight {#sas_aggregate_weight} 
Construct the weighted indicator as the indicator values over the countries weighted
by their respective populations.
 
	%aggregate_weight(zone, grpdim, tab, pop_part, pop_infl, dsn_o, lib=WORK, flag=, flag_zone=);

### Arguments
* `zone` : code of a geographical area, _e.g._, EU28, EA19, etc..;
* `grpdim` : list of fields to consider in the dataset;
* `tab` : working dataset indicator values and populations (_e.g._, the output of [aggregate_join](aggregate_join);
* `pop_part` : numeric variable storing the (partial) population cumulated over those countries
	that will be used for aggregate estimation;
* `pop_infl` : 'inflation' rate between both the global and partial populations, so that:
		`pop_glob = pop_part * infl`;
* `flag` : (_option_) ; default: not set; 
* `flag_zone` : (_option_) ; default: not set;
* `lib` : (_option_) input dataset library; default (not passed or ' '): `lib` is set to `WORK`.

### Returns
* `dsn_o` : name of the dataset with indicator value and weighting respective of the countries'
	populations.

### Example
Run macro `%%_example_aggregate_weight`.
*/ /** \cond */

%macro aggregate_weight(/*input*/ zone, grpdim, tab, pop_part, pop_infl,  
						/*output*/ dsn_o,
						/*option*/lib=, flag=, flag_zone=);

	%if %macro_isblank(lib) %then 	%let lib=WORK;

	%local TMP;
	%let TMP=_tmp_aggregate_weight;

	%let grpdim=%clist_unquote(&grpdim, sep=%str(%"), rep=%str(,));

	%local unitOK;
	%let unitOK=%var_check(&tab, unit);
	%put in tab=&tab, found unit? &unitOK;
	%if &unitOK=yes %then %do;
		%put hummmmmmmmmmm;
	%end;
	PROC SQL;
		CREATE TABLE &TMP AS SELECT DISTINCT 
		&grpdim,
		SUM(totwgh) as SUM_OF_totwgh,
		%if &unitOK=yes %then %do;
		/* %if &dsn =LI43 or &dsn =lvhl23 or &dsn =mddd23 or &dsn=peps13 %then %do; */
			(case when unit in ("THS_PER", "THS_CD08") then ivalue
				else (ivalue * totwgh) 
				end) AS wivalue ,
			(SUM(CALCULATED wivalue)) AS SUM_OF_wivalue,
			(case when unit in  ("THS_PER", "THS_CD08") then (CALCULATED SUM_of_wivalue * &pop_infl)
				else (CALCULATED SUM_OF_wivalue / CALCULATED SUM_OF_totwgh ) 
				end) AS euvalue,	
		%end;
		%else %do;
			(ivalue * totwgh ) AS wivalue ,
			(SUM(CALCULATED wivalue)) AS SUM_OF_wivalue,
			(CALCULATED SUM_OF_wivalue / CALCULATED SUM_OF_totwgh ) AS euvalue,
		%end;
		SUM(n) as SUM_OF_n,
		SUM(ntot) as SUM_OF_ntot,
		(case when (sum(wunrel)/(&pop_part)) > 0.6 then 2
			when (sum(wunrel)/(&pop_part)) > 0.3 then 1
			when (sum(wunrel)) ne 0 then 3
			else (case when "&flag_zone" = "s" then 4 /* it is 4 in _mEUvals, 3 in mEUvals!!! */
					else 0
					end)
			end) as euunrel
		/* use previously table output by aggregate_build */
		from &lib..&tab
		/*WHERE geo in &ms and time = &yyyy */
		group by &grpdim;
	quit;

	PROC SQL;
		CREATE TABLE   &dsn_o
		AS SELECT  DISTINCT 
			"&zone" as GEO,
			&year as TIME,
			&grpdim,
			euvalue as ivalue,
			"&flag" as iflag FORMAT=$3. LENGTH=3,
			euunrel as unrel,
			SUM_OF_n as n,
			SUM_OF_ntot as ntot,
			SUM_OF_totwgh as totwgh,
			"&sysdate" as lastup,
			"&sysuserid" as	lastuser 
		FROM &TMP; 
	quit;

	%work_clean(ds=&TMP);
	%exit:
%mend aggregate_weight;


%macro _example_aggregate_weight;
	%if %symexist(EUSILC) EQ 0 %then %do; 
		%include "/ec/prod/server/sas/0eusilc/library/autoexec/_setup_.sas";
		%_default_setup_;
	%end;

	/* we ensure that we are in test environment */
	/*	%_startup_env_(legacy=yes, test=yes);*/
	libname rdb "&G_PING_C_RDB"; /* "&eusilc/IDB_RDB_TEST/C_RDB"; */ 

	%let year=2015;
	%let ctry_code=EU28;
	%let ctry_glob=("AT","BE","BG","CY","CZ","DE","DK","EE","ES","FI","FR","EL","HU","IE",
					"IT","LT","LU","LV","MT","NL","PL","PT","RO","SE","SI","SK","UK","HR");
	%put list of EU28 countries required: &ctry_glob;

	%let dsn=DI02;

	%if %symexist(G_PING_COUNTRY_POPULATIONS) %then 	%let pop_file=&G_PING_COUNTRY_POPULATIONS;
	%else										%let pop_file=COUNTRY_POPULATIONS;

	%local tab_part tab_o;
	%let tab_part=_tmp_example_aggregate_weight;

	%*local pop_infl run_agg pop_part;
	%let pop_infl=;
	%let run_agg=;
	%let pop_part=;

	%put other variables to default values;
	%work_clean(ds=&tab_part);
	%aggregate_build(&dsn, &ctry_glob, &year, &tab_part, 
				_pop_infl_=pop_infl, _run_agg_=run_agg, _pop_part_=pop_part,
				take_all=yes, pop_file=&pop_file, lib=rdb);
	%put 	result in: pop_infl=&pop_infl, pop_part=&pop_part, run_agg=&run_agg;
	%ds_print(&tab_part);
	
	%let tab_o=_tmp_out_example_aggregate_weight;
	%aggregate_join(&dsn, &tab_part, 2015, &tab_o, lib=rdb);
	%ds_print(&tab_o);

	%local dsn_o;
	%let dsn_o=_out_example_aggregate_weight;
	 
	%let grpdim= ("incgrp","indic_il","currency","unit") ;
	%aggregate_weight(&ctry_code, %quote(&grpdim), &tab_o, &pop_part, &pop_infl,  &dsn_o);

	%work_clean(ds=&tab_part);
	%work_clean(ds=&tab_o);
	%work_clean(ds=&dsn_o);

%mend _example_aggregate_weight;

/* 
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;
%_example_aggregate_weight;  
*/

/** \endcond */
