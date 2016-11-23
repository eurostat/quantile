/** \cond */
/** 
## dszone_update {#sas_dszone_update}
Update the time/zone fields of a given dataset. 

	%dszone_update(dsn, dsn_o, geo_list=, time_list=, lib=WORK);

### Arguments
* `dsn` : input dataset;
* `geo_list` : (_option_) unformatted (_i.e._ blank separated, no quotes) list (of strings)
	representing the geographic locations (_e.g._, countries, zones) whose values are 
	stored into the dataset;
* `time_list` : (_option_) ibid, time is passed as a list (of numeric) years;
* `lib` : (_option_) name of the output library; by default: ' ', _i.e._ `WORK` is used.

### Returns
`dsn_o` : name of the dataset where data are stored/merged; if it does not exist, it is
	created.

### Examples
Run macro `%%_example_dszone_update` for more examples.

### Note
In practice, when both `geo_list` and `time_list` are passed, the following data step is 
processed:

	DATA  lib.dsn_o;
		set lib.dsn_o (where=(not(time in time_list and geo in geo_list)))
		dsn (where=(time in time_list and geo in geo_list)); 
	run;

When only one of the list is passed, say `time_list`, then the process becomes:

	DATA  lib.dsn_o;
		set lib.dsn_o (where=(not(time in time_list)))
		dsn (where=(time in time_list)); 
	run;

Ibid when only `geo_list` is passed.

### See also
[%list_quote](@ref sas_list_quote), [%clist_length](@ref sas_clist_length), [%ds_check](@ref sas_ds_check).
*/ /** \cond */

%macro dszone_update(/*input*/  tab, 
				 	 /*output*/ odsn, 
				 	 /*option*/ geo_list=, time_list=, lib=);
 	%if %macro_isblank(lib) %then %let lib=WORK;
	
	%let geoOK=no;
 	%if not %macro_isblank(geo_list) %then %do;
		%let geoOK=yes;
		%let geo_list=(%list_quote(&geo_list));
	%end; 
	
 	%let timeOK=no;
	%if not %macro_isblank(time_list) %then %do;
		%let timeOK=yes;
		%local ntime;
		%let ntime=%clist_length(&time_list);
		%if &ntime=1 %then %let time_list=(&time_list);
	%end;
	
	DATA  &lib..&odsn;
		set 
		%if %ds_check(&odsn, lib=&lib) %then %do;
			&lib..&odsn
			%if &timeOK=yes or &geoOK=yes  %then %do;
				(where=(not(
				%if &timeOK=yes %then %do;
					time in &time_list
				%end;
				%if &timeOK=yes and &geoOK=yes  %then %do;
					and
				%end;
				%if &geoOK=yes %then %do;
					geo in &geo_list
				%end;
				)))
			%end;
		%end;
		&tab
		%if &timeOK=yes or &geoOK=yes  %then %do;
			(where=(
			%if &timeOK=yes %then %do;
				time in &time_list
			%end;
			%if &timeOK=yes and &geoOK=yes  %then %do;
				and
			%end;
			%if &geoOK=yes %then %do;
				geo in &geo_list
			%end;
			))
		%end;
		; 
	run;

%mend dszone_update;

%macro _example_dszone_update;
	%if %symexist(G_PING_ROOTPATH) EQ 0 %then %do; 
		%if %symexist(G_PING_SETUPPATH) EQ 0 %then 	%let G_PING_SETUPPATH=/ec/prod/server/sas/0eusilc; 
		%include "&G_PING_SETUPPATH/library/autoexec/_setup_.sas";
		%_default_setup_;
	%end;

	%local tab;
	%let tab=_tmp_tab_example_dszone_update;
	data &tab;
		geo='AT'; value=4; time=2014; output;
		geo='BE'; value=4; time=2014; output;
		geo='BG'; value=4; time=2014; output;
		geo='LU'; value=4; time=2014; output;
		geo='IT'; value=4; time=2014; output;
		geo='FR'; value=0; time=2010; output;
		geo='FR'; value=3; time=2011; output;
		geo='FR'; value=2; time=2012; output;
		geo='FR'; value=3; time=2013; output;
		geo='FR'; value=4; time=2014; output;
	run;
	PROC print data=&tab;
	quit;

	%local dsn;
	%let dsn=_tmp_example_dszone_update;				  	  
	data &dsn;
		geo='BE'; value=.; time=2013; output;
		geo='BE'; value=.; time=2012; output;
		geo='AT'; value=.; time=2013; output; 
		geo='AT'; value=.; time=2012; output;
		geo='AT'; value=.; time=2011; output;
		geo='AT'; value=.; time=2010; output;
		geo='BG'; value=.; time=2013; output;
		geo='BG'; value=.; time=2012; output; 
		geo='LU'; value=.; time=2013; output;
		geo='LU'; value=.; time=2012; output;
		geo='IT'; value=.; time=2013; output;
		geo='IT'; value=.; time=2012; output;
		geo='FR'; value=.; time=2014; output;
		geo='BE'; value=.; time=2014; output;
		geo='IT'; value=.; time=2014; output;
	run;
	PROC print data=&dsn;
	quit;

	%put (i) Update the dataset &dsn with table &tab considering only time=2014;
	DATA &dsn._o; set &dsn; run;
	%dszone_update(&tab, &dsn._o, time_list=2014);
	PROC print data=&dsn._o;
	quit;

	%put (ii) Update the dataset &dsn with table &tab considering only geo=FR;
	DATA &dsn._o; set &dsn; run;
	%dszone_update(&tab, &dsn._o, geo_list=FR);
	PROC print data=&dsn._o;
	quit;

	%put (iii) Update the dataset &dsn with table &tab considering geo=FR AT and time=2014;
	%dszone_update(&tab, &dsn, time_list=2014, geo_list=FR AT);
	PROC print data=&dsn;
	quit;

	%work_clean(&dsn._o);
	%work_clean(&dsn);
	%work_clean(&tab);
%mend _example_dszone_update;

/*
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;
%_example_dszone_update; 
*/

/** \endcond */
