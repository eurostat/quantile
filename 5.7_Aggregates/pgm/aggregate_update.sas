/** 
## aggregate_update {#sas_aggregate_update}
Update the time/zone fields of a given dataset with the content of another dataset.

	%aggregate_update(dsn, zone, year, dsn_o, lib=WORK);

### Arguments
* `dsn` : input dataset to merge into the output dataset;
* `zone, year` : geographical areas (_e.g._ EU28) and year considered respectively; data for
 	`geo=zone` and `time=year` in the input dataset `dsn` (see above) will be merged/stored 
	into the output dataset `dsn_o` (see below);
* `lib` : (_option_) name of the output library; by default: ' ', _i.e._ `WORK` is used.

### Returns
* `dsn_o` : name of the dataset where data are stored/merged; if it does not exist, it is
	created.

### Note
The program is nothing else than:

	%dszone_update(&dsn, &dsn_o, geo_list=&zone, time_list=&year, lib=&lib);

### Example
Run macro `%%_example_aggregate_update`.

### See also
This macro is nothing else than a call to the macro program [dszone_update](@ref sas_dszone_update) (see note).
*/ /** \cond */

 
%macro aggregate_update(/*input*/  tab, zone, year,
				   		/*output*/ dsn_o,
				   		/*option*/ lib=);

	/* %dszone_update(&dsn, &dsn_o, geo_list=&zone, time_list=&year, lib=&lib); */

 	%if %macro_isblank(lib) %then 	%let lib=WORK;
	%let lib=WORK;
 	%local existOK;
 	%let existOK=%ds_check(&dsn_o, lib=&lib);

	%local v_time v_geo;
	%if %symexist(G_PING_VAR_TIME) %then 			%let v_time=&G_PING_VAR_TIME;
	%else										%let v_time=TIME;
	%if %symexist(G_PING_VAR_GEO) %then 				%let v_geo=&G_PING_VAR_GEO;
	%else										%let v_geo=GEO;

	DATA  &lib..&dsn_o;
		SET 
		%if &existOK=yes %then %do;
			&lib..&dsn_o(where=(not(
				&v_time in (&year)
				and
				&v_geo in ("&zone")
				)))
		%end;
		&tab(where=(
				&v_time in (&year)
				and
				&v_geo in ("&zone")
			)); 
	run;

%mend aggregate_update;

%macro _example_aggregate_update;
	%if %symexist(EUSILC) %then 	%let SETUP_PATH=&EUSILC;
	%else 		%let SETUP_PATH=/ec/prod/server/sas/0eusilc; 
	%include "&SETUP_PATH/library/autoexec/_setup_.sas";
	/* %include "&SETUP_PATH/library/pgm/dszone_update.sas"; */

	%put !!! _example_aggregate_update not yet implemented !!!;
%mend _example_aggregate_update;

/* 
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;
%_example_aggregate_update;  
*/

/** \endcond */
