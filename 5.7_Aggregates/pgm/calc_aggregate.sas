/** 
## calc_aggregate {#sas_calc_aggregate}
Calculate an aggregated indicator over a given geographical area for a given period.

	%calc_aggregate(dsn, zone, year, odsn, grpdim=(), ctry_glob=(), flag=, 
					pop_file=' ', take_all=no, nyear_back=0, sampsize=0, max_sampsize=0, 
					thres_presence=' ', thres_reach=' ', lib=' ');

### Arguments
* `dsn` : a dataset representing the indicator for which an aggregated value is estimated;
* `zone` : code of a geographical area, _e.g._, EU28, EA19, etc..
* `year` : year of interest;
* `grpdim` : (_option_) list of fields to consider in the dataset;
* `ctry_glob` : list of (comma-separated, in-between quotes) strings representing the ISO-codes
	of all the countries that belong to a given geographical area;
* `flag` : ;
* `pop_file` : (_option_) file storing the population of the different countries (e.g., what used 
	to be `CCWGH60`); see `SILCFMT` library;
* `take_all, nyear_back, sampsize, max_sampsize` : (_option_) see arguments of macro 
	[zone_build](@ref sas_zone_build);
* `thres_presence, thres_reach` : (_option_) ibid, see arguments of macro [`%zone_build`](@ref sas_zone_build);
* `lib` : (_option_) input dataset library; default (not passed or ' '): `lib` is set to `WORK`.

### Returns
- `odsn` : output dataset storing the aggregated indicator.

### Examples
Run macro `%%_example_calc_aggregate`.

### See also
The macro program uses aggregate macros: [aggregate_build](@ref sas_aggregate_build), [aggregate_unit](@ref sas_aggregate_unit), 
[aggregate_flag](@ref sas_aggregate_flag), [aggregate_join](@ref sas_aggregate_join), [aggregate_weight](@ref sas_aggregate_weight) 
and [aggregate_update](@ref sas_aggregate_update).

*/ /** \cond */

/*options nonotes  source  source2 mlogic nomprint  symbolgen;*/

%macro calc_aggregate(/*input*/	 dsn, zone, year,
				 /*output*/ dsn_o, 
				 /*option*/ grpdim=, ctry_glob=, flag=, 
				 pop_file=' ', take_all=no, nyear_back=0, sampsize=0, max_sampsize=0, 
				 thres_presence=' ', thres_reach=' ', lib=' ');
%put sono;
	%if %quote(&ctry_glob)= %then %do;
		%local ctry_glob;
		%zone_to_ctry(&zone, time=&year, _ctrylist_=ctry_glob);
	%end; 
	%if %quote(&grpdim)= %then %do; /* currently not working with RDB2 */
		%local grpdim;
		%fields_to_list(&dsn, _list_=grpdim, lib=&lib);
		%rule_aggregate(&dsn, %quote(&grpdim), _fields_=grpdim);
		%list_quote(&grpdim, _clist_=grpdim);
	%end; 

	%local ctry_tab pop_infl run_agg pop_part;
	%let ctry_tab=_tmp_ctry_tab_aggregate;
	%aggregate_build(&dsn, &ctry_glob, &year, &ctry_tab, 
				_pop_infl_=pop_infl, _run_agg_=run_agg, _pop_part_=pop_part,
				take_all=&take_all, nyear_back=&nyear_back,
				sampsize=&sampsize, max_sampsize=&max_sampsize,
				thres_presence=&thres_presence, thres_reach=&thres_reach, 
				pop_file=&pop_file, lib=&lib);


	%if run_agg=no %then %goto exit;

	/* set the rule on currency/unit flag when it exists */
	%local flag_unit;
	%aggregate_unit(&dsn, _flag_=flag_unit);

	%local flag_zone;
	%aggregate_flag(&zone, &ctry_glob, &year, &ctry_tab, _flag_=flag_zone);

	%local TMP;
	%let TMP=_tmp_tab_aggregate; /* temporary WORKing table */
	%aggregate_join(&dsn, &ctry_tab, &year, &TMP,
				lib=&lib, flag_unit=&flag_unit, pop_file=&pop_file);

	%local TMP_O;
	%let TMP_O=_tmp_out_aggregate; /* temporary WORKing table */
	%aggregate_weight(&zone, &grpdim, &TMP, &pop_part, &pop_infl,  
				 	&TMP_O, flag=&flag,	flag_zone=&flag_zone, lib=WORK);

	/* %let dsn_o=&dsn; */
	%aggregate_update(&TMP_O, &zone, &year, &dsn_o);

	%work_clean(ds=&ctry_tab);
	%work_clean(ds=&TMP);
	%work_clean(ds=&TMP_O);
	%exit:
%mend calc_aggregate;


%macro _example_calc_aggregate;
	%if %symexist(G_PING_ROOTPATH) EQ 0 %then %do; 
		%if %symexist(G_PING_SETUPPATH) EQ 0 %then 	%let G_PING_SETUPPATH=/ec/prod/server/sas/0eusilc; 
		%include "&G_PING_SETUPPATH/library/autoexec/_setup_.sas";
		%_default_setup_;
	%end;

	libname rdb "&G_PING_C_RDB"; /* "&eusilc/IDB_RDB_TEST/C_RDB"; */
 
    %local grpdim;
/*	%let dsn=MDES01;
	%let lib=rdb2;
	%let grpdim=;
	%fields_to_list(&dsn, _list_=grpdim, lib=&lib);
	%put grpdim=&grpdim; */

/*	%let dsn=DI04;
	%let zone=EU28;

	%let grpdim=("hhtyp", "unit", "indic_il", "unit");*/
	%let lib=rdb; 
	%let dsn=DI02;
	%local dimcol;
	%fields_to_list(&dsn, lib=rdb, _list_=dimcol);

	%put (i)  for RDB indicator &dsn; 
	%put res:  output by fields_to_list are dimcol=&dimcol;
	%rule_aggregate(&dsn, %quote(&dimcol), _fields_=dimcol);
		%put res:  updated fields is &dimcol;
	%list_quote(&dimcol, _clist_=clist)
	/* %list_quote(&dimcol, _clist_=dimcol);
	%clist_unquote(&dimcol, _list_=dimcol, sep=%str(%"), rep=%str(,)); */
	%put res:  updated fields is &dimcol;
	%put res:  updated fields is &clist);
%put ******;
	%local existOK;
	%ds_check(&dsn, _ans_=existOK, lib=&lib);
	%if &existOK=no %then %do;
		%put !!! file not found!!!;
		%goto exit;
	%end;
	%let yyyy=2014;
	%let zone=EU28;
	%local dsn_o;
	%let dsn_o=_out_example_aggregate; /* &dsn */
*	%aggregate(&dsn, &zone, &yyyy, &dsn_o, grpdim=%quote(&dimcol), take_all=yes, lib=&lib);
	PROC print data=&dsn_o;
	run;

	%work_clean(ds=&dsn_o);
	%exit:
%mend _example_calc_aggregate;

/* 
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;
%_example_calc_aggregate;  
*/

/** \endcond */
