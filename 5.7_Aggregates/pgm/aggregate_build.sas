/** 
## aggregate_build {#sas_aggregate_build}
Build the list of countries/years to take into consideration in order to calculate the 
aggregate value for a given indicator and a given area.
 
	%aggregate_build(dsn, ctry_glob, year, 
					 ctry_tab, _pop_infl_=, _run_agg_=, _pop_part_=,
					 take_all=no, nyear_back=0, lib=, pop_file=, 
					 sampsize=0, max_sampsize=0, thres_presence=, thres_reach=);

### Arguments
* `dsn` : a dataset representing the indicator for which an aggregated value is estimated;
* `ctry_glob` : list of (comma-separated, in-between quotes) strings representing the ISO-codes
	of all the countries that belong to a given geographical area;
* `year` : year of interest;
* `take_all` : (_option_) take all possible data from the input dataset, whatever the year 
	considered; when set to yes, all other arguments normally used for building the list of
	countries (see below: sampsize, max_sampsize, thres_presence, thres_reach) are ignored; 
	default to no;
* `nyear_back` : (_option_) look backward in time, _i.e._ consider the nyear_back years prior to the
	considered year; default to 0, _i.e._ only data available for current year shall be considered;
* `sampsize` : (_option_) size of the set of countries from previous year that is sequentially added 
	to the list of available countries so as to reach the desired threshold; default to 0, i.e. 
	all available shall be added at once when available;
* `max_sampsize` : (_option_) maximum number of additional countries from previous to take into
	consideration for the estimation; default to 0;
* `thres_presence` : (_option_) value (in range [0,1]) of the threshold to test whether:
		`pop_part / pop_glob >= pop_thres` ? 
	default to 0.7 (_i.e._ `pop_part` should be at least 70% of `pop_glob`);
* `thres_reach` : (_option_) value (in range [0,1]) of the second threshold considered when complementing
	the list of currently available countries with countries from previous years; default: not set; 
* `pop_file` : (_option_) file storing the population of the different countries (_e.g._, what used to be 
	`CCWGH60`); see `SILCFMT` library;
* `lib` : (_option_) input dataset library; default (not passed or ' '): `lib` is set to `WORK`.

### Returns
* `ctry_tab` : name of the output table where the list of countries with the year of estimation is
	stored;
* `_pop_infl_` : name of the macro variables storing the 'inflation' rate between both global and
	partial population, _i.e._ the ratio pop_glob / pop_part;
* `_run_agg_` : name of the macro variables storing the result of the test whhether some aggregates
	shall be computed or not, _i.e._ the result (`yes/no`) of the test:
		`pop_part / pop_glob >= pop_thres` ?
* `_pop_part_` : name of the macro variable storing the final cumulated population considered for 
	the estimation of the aggregate.

### Note
Visit <http://data.worldbank.org/about/data-overview/methodologies>.

### Example
Run macro `%%_example_aggregate_build`.

### See also
[ctry_select](@ref sas_ctry_select), [ctry_population](@ref sas_ctry_population), and [population_compare](@ref sas_population_compare).
*/ /** \cond */

%macro aggregate_build(/*input*/    dsn, ctry_glob, year, 
				  	   /*output*/   ctry_tab, _pop_infl_=, _run_agg_=, _pop_part_=,
				  	   /*option*/ take_all=no, nyear_back=0, lib=, pop_file=, 
					   sampsize=0, max_sampsize=0, thres_presence=, thres_reach=);

	/* ctry_tab: name of the table where to store the presence+year of countries */

	/* local variables used in this macro */
	%local ctry_part ctry_miss pop_glob pop_part;
	%local force_overwrite;
	%local max_ctry_n n_miss;
	%local ny_back year_available;

	%let G_PING_DEBUG=1; 
	%let DEF_CTRY_CODE_LEN=2; /* (dummy) countries are ISO-3611 encoded: 2 char */

	%if %error_handle(ErrorInputParameter, 
			%macro_isblank(_pop_infl_) EQ 1 and %macro_isblank(_run_agg_) EQ 1,		
			txt=!!! output macro variable _pop_infl_ and _run_agg_ need to be set !!!) %then 
		%goto exit;

	%if %macro_isblank(_pop_part) %then 	%let _pop_part_=pop_part;

	%if &G_PING_DEBUG %then %put input parameters: ny=&nyear_back, s=&sampsize, th_reach=&thres_reach, th_presence=&thres_presence;

	
	/* check the treshold variables, possibly set default values when not passed */
	%if %symexist(G_PING_AGG_POP_THRESH) %then 	%let DEF_AGG_POP_THRESH=&G_PING_AGG_POP_THRESH;
	%else 									%let DEF_AGG_POP_THRESH=0.7; /* yep... */
	%if %macro_isblank(thres_presence) %then		%let thres_presence=&DEF_AGG_POP_THRESH; 
	%if %macro_isblank(thres_reach) %then			%let thres_reach=&thres_presence;

	%if %macro_isblank(pop_file) %then %do;
		%if %symexist(G_PING_COUNTRY_POPULATIONS) %then 	%let pop_file=&G_PING_COUNTRY_POPULATIONS;
		%else										%let pop_file=COUNTRY_POPULATIONS;
	%end; 

	/* adjust the treshold variables depending on other parameters */
	%if &take_all=yes /* we want all countries to be included in the aggregate, whatever year is considered */
		%then %do;
		%if &nyear_back^=-1 %then %let nyear_back=10; /* we will go backward in time as much as we can... ok, 
							 						   * let's still be reasonable: 10 years back is enough */  			
		%let sampsize=0;   	/* we take all countries available for a given year */
		%let thres_reach=1; /* we will try to reach the quorum with the closest year in time; note that in
							 * fact, this is redundant with sampsize=0 */ 
	%end;
	%else %if &nyear_back=0 	/* we will look at the current year only */
		%then %do;
		%let thres_reach=0; /* we force this threshold to be ignored in practice */
	%end;

	%if &G_PING_DEBUG %then %put adjusted parameters: ny=&nyear_back, s=&sampsize, th_reach=&thres_reach, th_presence=&thres_presence;

	/* let's make some calculation on the considered aggregated zone/area
	 * first the max number of countries we may find = number of countries in the area */
	%let max_ctry_n=%clist_length(&ctry_glob);
	%if &G_PING_DEBUG %then %put max number of countries in the zone: max_ctry_n=&max_ctry_n;

	%if &max_ctry_n=0 %then %do;
		%let &_run_agg_=no;
		%let &_pop_infl_=-1;
		%goto break_loop_0;
	%end;

	/* in the case max_sampsize=0, we want to include all possible countries without restriction on the number */
	%if &max_sampsize=0 %then %let max_sampsize=&max_ctry_n;

	/* then the total population of the area */
	%ctry_population(&ctry_glob, &year, _pop_size_=pop_glob, pop_file=&pop_file);
	%if &G_PING_DEBUG %then %put cumulated population in the zone: pop_glob=&pop_glob;

	/* initialise the index on the years of search */
	%let ny_back=0;

	/* initialise the output variables */
	%let &_run_agg_=no;
	%let &_pop_infl_=-1;

	/*just in case: clean the table... 
	%work_clean(ds=&ctry_tab);
	* we use instead the force_overwrite variable below */
	
	/* initialise some useful variables: all countries are missing when we start */
	%let ctry_miss=&ctry_glob;
	%let n_miss=max_ctry_n;

	/* LOOP_0: start the tests through a loop ... */
	%do %while (1);
		%if &G_PING_DEBUG %then %put enter LOOP_0;

		/* go backward in time */
		%let year_available=%eval(&year - &ny_back);	
		%if &G_PING_DEBUG %then %put test &year_available;

		/* LOOP_1: look for the partial subset of countries among missing countries that are present in
		 * the dsn in (year_available); possibly proceed by randomly adding countries. 
		 * store (and update) the result (together with the year) in the table ctry_tab, where other countries 
		 * tested on previous years may already be stored */
		%do %while (1);
			%if &G_PING_DEBUG %then %put enter LOOP_1;

			%if &G_PING_DEBUG %then %put select available countries among &ctry_miss;
			/* when considering the year of the calculation (case year_available=year), we take all 
			 * countries available, no sampled selection is performed */
			%if &year_available=&year %then 	%let s_size=0; 
			%else								%let s_size=&sampsize;
			/* as we cannot add more countries than what available (case s_size>n_miss), we need to
			 * reduce the size of the sampled selection */
			%if &s_size>&n_miss %then 			%let s_size=&n_miss; 
			/* actual selection (addition) of countries through random sampling */
			%if &G_PING_DEBUG %then %do;
				%put look into: dsn=&lib..&dsn;
				%put      for: ctry=&ctry_miss;
				%put      in: year=&year_available;
				%put      with: s_size=&s_size;
			%end;
			%ctry_select(&dsn, &ctry_miss, &year_available, &ctry_tab, lib=&lib, sampsize=&s_size, 
						   	len=&DEF_CTRY_CODE_LEN);
 
			/* retrieve the subset of countries available from (year_available) onwards as a list 
			 * derived from tab.
			 * the list may indeed cumulate countries over several years ranging from (year_available)
			 * to (year) */
			%var_to_clist(&ctry_tab, geo, _varclst_=ctry_part, lib=WORK, num=&max_ctry_n, len=&DEF_CTRY_CODE_LEN);
			%if &G_PING_DEBUG %then %put added countries: &ctry_part;

			/* compute the new aggregated population for the partial list of countries
		     * note: for countries that are present in , we still look at the population in (year):
			 * for this reason, &year appears below, and not &year_available (this is a rough
		     * estimation!) */
			%ctry_population(&ctry_part, &year, _pop_size_=&_pop_part_, pop_file=&pop_file);
			%if &G_PING_DEBUG %then %put population of added countries: &&&_pop_part_;
	
			/* let's compare this new aggregated population with the global (desired) population and 
		 	 * procede with the test again */ 
			%if &year_available=&year %then 	%let thres=&thres_presence; 
			%else								%let thres=&thres_reach; 
			/* do the actual comparison which returns _run_agg_=yes iif 1/_pop_infl_>thres */
			%population_compare(&pop_glob, &&&_pop_part_, _pop_infl_=&_pop_infl_, _run_agg_=&_run_agg_, 
								pop_thres=&thres);
			%let ratio = %sysevalf(1 / &&&_pop_infl_);
			%if &G_PING_DEBUG %then %put ratio of cumulated countries: &ratio;

			/* retrieve (hence, update for the next search in the loop) the list (subset) of missing 
			 * countries as the difference of the previous missing list (set) of countries minus the
			 * partial list (subset) of available countries just calculated */
			%let ctry_miss=%clist_difference(&ctry_miss, &ctry_part, sep=%str(%"));
			%if &G_PING_DEBUG %then %put missing countries: &ctry_miss;

			/* decrement the number of added countries from (year_available) */
			%let max_sampsize=%sysevalf(&max_sampsize - &s_size);
			/* note that for year_available=year, max_sampsize is unchanged as s_size=0 */
			
			/* how many countries are still missing ? */
			%let n_miss=%clist_length(&ctry_miss, _sep=%str(%"));

			/* Here is the test for leaving the first "while" loop */
			%if &n_miss=0 /* we selected all available countries for this year_available, we cannot
			  			     add anything anymore */
				%then %do;
				%goto break_loop_1_case1;
			%end;
			%else %if &&&_run_agg_=yes /* i.e. &&&_pop_infl_=1: we reached the "quorum" */
				or &year_available=&year /* for the first year, we do not run any sampling selection:
										  * all countries were selected */
				%then %do;
				%goto break_loop_1_case2;
			%end;
		%end;

		/* Here is a series of tess for leaving the second "while" loop */

		%break_loop_1_case1:
		%if &G_PING_DEBUG %then %put enter break_loop_1_case1;
		/* ctry_miss=(): as the 'missing' list empty, all countries are...available! */
		%let &_run_agg_=yes;
		%let &_pop_infl_=1;
		%goto break_loop_0;	

		%break_loop_1_case2:
		%if &G_PING_DEBUG %then %put enter break_loop_1_case2;
		/* test if we reached the "quorum"... but maybe we want more! */
		/* note that &_pop_infl_ has also been updated in the previous function */
		%if &thres_presence<=&thres_reach %then %do;
			%let thres_presence=&thres_reach;
			%goto next_loop_0;
		%end;
		%else %do;
			%goto break_loop_0;
		%end;	

		%next_loop_0:
		%if &G_PING_DEBUG %then %put enter next_loop_0;
		/* increment the number of year to go backward in time */
		%let ny_back=%eval(&ny_back+1);

		%if &ny_back>&nyear_back %then %do;
			%goto break_loop_0;
		%end;
	%end;

	%break_loop_0:
	%if &G_PING_DEBUG %then %put enter break_loop_0;
	%if &G_PING_DEBUG %then %put pop_infl=&&&_pop_infl_, run_agg=&&&_run_agg_;
	/* return the results
	data _null_;
		call symput("&_pop_infl_",&_pop_infl);
		call symput("&_run_agg_","&_run_agg");
	run; */

	%exit:
%mend aggregate_build;

%macro _example_aggregate_build;
	%if %symexist(G_PING_ROOTPATH) EQ 0 %then %do; 
		%if %symexist(G_PING_SETUPPATH) EQ 0 %then 	%let G_PING_SETUPPATH=/ec/prod/server/sas/0eusilc; 
		%include "&G_PING_SETUPPATH/library/autoexec/_setup_.sas";
		%_default_setup_;
	%end;

	libname rdb "&G_PING_C_RDB"; /* "&eusilc/IDB_RDB_TEST/C_RDB"; */ 

	%let year=2015;
	%let ctry_code=EU28;
	%let ctry_glob=("AT","BE","BG","CY","CZ","DE","DK","EE","ES","FI","FR","EL","HU","IE",
					"IT","LT","LU","LV","MT","NL","PL","PT","RO","SE","SI","SK","UK","HR");
	%put list of EU28 countries required: &ctry_glob;

	%let dsn=LI01;

	%if %symexist(G_PING_COUNTRY_POPULATIONS) %then 	%let pop_file=&G_PING_COUNTRY_POPULATIONS;
	%else										%let pop_file=COUNTRY_POPULATIONS;

	%let tab_part=tab_example_aggregate_build;

	%*local pop_infl run_agg pop_part;
	%let pop_infl=;
	%let run_agg=;
	%let pop_part=;

	%let nyear_back=0;
	%let thres_presence=0.7;
	%let sampsize=0;
	%put (i) test countries currently available in dsn=&dsn with ny=&nyear_back and th_presence=&thres_presence ...;
	%put other variables to default values;
	%work_clean(&tab_part);
	%aggregate_build(&dsn, &ctry_glob, &year, &tab_part, 
					 _pop_infl_=pop_infl, _run_agg_=run_agg, _pop_part_=pop_part,
					 nyear_back=&nyear_back, thres_presence=&thres_presence, sampsize=&sampsize,
					 pop_file=&pop_file, lib=rdb);
	%put 	result in: pop_infl=&pop_infl, pop_part=&pop_part, run_agg=&run_agg;
	PROC print data=&tab_part; quit;
	%work_clean(&tab_part);

	%let nyear_back=0;
	%let thres_presence=0.05;
	%let sampsize=0;
	%put (ii) test countries currently available in dsn=&dsn with ny=&nyear_back and th_presence=&thres_presence ...;
	%put other variables to default values;
	%work_clean(&tab_part);
	%aggregate_build(&dsn, &ctry_glob, &year, &tab_part, 
					 _pop_infl_=pop_infl, _run_agg_=run_agg, _pop_part_=pop_part,
					 nyear_back=&nyear_back, thres_presence=&thres_presence, sampsize=&sampsize,
					 pop_file=&pop_file, lib=rdb);
	%put 	result in: pop_infl=&pop_infl, pop_part=&pop_part, run_agg=&run_agg;
	PROC print data=&tab_part; quit;
	%work_clean(&tab_part);

	%let nyear_back=1;
	%let thres_presence=0.01;
	%let thres_reach=0.7;
	%let sampsize=1;
	%put (iii) test countries currently available in dsn=&dsn with ny=&nyear_back and th_presence=&thres_presence ...;
	%put other variables to default values;
	%work_clean(&tab_part);
	%aggregate_build(&dsn, &ctry_glob, &year, &tab_part, 
					 _pop_infl_=pop_infl, _run_agg_=run_agg, _pop_part_=pop_part,
					 nyear_back=&nyear_back, thres_presence=&thres_presence, thres_reach=&thres_reach, sampsize=&sampsize,
					 pop_file=&pop_file, lib=rdb);
	%put 	result in: pop_infl=&pop_infl, pop_part=&pop_part, run_agg=&run_agg;
	PROC print data=&tab_part; quit;
	%work_clean(ds=&tab_part);
	
	%put (iv) take all countries (currently available or not) in dsn=&dsn with take_all set to yes ...;
	%work_clean(&tab_part);
	%aggregate_build(&dsn, &ctry_glob, &year, &tab_part, 
					 _pop_infl_=pop_infl, _run_agg_=run_agg, _pop_part_=pop_part,
					 take_all=yes, pop_file=&pop_file, lib=rdb);
	%put 	result in: pop_infl=&pop_infl, pop_part=&pop_part, run_agg=&run_agg;
	PROC print data=&tab_part; quit;
	%work_clean(&tab_part);

%mend _example_aggregate_build;

/* 
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;
%_example_aggregate_build;  
*/

/** \endcond */
