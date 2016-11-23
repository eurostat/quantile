/** 
## aggregate_join {#sas_aggregate_join}
Join the countries available for aggregate estimation together with their respective
population.
 
	%aggregate_join(dsn, ctry_tab, year, dsn_o, lib=WORK, flag_unit=, pop_file=);

### Arguments
* `dsn` : a dataset representing the indicator for which an aggregated value is estimated;
* `ctry_tab` : name of the table where the list of countries with the year of estimation is
	stored;
* `year` : year of interest;
* `flag_unit` : (_option_) ; default: not set; 
* `pop_file` : (_option_) file storing the population of the different countries (_e.g._, what used 
	to be `CCWGH60`); see `SILCFMT` library;
* `lib` : (_option_) input dataset library; default (not passed or ' '): `lib` is set to `WORK`.

### Returns
* `dsn_o` : name of the joined dataset.

### Example
Run macro `%%_example_aggregate_join`.
*/ /** \cond */


%macro aggregate_join(/*input*/  dsn, ctry_tab, year, 
					  /*output*/ tab_o,
					  /*option*/ lib=, flag_unit=, pop_file=);

	%if %macro_isblank(&lib) %then 	%let lib=WORK;

	%if %macro_isblank(pop_file) %then %do;
		%if %symexist(G_PING_COUNTRY_POPULATIONS) %then 	%let pop_file=&G_PING_COUNTRY_POPULATIONS;
		%else										%let pop_file=COUNTRY_POPULATIONS;
	%end; 

	%local SILCLIBCFG;
	%if %symexist(G_PING_SILCLIBCFG) %then 			%let SILCLIBCFG=&G_PING_SILCLIBCFG;
	%else										%let SILCLIBCFG=SILCFMT;

	%local v_time v_geo;
	%if %symexist(G_PING_VAR_TIME) %then 			%let v_time=&G_PING_VAR_TIME;
	%else										%let v_time=TIME;
	%if %symexist(G_PING_VAR_GEO) %then 				%let v_geo=&G_PING_VAR_GEO;
	%else										%let v_geo=GEO;
	
	/* retrieve the final list of available countries */
	%local ctry_clist;
	%var_to_clist(&ctry_tab, &v_geo, _varclst_=ctry_clist);
	%put flag_unit=AAAAAAA&flag_unit.AAAAAAAAA;
	%if not %macro_isblank(flag_unit) %then %do;
		%put found: flag_unit=&flag_unit;
	%end;
	PROC SQL;
		create table &tab_o as 
		select ds.*, 
		popf.Y&year, /* note that for the population, we again consider the current year */
		(unrel * Y&year) as wunrel 
	 	from &lib..&dsn as ds 
		inner join &ctry_tab ON (ds.&v_time = &ctry_tab..&v_time and ds.&v_geo = &ctry_tab..&v_geo)
		inner join &SILCLIBCFG..&pop_file as popf ON (popf.DB020=ds.&v_geo)
		where ds.&v_geo in &ctry_clist
		%if not %macro_isblank(flag_unit) %then %do;
			and ds.&flag_unit in ('EUR')
		%end;
		;
	quit;

%mend aggregate_join;

%macro _example_aggregate_join;
	%if %symexist(EUSILC) EQ 0 %then %do; 
		%include "/ec/prod/server/sas/0eusilc/library/autoexec/_setup_.sas";
		%_test_setup_;
	%end;

	/* first simple test */
	%_dstest25;
	%_dstest26;
	%_dstest27;

	%ds_print(_dstest26);
	%work_clean(_dstest26);

	%let tab_o=_tmp_out_example_aggregate_join;
	%zone_join(_dstest25, _dstest27, 2014, &tab_o, flag_unit=unit );
	%ds_print(&tab_o);
	%work_clean(_dstest25);
	%work_clean(_dstest27);
	%work_clean(&tab_o);

	/* more complex test: combine with zone_build */

	libname rdb "&G_PING_C_RDB"; /* "&eusilc/IDB_RDB_TEST/C_RDB"; */ 

	%let year=2015;
	%let ctry_code=EU28;
	%let ctry_glob=("AT","BE","BG","CY","CZ","DE","DK","EE","ES","FI","FR","EL","HU","IE",
					"IT","LT","LU","LV","MT","NL","PL","PT","RO","SE","SI","SK","UK","HR");
	%put list of EU28 countries required: &ctry_glob;

	%let dsn=LI01;

	%if %symexist(G_PING_COUNTRY_POPULATIONS) %then 	%let pop_file=&G_PING_COUNTRY_POPULATIONS;
	%else										%let pop_file=COUNTRY_POPULATIONS;

	%let tab_part=_tmp_example_aggregate_join;

	%*local pop_infl run_agg pop_part;
	%let pop_infl=;
	%let run_agg=;
	%let pop_part=;

	%put other variables to default values;
	%zone_build(&dsn, &ctry_glob, &year, &tab_part, 
				_pop_infl_=pop_infl, _run_agg_=run_agg, _pop_part_=pop_part,
				take_all=yes, pop_file=&pop_file, lib=rdb);
	%put 	result in: pop_infl=&pop_infl, pop_part=&pop_part, run_agg=&run_agg;
	%ds_print(&tab_part);
	%work_clean(&tab_part);

	%zone_join(&dsn, &tab_part, 2015, &tab_o, lib=rdb);
	%ds_print(&tab_o);

	%work_clean(&tab_part);
	%work_clean(&tab_o);

%mend _example_aggregate_join;

/* 
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;
%_example_aggregate_join;  
*/

/** \endcond */
