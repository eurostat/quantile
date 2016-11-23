/** 
## population_compare {#sas_population_compare}
Compare the ratio of two populations with a given threshold.

	%population_compare(pop_glob, pop_part, _pop_infl_=, _run_agg_=, pop_thres=0.7);

### Arguments
* `pop_glob, pop_part` : two (string/numeric) variables storing respectively the global and partial
	population figures to compare, where `pop_glob > pop_part`;
* `pop_thres` : (_option_) value (in range [0,1]) of the threshold to test whether:
		`pop_part / pop_glob >= pop_thres` ?
	default to 0.7 (_i.e._ `pop_part` should be at least 70% of `pop_glob`).
 
### Returns
* `_pop_infl_` : name of the macro variables storing the 'inflation' rate between both global and
	partial population, _i.e._ the ratio `pop_glob / pop_part`;
* `_run_agg_` : name of the macro variables storing the result of the test whhether some aggregates
	shall be computed or not, _i.e._ the result (yes/no) of the test:
		`pop_part / pop_glob >= pop_thres` ?

### Examples
_Alleluia!!!_
	
	%let pop_infl=;
	%let run_agg=;
	%population_compare(1, 0.1, _pop_infl_=pop_infl, _run_agg_=run_agg, pop_thres=0.2);

returns `pop_infl=10` and `run_agg=no`.

	%population_compare(1, 0.2, _pop_infl_=pop_infl, _run_agg_=run_agg, pop_thres=0.2);

returns `pop_infl=5` and `run_agg=yes` (note that we indeed test `>=`).

	%population_compare(1, 0.5, _pop_infl_=pop_infl, _run_agg_=run_agg, pop_thres=0.2);

returns `pop_infl=2` and `run_agg=yes`.

Run macro `%%_example_population_compare` for more examples.

### See also
[%ctry_population_compare](@ref sas_ctry_population_compare)
*/ /** \cond */

%macro population_compare(pop_glob		/* Global cumulated population 									(REQ) */
						, pop_part		/* Partial cumulated population 								(REQ) */
						, _pop_infl_=	/* Name of the macro variables storing the 'inflation' rate		(REQ) */
						, _run_agg_=	/* Name of the macro variables storing the result of the test	(REQ) */
						, pop_thres=	/* Population ratio considered as a threshold for the test 		(OPT) */
						);
	%local _mac;
	%let _mac=&sysmacroname;

	%if %error_handle(ErrorInputParameter, 
			%macro_isblank(_pop_infl_) EQ 1 and %macro_isblank(_run_agg_) EQ 1, mac=&_mac,		
			txt=!!! one of the output macro variables _POP_INFL_ or _RUN_AGG_ needs to be set !!!) %then
		%goto exit;

	%if %macro_isblank(pop_thres) %then %do; 			
		%if %symexist(G_PING_AGG_POP_THRESH) %then 	%let pop_thres=&G_PING_AGG_POP_THRESH;
		%else 									%let pop_thres=0.7; /* yep... */
	%end;
 
 	%local _pop_infl _run_agg;
	/*%let _run_agg=;*/
	%let _pop_infl=%sysevalf(&pop_glob / &pop_part);
	/*%let pop_infl_i=%sysevalf(&pop_part / &pop_glob);*/
	%let pop_test=%sysevalf(&pop_glob * &pop_thres);

	/* perform the test */
	%if &pop_part >= &pop_test %then %do;
	/* %if &pop_infl_i >= &pop_thres %then %do; */
		%let _run_agg=yes;
	%end;
	%else %do;
		%let _run_agg=no;
	%end;

	/* store the results */
	data _null_;
		%if not %macro_isblank(_pop_infl_) %then %do;
			call symput("&_pop_infl_",&_pop_infl);
		%end;
		%if not %macro_isblank(_run_agg_) %then %do;
			call symput("&_run_agg_","&_run_agg");
		%end;
	run;

	%exit:
%mend population_compare;

%macro _example_population_compare();
	%if %symexist(G_PING_ROOTPATH) EQ 0 %then %do; 
		%if %symexist(G_PING_SETUPPATH) EQ 0 %then 	%let G_PING_SETUPPATH=/ec/prod/server/sas/0eusilc; 
		%include "&G_PING_SETUPPATH/library/autoexec/_setup_.sas";
		%_default_setup_;
	%end;

	libname rdb "&G_PING_C_RDB"; /* "&eusilc/IDB_RDB_TEST/C_RDB"; */ 

	%local pop_glob pop_part;
	%local run_agg pop_infl;

	%let year=2015;
	%let ctry_glob=("AT","BE","BG","CY","CZ","DE","DK","EE","ES","FI","FR","EL","HU","IE",
					"IT","LT","LU","LV","MT","NL","PL","PT","RO","SE","SI","SK","UK","HR");
	%let ctry_part=("AT","BE","BG","CY","CZ","DE","DK","EE","ES","FI","FR","EL","HU","IE");
	
	%put Consider the list of countries glob=&ctry_glob and part=&ctry_part ...;
	%ctry_population(%quote(&ctry_glob), &year, _pop_size_=pop_glob);
	%ctry_population(%quote(&ctry_part), &year, _pop_size_=pop_part);
	%put the corresponding populations are: &pop_glob and &pop_part respectively;

	%let thres=0.7; /* 70% of the total EU28 population */
	%put Setting then a threshold to &thres, the ratio can be estimated ...; 
	%population_compare(&pop_glob, &pop_part, _pop_infl_=pop_infl, _run_agg_=run_agg, pop_thres=&thres);
	%put calculation will be run? &run_agg, while pop_infl=&pop_infl;

%mend _example_population_compare;

/* 
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;
%_example_population_compare;  
*/

/** \endcond */
